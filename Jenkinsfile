pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    parameters {
        choice(name: 'ACTION', choices: ['Deploy', 'Destroy'], description: 'Select the action to perform')
    }
    stages {
        stage('Clean workspace') {
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
        stage('Deployment Stages') {
            when {
                expression { params.ACTION == 'Deploy' }
            }
            stages {
                stage('Verify Tools') {
                    steps {
                        parallel(
                            "Terraform": { sh 'terraform -v' },
                            "Docker": { sh 'docker -v' },
                            "AWS": { sh 'aws --version' }
                        )
                    }
                }
                stage('Verify Other Tools') {
                    steps {
                        parallel(
                            "Git": { sh 'git --version' },
                            "NPM": { sh 'npm -v' },
                            "Ansible": { sh 'ansible --version' }
                        )
                    }
                }
                stage('Terraform Plan') {
                    steps {
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform plan -input=false -out tfplan'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
                stage('Check Plan') {
                    steps {
                        input message: 'Is terraform plan okay?', ok: 'yes'
                    }
                }
                stage ('Apply') {
                    steps {
                        input message: 'Do you want to Apply?', ok: 'yes'
                        sh 'terraform apply -input=false tfplan'
                    }
                }
                stage('Build Docker Image') { 
                    steps { 
                        script{
                            app = docker.build("underwater")
                        }
                    }
                }
                stage('Test'){
                    steps {
                        echo 'Empty'
                    }
                }
                stage('Push Docker Image to Registry') {
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
                    steps {
                        sh 'kubectl get nodes'
                        sh 'kubectl apply -f deployment.yml'
                        sh 'kubectl rollout restart deployment ecr-app-underwater'
                    }
                }
            }
        }
        stage('Destroy Resources') {
            when {
                expression { params.ACTION == 'Destroy' }
            }
            steps {
                input message: 'Are you sure you want to destroy all resources? This action cannot be undone!', ok: 'Yes, Destroy Everything'
                script {
                    try {
                        // Delete all Kubernetes resources
                        sh '''
                            kubectl delete deployment ecr-app-underwater || true
                            kubectl delete service ecr-app-underwater || true
                            kubectl delete pods --all || true
                        '''
                        
                        // Delete ECR repository
                        sh '''
                            aws ecr delete-repository \
                                --repository-name underwater \
                                --force || true
                        '''
                        
                        // Destroy Terraform infrastructure
                        sh '''
                            terraform init
                            terraform destroy -auto-approve \
                                -var="AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                                -var="AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
                        '''
                        
                        // Clean Docker images
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