# Underwater DevSecOps Infrastructure (EKS Repo)

A complete DevSecOps pipeline running on AWS EKS with GitOps deployment via Flux. This repo contains all infrastructure code, application code, and the CI/CD pipeline definition.

---

## Repository Structure

```
EKS/
├── Dockerfile              # Application container (nginx)
├── Dockerfile.jenkins      # Custom Jenkins image with DevSecOps tools
├── Jenkinsfile             # CI/CD pipeline definition
├── docker-compose.yml      # Local DevSecOps stack
├── prometheus.yml          # Prometheus scrape config
├── nginx.conf              # Nginx web server config
├── static/                 # Application static files
│
├── dev/                    # Dev environment Terraform
│   ├── backend.tf          # S3 state backend config
│   ├── locals.tf           # Environment variables
│   ├── providers.tf        # AWS, Kubernetes, Helm providers
│   ├── variables.tf        # Variable definitions
│   ├── terraform.tfvars    # Dev values (SPOT nodes, 2 AZs)
│   ├── vpc.tf              # VPC module call
│   ├── eks.tf              # EKS module call
│   ├── irsa.tf             # IRSA module call
│   └── outputs.tf          # Output values
│
├── prod/                   # Prod environment Terraform (same structure)
│
├── modules/
│   ├── eks-cluster/        # EKS control plane + node groups
│   │   ├── eks.tf          # EKS cluster (references locals)
│   │   ├── node_group.tf   # Node group config (SPOT/ON_DEMAND)
│   │   ├── sg.tf           # Security group rules
│   │   ├── addons.tf       # VPC CNI, CoreDNS, EBS CSI
│   │   ├── outputs.tf      # Cluster outputs
│   │   └── variables.tf    # Module variables
│   │
│   ├── eks-irsa/           # IAM Roles for Service Accounts
│   │   ├── main.tf         # Jenkins, Flux, VPC CNI, EBS CSI roles
│   │   ├── outputs.tf
│   │   └── variables.tf
│   │
│   ├── eks-vpc/            # VPC, subnets, NAT Gateway
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   │
│   └── ecr/                # ECR repositories
│       └── main.tf
│
└── global/
    └── ecr/                # Shared ECR repos (applied once)
        └── main.tf
```

---

## Prerequisites

### Tools Required

Install all tools in WSL (Ubuntu 22.04):

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Docker Engine (WSL)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
sudo service docker start

# Docker Compose plugin
sudo apt install docker-compose-plugin -y
```

### AWS Setup

```bash
# Configure AWS CLI with your IAM user credentials
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

---

## Step 1 — Create Terraform State Backend (One Time)

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket devops-bucket-<your-account-id> \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket devops-bucket-<your-account-id> \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket devops-bucket-<your-account-id> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update `dev/backend.tf` and `prod/backend.tf` with your bucket name:
```hcl
bucket = "devops-bucket-<your-account-id>"
```

---

## Step 2 — Create ECR Repositories (One Time)

```bash
cd global/ecr
terraform init
terraform apply
```

This creates three ECR repositories:
- `underwater`
- `auth-service`
- `api-service`

---

## Step 3 — Start Local DevSecOps Stack

```bash
# Fix WSL memory settings (required for SonarQube)
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Start all services
docker compose up -d

# Verify all running
docker compose ps
```

Services available:
```
Jenkins     → http://localhost:8080
SonarQube   → http://localhost:9000  (admin/admin on first login)
Grafana     → http://localhost:3000  (admin/admin)
Prometheus  → http://localhost:9090
```

### Jenkins Initial Setup

```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Open `http://localhost:8080` and paste the password
2. Click **Install suggested plugins**
3. Create admin user
4. Install additional plugins:
   - Docker Pipeline
   - Kubernetes
   - Amazon ECR
   - AWS Credentials
   - SonarQube Scanner
   - SSH Agent
   - Blue Ocean

### SonarQube Setup

1. Open `http://localhost:9000` → login `admin/admin` → change password
2. Generate token: **My Account → Security → Generate Token**
   - Name: `jenkins-sonar`, Type: `Global Analysis Token`
3. Create webhook: **Administration → Configuration → Webhooks → Create**
   - Name: `jenkins`, URL: `http://jenkins:8080/sonarqube-webhook/`
4. Create project: **Create Project → Local → underwater**

### Jenkins Credentials Setup

Go to **Manage Jenkins → Credentials → System → Global credentials → Add Credentials**:

| ID | Kind | Value |
|----|------|-------|
| `sonar-token` | Secret text | SonarQube token |
| `github-token` | Secret text | GitHub Personal Access Token |
| `github-ssh-key` | SSH Username with private key | Contents of `~/.ssh/jenkins_key` |
| `snyk-token` | Secret text | Snyk auth token from app.snyk.io |

### Jenkins SonarQube Server Config

Go to **Manage Jenkins → System → SonarQube servers**:
```
✅ Environment variables
Name:               SonarQube
Server URL:         http://sonarqube:9000
Server auth token:  sonar-token
```

### Jenkins SonarQube Scanner Tool

