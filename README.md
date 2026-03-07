# Underwater Infrastructure (EKS Repo)

This repository contains all infrastructure code for the Underwater project. Application code lives in `underwater-app` and Kubernetes manifests live in `underwater-manifests`.

---

## Repository Structure

```
EKS/
├── Dockerfile.jenkins       # Custom Jenkins image with DevSecOps tools
├── Jenkinsfile.infra        # Infrastructure pipeline (Plan/Apply/Destroy)
├── docker-compose.yml       # Local DevSecOps stack
├── prometheus.yml           # Local Prometheus scrape config
│
├── environments/
│   ├── dev/                 # Dev environment Terraform
│   │   ├── backend.tf       # S3 state backend config
│   │   ├── providers.tf     # AWS provider
│   │   ├── variables.tf     # Variable definitions
│   │   ├── terraform.tfvars # Dev values (SPOT nodes, 2 AZs)
│   │   ├── vpc.tf           # VPC module call
│   │   ├── eks.tf           # EKS cluster + access entries
│   │   ├── irsa.tf          # IRSA module call
│   │   ├── sns.tf           # SNS SMS alert (3hr runtime warning)
│   │   └── outputs.tf       # Output values
│   └── prod/                # Prod environment (same structure)
│
├── modules/
│   ├── eks-cluster/         # EKS control plane + node groups
│   │   ├── eks.tf           # EKS cluster
│   │   ├── node_group.tf    # Node group + ECR/EBS IAM policies
│   │   ├── sg.tf            # Security group rules
│   │   ├── addons.tf        # VPC CNI, CoreDNS, EBS CSI driver
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks-irsa/            # IAM Roles for Service Accounts
│   ├── eks-vpc/             # VPC, subnets, NAT Gateway
│   └── ecr/                 # ECR repositories
│
└── global/
    └── ecr/                 # Shared ECR repos (applied once, never destroyed)
```

---

## Three Repo Structure

```
EKS (this repo)          → Terraform infrastructure + infra-pipeline
underwater-app           → Application code + Dockerfile + app pipeline
underwater-manifests     → Flux/Kubernetes manifests (GitOps)
```

---

## Two Jenkins Pipelines

```
infra-pipeline           → Plan/Apply/Destroy EKS cluster
                           triggered manually
                           watches: EKS repo, develop branch
                           script: Jenkinsfile.infra

underwater-pipeline      → Build/scan/push Docker image
                           triggered automatically on code push
                           watches: underwater-app repo, develop branch
                           script: Jenkinsfile
```

---

## Prerequisites

### Tools Required

Install in WSL (Ubuntu 22.04):

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
aws configure
# AWS Access Key ID:     <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region:        us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

---

## Step 1 — Create Terraform State Backend (One Time)

```bash
# Create S3 bucket
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

Update `environments/dev/backend.tf` with your bucket name.

---

## Step 2 — Create ECR Repositories (One Time)

```bash
cd global/ecr
terraform init
terraform apply
```

Creates three ECR repositories: `underwater`, `auth-service`, `api-service`.

> ⚠️ Never run `terraform destroy` in global/ecr — ECR repos persist across cluster destroy/apply cycles.

---

## Step 3 — Start Local DevSecOps Stack

```bash
# Required for SonarQube
sudo sysctl -w vm.max_map_count=262144

# Start stack
docker compose up -d

# Verify
docker compose ps
```

Services:
```
Jenkins     → http://localhost:8080
SonarQube   → http://localhost:9000
Grafana     → http://localhost:3000  (monitors Jenkins/SonarQube)
Prometheus  → http://localhost:9090
```

### Jenkins Initial Setup

```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Open `http://localhost:8080` → paste password
2. Install suggested plugins
3. Create admin user
4. Install additional plugins: Docker Pipeline, Kubernetes, Amazon ECR, AWS Credentials, SonarQube Scanner, SSH Agent, Blue Ocean, Prometheus metrics

### Jenkins Credentials Setup

Go to **Manage Jenkins → Credentials → System → Global → Add Credentials**:

| ID | Kind | Value |
|----|------|-------|
| `sonar-token` | Secret text | SonarQube token |
| `github-token` | Username with password | GitHub username + PAT |
| `github-ssh-key` | SSH Username with private key | Contents of `~/.ssh/jenkins_key` |
| `snyk-token` | Secret text | Snyk auth token |
| `alert-phone-number` | Secret text | Phone number e.g. +12345678900 |

