# Define the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Define the virtual machines for the cluster
resource "aws_instance" "kubernetes_nodes" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# Define the networking components
resource "aws_security_group" "kubernetes" {
  name_prefix = "kubernetes-"
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "kubernetes" {
  count = 3
  cidr_block = "10.0.${count.index + 1}.0/24"
}

resource "aws_elb" "kubernetes" {
  name = "kubernetes"
  subnets = aws_subnet.kubernetes.*.id
}

# Define Kubernetes as the cluster management tool
module "kubernetes" {
  source = "github.com/terraform-aws-modules/kubernetes/aws"
  git    = "ssh"
  
  # Pass in the necessary configuration parameters
  worker_instance_type = "t2.micro"
  num_workers          = 3
  cluster_name         = "my-kubernetes-cluster"
  subnets              = aws_subnet.kubernetes.*.id
  vpc_id               = aws_vpc.main.id
  aws_region           = "us-west-2"
  tags                 = { Terraform = "true" }
  elb_name             = aws_elb.kubernetes.name
}
