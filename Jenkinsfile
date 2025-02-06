pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    options {
        skipStagesAfterUnstable()
    }
    parameters {
        choice(name: 'ACTION', choices: ['Deploy', 'Destroy'], description: 'Select the action to perform')
    }
    stages {
        stage('Clean workspace') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                cleanWs()
            }
        }
        stage('Clone Repository') { 
            steps { 
                script{
                    checkout scm
                }
            }
        }
        stage('Set Terraform path') {
            steps {
                script {
                    env.PATH += ":/usr/bin/terraform"
                }
                sh 'terraform --version'
                sh 'pwd'
            }
        }
        stage('Verify Tools') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                parallel(
                    "Terraform": { sh 'terraform -v' },
                    "Docker": { sh 'docker -v' },
                    "AWS": { sh 'aws --version' }
                )
            }
        }
        stage('Verify Other Tools') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                parallel(
                    "Git": { sh 'git --version' },
                    "NPM": { sh 'npm -v' },
                    "Ansible": { sh 'ansible --version' }
                )
            }
        }
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                sh 'pwd'
                sh 'terraform init'
                sh 'terraform validate'
                sh 'terraform plan -input=false -out tfplan'
                sh 'terraform show -no-color tfplan > tfplan.txt'
            }
        }
        stage('Check Plan') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                input message: 'Is terraform plan okay?', ok: 'yes'
            }
        }
        stage ('Apply') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                input message: 'Do you want to Apply?', ok: 'yes'
                sh 'terraform apply -input=false tfplan'
            }
        }
        stage('Build Docker Image') { 
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps { 
                script{
                    app = docker.build("underwater")
                }
            }
        }
        stage('Test'){
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                echo 'Empty'
            }
        }
        stage('Push Docker Image to Registry') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                script{
                    docker.withRegistry('https://861276101474.dkr.ecr.us-east-1.amazonaws.com/underwater/', 'ecr:us-east-1:aws-credentials') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }
        stage('Deploy'){
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps {
                sh 'kubectl get nodes'
                sh 'kubectl apply -f deployment.yml'
                sh 'kubectl rollout restart deployment ecr-app-underwater'
            }
        }
        stage('Cleanup Resources') {
            when {
                expression { params.ACTION == 'Destroy' }
            }
            steps {
                input message: 'Are you sure you want to destroy all resources? This action cannot be undone!', ok: 'Yes, Destroy Everything'
                script {
                    try {
                        // Delete all Kubernetes resources in the namespace
                        sh '''
                            kubectl delete deployment ecr-app-underwater || true
                            kubectl delete service ecr-app-underwater || true
                            kubectl delete pods --all || true
                        '''
                        
                        // Delete ECR images only
                        sh '''
                            # List all image IDs in the repository
                            IMAGE_IDS=$(aws ecr list-images --repository-name underwater --query 'imageIds[*]' --output json)
                            
                            # Delete all images if there are any
                            if [ "$IMAGE_IDS" != "[]" ]; then
                                aws ecr batch-delete-image \
                                    --repository-name underwater \
                                    --image-ids "$IMAGE_IDS" || true
                            fi
                        '''
                        
                        // Destroy all Terraform-managed infrastructure
                        sh '''
                            terraform init
                            terraform destroy -auto-approve
                        '''
                
                        // Clean up any local Docker images
                        sh '''
                            docker rmi -f $(docker images 'underwater' -a -q) || true
                            docker rmi -f $(docker images '*amazonaws.com/underwater*' -a -q) || true
                        '''
                    } catch (err) {
                        echo "Error during cleanup: ${err}"
                        currentBuild.result = 'FAILURE'
                        error("Cleanup failed: ${err}")
                    }
                }
            }
            post {
                success {
                    echo 'All resources have been successfully destroyed'
                }
                failure {
                    echo 'Resource destruction failed - check the logs for details'
                }
            }
        }
    }
}