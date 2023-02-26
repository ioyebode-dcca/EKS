provider "aws" {
  region = "us-west-1" # Replace with your desired AWS region
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

  cluster_name = "my-eks-cluster"

  subnets = [
    aws_subnet.eks_subnet[0].id,
    aws_subnet.eks_subnet[1].id,
    aws_subnet.eks_subnet[2].id,
  ]

  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  kubeconfig_aws_authenticator_additional_args = [
    "--region",
    "${var.region}",
  ]

  worker_groups_launch_template = [
    {
      name                 = "my-eks-worker-group"
      instance_type       = "t2.small"
      asg_desired_capacity = 2
      additional_security_group_ids = [
        aws_security_group.eks_sg.id
      ]
      ami_id              = data.aws_ami.eks_worker.id
      subnets             = [
        aws_subnet.eks_subnet[0].id,
        aws_subnet.eks_subnet[1].id,
        aws_subnet.eks_subnet[2].id,
      ]
      tags = {
        Terraform   = "true"
        Environment = "dev"
      }
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}