Go to **Manage Jenkins → Tools → SonarQube Scanner**:
```
Name:                SonarScanner
✅ Install automatically
```

### SSH Key Setup

```bash
# Generate SSH key for Jenkins → GitHub access
ssh-keygen -t ed25519 -C "jenkins@underwater" -f ~/.ssh/jenkins_key -N ""

# Add public key to GitHub
cat ~/.ssh/jenkins_key.pub
# GitHub → underwater-manifests → Settings → Deploy Keys → Add Deploy Key
# ✅ Allow write access
```

### Create Pipeline Job

**Jenkins → New Item → Pipeline**:
```
Name: underwater-pipeline

Parameters:
  ACTION:       Choice → Deploy, Destroy
  SERVICE_NAME: Choice → underwater, auth-service, api-service

Build Triggers:
  ✅ Poll SCM → H/5 * * * *

Pipeline:
  Definition:  Pipeline script from SCM
  SCM:         Git
  Repository:  https://github.com/<your-username>/EKS.git
  Credentials: github-token
  Branch:      */develop
  Script Path: Jenkinsfile
```

---

## Step 4 — Create Dev EKS Cluster

> ⚠️ **Cost Warning**: EKS costs ~$4/day. Destroy when not in use.

```bash
cd dev

# Initialize
terraform init

# Review what will be created
terraform plan

# Create cluster (~20 minutes)
terraform apply
```

**Resources created:**
```
VPC with public/private subnets across 2 AZs
NAT Gateway for private subnet internet access
EKS control plane (Kubernetes 1.34)
Managed node group (2x t3.medium SPOT instances)
IRSA roles for Jenkins, Flux, VPC CNI, EBS CSI
Security groups
```

---

## Step 5 — Connect kubectl to Cluster

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name underwater-dev

# Verify nodes are ready
kubectl get nodes
```

---

## Step 6 — Bootstrap Flux (GitOps)

```bash
# Bootstrap Flux on dev cluster
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=underwater-manifests \
  --branch=main \
  --path=clusters/dev \
  --personal

# Verify Flux is running
kubectl get pods -n flux-system
```

---

## Branch Strategy

```
main      → protected, no direct pushes, PR + approval required
develop   → active development, triggers dev deployments
release   → triggers prod deployments, PR + approval required

Workflow:
feature/* → PR → develop → dev pipeline → dev EKS cluster
develop   → PR → release → prod pipeline → prod EKS cluster
```

---

## Pipeline Stages

```
1. Checkout SCM          Pull code from GitHub
2. Clean Workspace       Remove old build artifacts
3. Verify Tools          Check docker, aws, git available
4. Build Docker Image    Build container from Dockerfile
5. SonarQube Analysis    Scan source code for vulnerabilities
6. Trivy Scan            Scan Docker image for CVEs
7. Push to ECR           Upload image to AWS ECR
8. Update Manifests Repo Update image tag in underwater-manifests
   (Flux detects change and deploys to EKS automatically)
```

---

## Destroy Resources

```bash
# Destroy dev EKS cluster (saves ~$4/day)
cd dev
terraform destroy

# Stop local Docker stack
docker compose down

# Clean ECR images (optional)
aws ecr batch-delete-image \
  --repository-name underwater \
  --region us-east-1 \
  --image-ids "$(aws ecr list-images \
    --repository-name underwater \
    --query 'imageIds[*]' \
    --output json)"
```

> **Note**: S3 bucket, DynamoDB table, and ECR repositories have negligible cost (~$0.05/month) and can be left running.

---

## Cost Summary

| Resource | Cost When Running | Cost When Destroyed |
|----------|------------------|---------------------|
| EKS Control Plane | $0.10/hr ($72/mo) | $0 |
| EC2 Nodes (2x t3.medium SPOT) | ~$0.03/hr ($22/mo) | $0 |
| NAT Gateway | $0.045/hr ($32/mo) | $0 |
| ECR Images | ~$0.05/mo | ~$0.05/mo |
| S3 State Bucket | ~$0.001/mo | ~$0.001/mo |
| DynamoDB Lock Table | ~$0.001/mo | ~$0.001/mo |
| **Total** | **~$126/mo** | **~$0.05/mo** |

---

## Troubleshooting

**SonarQube not starting:**
```bash
sudo sysctl -w vm.max_map_count=262144
docker compose restart sonarqube
docker logs sonarqube -f  # wait for "SonarQube is operational"
```

**Docker not found in Jenkins:**
```bash
docker exec -u root jenkins bash -c "apt-get update && apt-get install -y docker.io"
```

**AWS credentials not working in Jenkins:**
```bash
# Verify credentials mount
docker exec jenkins aws sts get-caller-identity
```

**SSH host key verification failed:**
```bash
docker exec -u root jenkins bash -c "
  ssh-keyscan github.com >> /root/.ssh/known_hosts
  ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts
"
```

**Terraform cycle error:**
```
Remove vpc_cni_irsa_role_arn and ebs_csi_irsa_role_arn 
from dev/eks.tf — IRSA roles are applied after cluster creation
```