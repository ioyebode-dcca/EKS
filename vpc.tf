# ✅ Create VPC for EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
    "kubernetes.io/cluster/DevOps-cluster" = "shared"
  }
}

# ✅ Create Public Subnets for Worker Nodes
resource "aws_subnet" "eks_subnet" {
  count = 3

  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)
  map_public_ip_on_launch = true  # Ensure public subnets allow internet access

  tags = {
    Name = "eks-public-subnet-${count.index}"
    "kubernetes.io/cluster/DevOps-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# ✅ Create Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

# ✅ Create Route Table for Public Subnets
resource "aws_route_table" "eks_public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

# ✅ Associate Public Subnets with Route Table
resource "aws_route_table_association" "eks_public_rta" {
  count = 3
  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_public_rt.id
}

# ✅ Create Security Group for EKS Cluster & Worker Nodes
resource "aws_security_group" "eks_sg" {
  name_prefix = "eks-"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound traffic for EKS API
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic within the VPC CIDR
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
  }

  # Allow worker nodes to access the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-security-group"
  }
}
