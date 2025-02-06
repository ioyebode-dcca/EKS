Octopus Underwater App
This app is a simple web application that demonstrates CI/CD with Jenkins, Docker, AWS EKS, and Terraform.
Prerequisites
Jenkins Installation
Follow this guide for Jenkins installation on AWS EC2:
https://medium.com/@oladejit3/how-to-install-jenkins-on-aws-ec2-instance-4ec700f68948
Required Tools

Terraform

Installation guide: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli


Docker

Installation guide: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-docker.html


Node.js
bashCopy# Install Node.js 16.x
curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -

# Install required dependencies
sudo yum install gcc-c++ make

# Install Node.js
sudo yum install nodejs

# Verify installations
node -v  # Should show v16.17.0
npm -v   # Should show 8.15.0


Jenkins Pipeline Configuration
The project includes two pipeline options:
1. Full Deployment Pipeline

Cleans workspace
Clones repository
Sets up and verifies tools
Deploys infrastructure with Terraform
Builds and pushes Docker images
Deploys to Kubernetes

2. Parameterized Pipeline
The pipeline now supports two modes of operation:

Deploy: Runs the full deployment pipeline
Destroy: Cleans up all resources

To use the parameterized pipeline:

Select 'Build with Parameters' in Jenkins
Choose either 'Deploy' or 'Destroy' from the ACTION parameter
Click 'Build'

Resource Cleanup
The destroy operation will:

Remove Kubernetes deployments and services
Clean up ECR images
Destroy all Terraform-managed infrastructure (EKS, ASG, etc.)
Remove local Docker images

Required Jenkins Credentials
Set up the following credentials in Jenkins:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

Pipeline Stages
groovyCopystages {
    Clean workspace
    Clone Repository
    Set Terraform path
    Verify Tools (Terraform, Docker, AWS)
    Verify Other Tools (Git, NPM, Ansible)
    Terraform Plan
    Check Plan
    Apply
    Build Docker Image
    Test
    Push Docker Image to Registry
    Deploy
    Cleanup Resources (when destroying)
}
Important Notes

Always review Terraform plans before applying
The destroy operation is irreversible
Cleanup can be run independently by selecting 'Destroy' in the pipeline parameters
ECR images are removed during cleanup but the repository is preserved

Cost Management

ECR usage incurs storage and data transfer costs
Remember to clean up resources when not in use
Use the destroy pipeline to remove all infrastructure and avoid unnecessary charges