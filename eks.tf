provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet" {
  count = 3 # Replace with the number of subnets you want to create

  cidr_block = "10.0.${count.index}.0/24" # Replace with your desired subnet CIDR block

  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

resource "aws_security_group" "eks_sg" {
  name_prefix = "eks-"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

data "aws_ami" "eks_worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["eks-worker-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["602401143452"] # The official AWS EKS AMI owner ID
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.5.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.21"
  subnets         = ["subnet-06d634c2ec29a61ac", "subnet-0937cce09d1668c4b", "subnet-0bd163902e4165d24"] # Replace with the IDs of your VPC subnets
  vpc_id          = "vpc-0bdba944130cdb522" # Replace with the ID of your VPC

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  worker_groups_launch_template = [
    {
      name                 = "my-eks-worker-group"
      instance_type       = "t2.small"
      asg_desired_capacity = 2
      additional_security_group_ids = ["sg-080799143e51cee36"] # Replace with the IDs of any additional security groups
      subnets             = ["subnet-0bd163902e4165d24", "subnet-0937cce09d1668c4b", "subnet-06d634c2ec29a61ac"] # Replace with the IDs of your VPC subnets
      tags = {
        Terraform   = "true"
        Environment = "dev"
      }
    }
  ]
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}