> ⚠️ `github-token` must be **Username with password** type — Secret text does not appear in SCM credential dropdowns.

### SonarQube Setup

1. Open `http://localhost:9000` → login `admin/admin` → change password
2. Generate token: **My Account → Security → Generate Token** (Global Analysis Token)
3. Create webhook: **Administration → Configuration → Webhooks → Create**
   - Name: `jenkins`, URL: `http://jenkins:8080/sonarqube-webhook/`
4. Create project: **Create Project → Local → underwater**

### Prometheus Metrics Plugin

```
Manage Jenkins → Plugins → Available
→ Search: Prometheus metrics → Install
→ Manage Jenkins → System → Prometheus
→ Uncheck: Enable authentication for prometheus end-point
→ Apply → Save
```

### SSH Key for Manifests Repo

```bash
ssh-keygen -t ed25519 -C "jenkins@underwater" -f ~/.ssh/jenkins_key -N ""
cat ~/.ssh/jenkins_key.pub
# GitHub → underwater-manifests → Settings → Deploy Keys → Add
# ✅ Allow write access
```

### SonarQube Secrets File

```bash
mkdir -p ~/code/EKS/.secrets
echo -n "your-sonarqube-password" > ~/code/EKS/.secrets/sonarqube_password
echo ".secrets/" >> ~/code/EKS/.gitignore
```

---

## Step 4 — Create Jenkins Pipelines

### infra-pipeline

```
Jenkins → New Item → Pipeline

Name: infra-pipeline

Parameters:
  ACTION:      Choice → Plan, Apply, Destroy
  ENVIRONMENT: Choice → dev, prod

Pipeline:
  Definition:  Pipeline script from SCM
  SCM:         Git
  Repository:  https://github.com/<username>/EKS.git
  Credentials: github-token
  Branch:      */develop
  Script Path: Jenkinsfile.infra

→ Apply → Save
```

### underwater-pipeline

```
Jenkins → New Item → Pipeline

Name: underwater-pipeline

Parameters:
  ACTION:       Choice → Deploy
  SERVICE_NAME: Choice → underwater, auth-service, api-service

Build Triggers:
  ✅ Poll SCM → H/5 * * * *

Pipeline:
  Definition:  Pipeline script from SCM
  SCM:         Git
  Repository:  https://github.com/<username>/underwater-app.git
  Credentials: github-token
  Branch:      */develop
  Script Path: Jenkinsfile

→ Apply → Save
```

---

## Step 5 — Deploy EKS Cluster via infra-pipeline

> ⚠️ Cost Warning: EKS costs ~$4/day. Destroy when not in use.

```
Jenkins → infra-pipeline → Build with Parameters
ACTION:      Plan       ← review changes first
ENVIRONMENT: dev
→ Build

# Review tfplan.txt in build artifacts, then:
ACTION:      Apply
ENVIRONMENT: dev
→ Build → click Apply when prompted
```

Resources created:
```
VPC                      → 2 public + 2 private subnets across 2 AZs
NAT Gateway              → private subnet internet access
EKS cluster              → Kubernetes 1.34, underwater-dev
Node group               → 2x t3.medium SPOT instances
IAM roles                → node group ECR + EBS CSI policies
EKS access entry         → devops-admin cluster admin access
EBS CSI driver addon     → persistent volume support
Default storage class    → gp2 set as default for PVC provisioning
SNS topic + subscription → SMS alert after 3 hours runtime
EventBridge rule         → triggers SNS every 3 hours
```

---

## Step 6 — Bootstrap Flux

Run after infra-pipeline Apply completes:

```bash
# Pull latest manifests
cd ~/code/underwater-manifests
git pull origin main --rebase

# Bootstrap Flux with image automation
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=underwater-manifests \
  --branch=main \
  --path=clusters/dev \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller

# Pull after bootstrap (Flux writes to repo)
git pull origin main --rebase
```

Flux automatically deploys:
```
underwater app           → from apps/base/underwater/
kube-prometheus-stack    → Prometheus + Grafana on cluster
ingress-nginx            → AWS NLB for public app access
```

---

## Step 7 — Deploy App via underwater-pipeline

```
Jenkins → underwater-pipeline → Build with Parameters
ACTION:       Deploy
SERVICE_NAME: underwater
→ Build
```

Access the app:
```bash
# Get public URL
kubectl get svc -n ingress-nginx

# Open in browser (no port-forward needed)
http://<elb-hostname>
```

