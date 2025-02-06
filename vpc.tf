resource "aws_subnet" "eks_subnet" {
  count = 3 # Number of subnets to create

  cidr_block = "10.0.${count.index + 1}.0/24" # Ensure unique subnet CIDRs
  vpc_id     = aws_vpc.eks_vpc.id
  availability_zone = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)

  tags = {
    Name = "eks-subnet-${count.index}"
  }
}
