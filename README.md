# underwater-infra

Terraform infrastructure and Jenkins pipeline for the Octopus Underwater App.

## Repository Structure

```
underwater-infra/
├── modules/
│   ├── vpc/          # VPC, subnets, NAT gateway
│   ├── eks/          # EKS 1.34, addons (vpc-cni, ebs-csi, coredns)
│   ├── irsa/         # IAM roles for Jenkins, Flux, VPC CNI, EBS CSI
│   └── ecr/          # (reference — ECR lives in global/)
├── environments/
│   ├── dev/          # develop branch → dev cluster
│   └── prod/         # release branch → prod cluster
├── global/
│   └── ecr/          # ECR repos shared between dev and prod
├── Dockerfile        # nginx:1.25-alpine, hardened
├── nginx.conf        # Security headers, SPA routing
└── Jenkinsfile       # Full CI/CD pipeline with security scanning
```

## Branch → Environment Mapping

| Branch    | Environment | Image Tag       | EKS Cluster          |
|-----------|-------------|-----------------|----------------------|
| develop   | dev         | dev-{build}     | underwater-dev       |
| release   | prod        | release-{build} | underwater-prod      |

## First-Time Setup

### 1. Create S3 state bucket and DynamoDB lock table
```bash
aws s3api create-bucket \
  --bucket izzy-terraform \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket izzy-terraform \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Create ECR repos (one time, shared)
```bash
cd global/ecr
terraform init && terraform apply
```

### 3. Deploy dev environment
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Bootstrap Flux onto dev cluster
```bash
aws eks update-kubeconfig --name underwater-dev --region us-east-1

flux bootstrap github \
  --owner=your-github-username \
  --repository=underwater-manifests \
  --branch=main \
  --path=clusters/dev \
  --personal
```

### 5. Deploy prod environment
```bash
cd environments/prod
terraform init
terraform plan
terraform apply

# Bootstrap Flux on prod
aws eks update-kubeconfig --name underwater-prod --region us-east-1

flux bootstrap github \
  --owner=your-github-username \
  --repository=underwater-manifests \
  --branch=main \
  --path=clusters/prod \
  --personal
```

## Cost Estimate

| Environment | Monthly Cost |
|-------------|-------------|
| Dev (SPOT nodes) | ~$80-100 |
| Prod (ON_DEMAND) | ~$180-220 |

> Tip: Run `terraform destroy` on dev when not in use to save cost.
