resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet" {
  count = 3  # Number of subnets to create

  cidr_block = "10.0.${count.index + 1}.0/24"
  vpc_id     = aws_vpc.eks_vpc.id 

  availability_zone = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}

resource "aws_security_group" "eks_sg" {
  name_prefix = "eks-"
  vpc_id      = var.vpc_id  # Ensure it uses the correct VPC ID

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-security-group"
  }
}

