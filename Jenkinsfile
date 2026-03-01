pipeline {

    // ── KUBERNETES POD AGENT ─────────────────────────────────────────────────
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                metadata:
                  labels:
                    app: jenkins-agent
                spec:
                  serviceAccountName: jenkins
                  containers:
                    - name: builder
                      image: maven:3.9-eclipse-temurin-17
                      command: [sleep]
                      args: [infinity]
                      resources:
                        requests:
                          cpu: "500m"
                          memory: "1Gi"
                        limits:
                          cpu: "1000m"
                          memory: "2Gi"
                    - name: docker
                      image: docker:24-dind
                      securityContext:
                        privileged: true
                      env:
                        - name: DOCKER_TLS_CERTDIR
                          value: ""
                      resources:
                        requests:
                          cpu: "500m"
                          memory: "512Mi"
                    - name: terraform
                      image: hashicorp/terraform:1.7
                      command: [sleep]
                      args: [infinity]
                      resources:
                        requests:
                          cpu: "200m"
                          memory: "256Mi"
                    - name: aws-tools
                      image: amazon/aws-cli:latest
                      command: [sleep]
                      args: [infinity]
                      resources:
                        requests:
                          cpu: "100m"
                          memory: "128Mi"
                    - name: trivy
                      image: aquasec/trivy:latest
                      command: [sleep]
                      args: [infinity]
                      volumeMounts:
                        - name: trivy-cache
                          mountPath: /root/.cache/trivy
                  volumes:
                    - name: trivy-cache
                      emptyDir: {}
            '''
        }
    }

    // ── ENVIRONMENT ──────────────────────────────────────────────────────────
    environment {
        ECR_REGISTRY   = '861276101474.dkr.ecr.us-east-1.amazonaws.com'
        AWS_REGION     = 'us-east-1'
        MANIFESTS_REPO = 'git@github.com:your-username/underwater-manifests.git'
        SONAR_TOKEN    = credentials('sonar-token')
        SNYK_TOKEN     = credentials('snyk-token')

        // Derive environment and image tag from branch name
        // develop → dev-42  |  release → release-42
        ENVIRONMENT = sh(
            returnStdout: true,
            script: '''
                if [ "${GIT_BRANCH}" = "origin/release" ]; then
                    echo -n "prod"
                else
                    echo -n "dev"
                fi
            '''
        ).trim()

        IMAGE_TAG = sh(
            returnStdout: true,
            script: '''
                if [ "${GIT_BRANCH}" = "origin/release" ]; then
                    echo -n "release-${BUILD_NUMBER}"
                else
                    echo -n "dev-${BUILD_NUMBER}"
                fi
            '''
        ).trim()

        TF_DIR       = "environments/${ENVIRONMENT}"
        CLUSTER_NAME = "underwater-${ENVIRONMENT}"
    }

    options {
        skipStagesAfterUnstable()
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['Deploy', 'Destroy'],
            description: 'Deploy or destroy resources'
        )
        choice(
            name: 'SERVICE_NAME',
            choices: ['underwater', 'auth-service', 'api-service'],
            description: 'Which microservice to build'
        )
    }

    stages {

        // ── SETUP ────────────────────────────────────────────────────────────

        stage('Clean Workspace') {
            steps { cleanWs() }
        }

        stage('Checkout SCM') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        returnStdout: true,
                        script: "git rev-parse --short HEAD"
                    ).trim()
                    echo "Branch: ${GIT_BRANCH} | Environment: ${ENVIRONMENT} | Tag: ${IMAGE_TAG}"
                }
            }
        }

        stage('Verify Tools') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                parallel(
                    "Terraform": {
                        container('terraform') { sh 'terraform version' }
                    },
                    "Docker": {
                        container('docker') { sh 'docker version' }
                    },
                    "AWS + IRSA": {
                        container('aws-tools') {
                            sh '''
                                aws --version
                                aws sts get-caller-identity
                            '''
                        }
                    },
                    "Trivy": {
                        container('trivy') { sh 'trivy --version' }
                    }
                )
            }
        }

        // ── INFRASTRUCTURE ───────────────────────────────────────────────────

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('terraform') {
                    sh """
                        cd ${TF_DIR}
                        terraform init
                        terraform validate
                        terraform plan -input=false -out tfplan
                        terraform show -no-color tfplan > tfplan.txt
                    """
                    archiveArtifacts artifacts: "${TF_DIR}/tfplan.txt"
                }
            }
        }

        stage('Review Terraform Plan') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                input message: "Deploying to ${ENVIRONMENT} — review tfplan.txt and approve?", ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('terraform') {
                    sh """
                        cd ${TF_DIR}
                        terraform apply -input=false tfplan
                    """
                }
            }
        }

        // ── BUILD ────────────────────────────────────────────────────────────

        stage('Build Docker Image') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('docker') {
                    sh """
                        docker build \
                          --label git-commit=${env.GIT_COMMIT_SHORT} \
                          --label build-number=${IMAGE_TAG} \
                          --label environment=${ENVIRONMENT} \
                          -t ${params.SERVICE_NAME}:${IMAGE_TAG} .
                    """
                }
            }
        }

        // ── SECURITY SCANNING ────────────────────────────────────────────────

        stage('SonarQube Analysis') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('builder') {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            sonar-scanner \
                              -Dsonar.projectKey=${params.SERVICE_NAME}-${ENVIRONMENT} \
                              -Dsonar.projectName="${params.SERVICE_NAME} (${ENVIRONMENT})" \
                              -Dsonar.sources=. \
                              -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Container Security') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                parallel(
                    "Trivy CVE Scan": {
                        container('trivy') {
                            sh """
                                trivy image \
                                  --exit-code 0 \
                                  --severity HIGH,CRITICAL \
                                  --format json \
                                  -o trivy-report.json \
                                  ${params.SERVICE_NAME}:${IMAGE_TAG}

                                # Hard fail on CRITICAL
                                trivy image \
                                  --exit-code 1 \
                                  --severity CRITICAL \
                                  --no-progress \
                                  ${params.SERVICE_NAME}:${IMAGE_TAG}
                            """
                            archiveArtifacts artifacts: 'trivy-report.json'
                        }
                    },
                    "Snyk Scan": {
                        container('builder') {
                            sh """
                                npm install -g snyk
                                snyk auth ${SNYK_TOKEN}
                                snyk test --severity-threshold=high --json > snyk-report.json || true
                                snyk monitor || true
                            """
                            archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                        }
                    }
                )
            }
        }

        // ── PUBLISH ──────────────────────────────────────────────────────────

        stage('Push to ECR') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('docker') {
                    sh """
                        # IRSA handles auth — no stored credentials
                        aws ecr get-login-password --region ${AWS_REGION} | \
                          docker login \
                            --username AWS \
                            --password-stdin \
                            ${ECR_REGISTRY}

                        docker tag ${params.SERVICE_NAME}:${IMAGE_TAG} \
                          ${ECR_REGISTRY}/${params.SERVICE_NAME}:${IMAGE_TAG}

                        docker push ${ECR_REGISTRY}/${params.SERVICE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        // ── GITOPS DEPLOY ────────────────────────────────────────────────────

        stage('Update Manifests Repo') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('builder') {
                    sshagent(['github-ssh-key']) {
                        sh """
                            git clone ${MANIFESTS_REPO} manifests
                            cd manifests

                            # Update image tag for this service in the correct overlay
                            sed -i 's|${ECR_REGISTRY}/${params.SERVICE_NAME}:.*|${ECR_REGISTRY}/${params.SERVICE_NAME}:${IMAGE_TAG}|g' \
                              apps/base/${params.SERVICE_NAME}/deployment.yaml

                            git config user.email "jenkins@underwater.com"
                            git config user.name "Jenkins CI"
                            git add apps/base/${params.SERVICE_NAME}/deployment.yaml
                            git commit -m "ci(${ENVIRONMENT}): ${params.SERVICE_NAME} → ${IMAGE_TAG} [${env.GIT_COMMIT_SHORT}]"
                            git push origin main
                        """
                    }
                }
            }
        }

        stage('Verify Flux Rollout') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                container('aws-tools') {
                    sh """
                        aws eks update-kubeconfig \
                          --region ${AWS_REGION} \
                          --name ${CLUSTER_NAME}

                        curl -LO "https://dl.k8s.io/release/\$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl && mv kubectl /usr/local/bin/

                        echo "Waiting for Flux to sync (~30s)..."
                        sleep 30

                        kubectl rollout status deployment/ecr-app-underwater \
                          -n underwater \
                          --timeout=120s
                    """
                }
            }
        }

        // ── DESTROY ──────────────────────────────────────────────────────────

        stage('Destroy Resources') {
            when { expression { params.ACTION == 'Destroy' } }
            steps {
                input message: "Destroy ALL ${ENVIRONMENT} resources? This cannot be undone!", ok: 'Yes, Destroy'
                script {
                    try {
                        container('aws-tools') {
                            sh """
                                aws eks update-kubeconfig \
                                  --region ${AWS_REGION} \
                                  --name ${CLUSTER_NAME}

                                curl -LO "https://dl.k8s.io/release/\$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                                chmod +x kubectl && mv kubectl /usr/local/bin/

                                kubectl delete deployment ecr-app-underwater -n underwater --ignore-not-found=true
                                kubectl delete service ecr-app-underwater -n underwater --ignore-not-found=true

                                if aws ecr describe-repositories --repository-names ${params.SERVICE_NAME} 2>/dev/null; then
                                    IMAGE_IDS=\$(aws ecr list-images \
                                      --repository-name ${params.SERVICE_NAME} \
                                      --query 'imageIds[*]' --output json)
                                    if [ "\$IMAGE_IDS" != "[]" ]; then
                                        aws ecr batch-delete-image \
                                          --repository-name ${params.SERVICE_NAME} \
                                          --image-ids "\$IMAGE_IDS"
                                    fi
                                fi
                            """
                        }
                        container('terraform') {
                            sh """
                                cd ${TF_DIR}
                                terraform init
                                terraform destroy -auto-approve
                            """
                        }
                    } catch (err) {
                        currentBuild.result = 'FAILURE'
                        error("Destroy failed: ${err}")
                    }
                }
            }
        }
    }

    // ── NOTIFICATIONS ────────────────────────────────────────────────────────

    post {
        success {
            echo "✅ [${ENVIRONMENT}] ${params.SERVICE_NAME}:${IMAGE_TAG} — Flux syncing to cluster"
            // slackSend channel: '#deployments', color: 'good',
            //   message: "✅ *${ENVIRONMENT}* | ${params.SERVICE_NAME}:${IMAGE_TAG} deployed | commit: ${env.GIT_COMMIT_SHORT}"
        }
        failure {
            echo "❌ [${ENVIRONMENT}] Pipeline failed — ${params.SERVICE_NAME}"
            // slackSend channel: '#deployments', color: 'danger',
            //   message: "❌ *${ENVIRONMENT}* | ${params.SERVICE_NAME} build ${IMAGE_TAG} failed"
        }
        always {
            archiveArtifacts artifacts: '**/*-report.json', allowEmptyArchive: true
            cleanWs()
        }
    }
}
