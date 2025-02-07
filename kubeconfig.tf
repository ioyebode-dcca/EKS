# First ensure kubeconfig is updated
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Updating kubeconfig for EKS cluster..."
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1 --alias DevOps-cluster

      echo "Waiting for cluster API endpoint to be reachable..."
      aws eks wait cluster-active --name ${module.eks.cluster_name}

      echo "Waiting for cluster endpoint availability..."
      sleep 60
    EOT
  }
}

# Verify cluster connectivity
resource "null_resource" "verify_connection" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Checking cluster connectivity..."
      for i in {1..10}; do
        if kubectl get ns kube-system; then
          echo "✅ Successfully connected to cluster"
          exit 0
        fi
        echo "⏳ Attempt $i: Waiting for cluster connectivity..."
        sleep 30
      done
      echo "❌ Failed to connect to cluster after 10 attempts"
      exit 1
    EOT
  }
}

# ✅ Fix `aws-auth` ConfigMap to register worker nodes
resource "null_resource" "create_aws_auth" {
  depends_on = [null_resource.verify_connection]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Creating aws-auth ConfigMap for worker nodes..."
      cat <<EOF | kubectl apply -f -
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
      echo "✅ aws-auth ConfigMap applied successfully!"
    EOT
  }
}
