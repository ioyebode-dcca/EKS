pipeline {

    // Temporary: using local agent for testing
    // Replace with kubernetes agent block when deploying to EKS
    agent any

    // ── ENVIRONMENT ──────────────────────────────────────────────────────────
    environment {
        ECR_REGISTRY   = '495905914919.dkr.ecr.us-east-1.amazonaws.com'
        AWS_REGION     = 'us-east-1'
        MANIFESTS_REPO = 'git@github.com:ioyebode-dcca/underwater-manifests.git'
        SONAR_TOKEN    = credentials('sonar-token')
        SNYK_TOKEN     = credentials('snyk-token')

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
                sh '''
                    echo "=== Checking available tools ==="
                    docker --version || echo "Docker not available"
                    aws --version || echo "AWS CLI not available"
                    git --version
                    echo "================================"
                '''
            }
        }

        // ── BUILD ────────────────────────────────────────────────────────────

        stage('Build Docker Image') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                sh """
                    docker build \
                      --label git-commit=${env.GIT_COMMIT_SHORT} \
                      --label build-number=${IMAGE_TAG} \
                      --label environment=${ENVIRONMENT} \
                      -t ${params.SERVICE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        // ── SECURITY SCANNING ────────────────────────────────────────────────

        stage('SonarQube Analysis') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
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

        stage('Trivy Scan') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                sh """
                    # Full report
                    trivy image \
                      --exit-code 0 \
                      --severity HIGH,CRITICAL \
                      --format json \
                      -o trivy-report.json \
                      ${params.SERVICE_NAME}:${IMAGE_TAG} || true

                    # Hard fail on CRITICAL
                    trivy image \
                      --exit-code 1 \
                      --severity CRITICAL \
                      --no-progress \
                      ${params.SERVICE_NAME}:${IMAGE_TAG}
                """
                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('Snyk Scan') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                sh """
                    npm install -g snyk || true
                    snyk auth ${SNYK_TOKEN} || true
                    snyk test --severity-threshold=high --json > snyk-report.json || true
                """
                archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
            }
        }

        // ── PUBLISH ──────────────────────────────────────────────────────────

        stage('Push to ECR') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                sh """
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

        // ── GITOPS DEPLOY ────────────────────────────────────────────────────

        stage('Update Manifests Repo') {
            when { expression { params.ACTION == 'Deploy' } }
            steps {
                sshagent(['github-ssh-key']) {
                    sh """
                        git clone ${MANIFESTS_REPO} manifests
                        cd manifests

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

        // ── DESTROY ──────────────────────────────────────────────────────────

        stage('Destroy Resources') {
            when { expression { params.ACTION == 'Destroy' } }
            steps {
                input message: "Destroy ALL ${ENVIRONMENT} resources? This cannot be undone!", ok: 'Yes, Destroy'
                sh """
                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${CLUSTER_NAME}

                    kubectl delete deployment ecr-app-underwater \
                      -n underwater --ignore-not-found=true
                    kubectl delete service ecr-app-underwater \
                      -n underwater --ignore-not-found=true
                """
            }
        }
    }

    // ── NOTIFICATIONS ────────────────────────────────────────────────────────

    post {
        success {
            echo "✅ [${ENVIRONMENT}] ${params.SERVICE_NAME}:${IMAGE_TAG} deployed successfully"
        }
        failure {
            echo "❌ [${ENVIRONMENT}] Pipeline failed — ${params.SERVICE_NAME}"
        }
        always {
            archiveArtifacts artifacts: '**/*-report.json', allowEmptyArchive: true
            cleanWs()
        }
    }
}
