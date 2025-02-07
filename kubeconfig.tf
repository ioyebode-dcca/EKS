# First ensure kubeconfig is updated
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1
      echo "Waiting for cluster endpoint..."
      sleep 120  # Increased wait time
    EOT
  }
}

# Verify cluster connectivity
resource "null_resource" "verify_connection" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      for i in {1..10}; do
        if kubectl get ns kube-system; then
          echo "Successfully connected to cluster"
          exit 0
        fi
        echo "Attempt $i: Waiting for cluster connectivity..."
        sleep 30
      done
      echo "Failed to connect to cluster after 10 attempts"
      exit 1
    EOT
  }
}

# Create aws-auth ConfigMap with error handling
resource "null_resource" "create_aws_auth" {
  depends_on = [null_resource.verify_connection]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      for i in {1..5}; do
        if kubectl apply -f - --validate=false <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.worker_nodes_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF
        then
          echo "Successfully applied aws-auth ConfigMap"
          exit 0
        fi
        echo "Attempt $i: Retrying aws-auth ConfigMap creation..."
        sleep 30
      done
      echo "Failed to create aws-auth ConfigMap after 5 attempts"
      exit 1
    EOT
  }
}