---

## Daily Workflow

### Morning (start)
```bash
# Start local stack
cd ~/code/EKS
sudo sysctl -w vm.max_map_count=262144
docker compose up -d

# Deploy cluster
infra-pipeline → Plan → Apply  (~20 mins)

# Bootstrap Flux (needed after every cluster recreate)
flux bootstrap github \
  --owner=ioyebode-dcca \
  --repository=underwater-manifests \
  --branch=main \
  --path=clusters/dev \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller

# Pull after bootstrap
cd ~/code/underwater-manifests && git pull origin main --rebase

# Deploy app
underwater-pipeline → Deploy → underwater
```

### Evening (destroy)
```bash
# Destroy cluster via pipeline
infra-pipeline → Destroy → dev

# Stop local stack
docker compose down
```

---

## What Gets Destroyed vs Preserved

```
DESTROYED by infra-pipeline Destroy:
  EKS cluster + nodes
  VPC + subnets + NAT Gateway
  IAM roles
  SNS topic + EventBridge rule
  EBS volumes (PVCs)

PRESERVED (never destroyed):
  ECR repositories        → global/ecr, separate state
  Docker images in ECR    → persist across cluster cycles
  S3 state bucket         → created manually
  DynamoDB lock table     → created manually
  Local Jenkins/SonarQube → docker compose, separate from cluster
```

---

## Branch Strategy

```
main      → protected, PR + approval required
develop   → active development, infra-pipeline and app-pipeline watch this
release   → prod deployments

Workflow:
feature/* → PR → develop → pipelines trigger → dev cluster
develop   → PR → release → prod pipeline → prod cluster
```

---

## Monitoring

Two Grafana instances:

```
Local Docker Grafana (http://localhost:3000):
  → monitors Jenkins build metrics
  → starts with docker compose up

EKS Grafana (kubectl port-forward):
  kubectl port-forward svc/prometheus-grafana 3001:80 -n monitoring
  → http://localhost:3001  (admin/admin)
  → monitors pods, nodes, deployments
  → deployed automatically by Flux
```

Pre-built Kubernetes dashboards:
```
Dashboards → Kubernetes / Compute Resources / Cluster
Dashboards → Kubernetes / Compute Resources / Namespace → underwater
Dashboards → Kubernetes / Nodes
```

---

## Cost Summary

| Resource | Running | Destroyed |
|----------|---------|-----------|
| EKS Control Plane | $0.10/hr | $0 |
| 2x t3.medium SPOT | ~$0.03/hr | $0 |
| NAT Gateway | $0.045/hr | $0 |
| ECR Images | ~$0.05/mo | ~$0.05/mo |
| S3 + DynamoDB | ~$0.001/mo | ~$0.001/mo |
| **Total active** | **~$4/day** | **~$0.05/mo** |

---

## Troubleshooting

**SonarQube not starting:**
```bash
sudo sysctl -w vm.max_map_count=262144
docker compose restart sonarqube
```

**Prometheus secrets not mounting:**
```bash
# Bring down and up (restart doesn't remount volumes)
docker compose down prometheus
docker compose up -d prometheus
docker exec prometheus ls /etc/prometheus/
```

**Terraform: module directory not found:**
```
After moving dev/ to environments/dev/ module paths changed.
Fix: update source = "../modules/" to "../../modules/" in all .tf files
     sed -i 's|../modules/|../../modules/|g' environments/dev/*.tf
```

**Terraform: Can't set variables when applying a saved plan:**
```
Remove -var flags from terraform apply — variables are baked into tfplan during plan.
Only pass -var flags to terraform plan, not apply.
```

**kubectl: server has asked for credentials:**
```
IAM access entry not created yet.
Fix: add aws_eks_access_entry and aws_eks_access_policy_association
     to environments/dev/eks.tf (already in current config)
```

**Monitoring pods Pending (PVC unbound):**
```
Node IAM role missing EBS permissions or gp2 not default storage class.
Fix: AmazonEBSCSIDriverPolicy is attached in modules/eks-cluster/node_group.tf
     gp2 default class set via null_resource in environments/dev/eks.tf
     If still stuck: kubectl patch storageclass gp2 \
       -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
     Then: kubectl delete pvc -n monitoring --all
```

**Git push rejected (fetch first):**
```
Flux or Jenkins pushed to repo while you were working.
Fix: git pull origin main --rebase
     git push origin main
```