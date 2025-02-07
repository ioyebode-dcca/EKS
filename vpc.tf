resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
    "kubernetes.io/cluster/DevOps-cluster" = "shared"
  }
}

resource "aws_subnet" "eks_subnet" {
  count = 3

  cidr_block = "10.0.${count.index + 1}.0/24"
  vpc_id     = aws_vpc.eks_vpc.id 
  availability_zone = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)
  
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/DevOps-cluster" = "shared"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/role/internal-elb" = 1
  }
}

# Ensure internet connectivity
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "eks_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-rt"
  }
}

resource "aws_route_table_association" "eks_rta" {
  count = 3
  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_rt.id
}

# Update security group rules
resource "aws_security_group" "eks_sg" {
  name_prefix = "eks-"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound traffic for EKS API from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Or restrict to trusted IPs if needed
  }

  # ✅ Allow all traffic within the VPC CIDR (Worker Nodes <--> Control Plane)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]  # Allow all internal traffic
  }

  # ✅ Allow all outbound traffic to any destination (Fixes API connectivity)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allowing all outbound traffic
  }

  tags = {
    Name = "eks-security-group"
  }
}
