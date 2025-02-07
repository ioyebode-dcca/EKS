# ✅ Ensure kubeconfig is updated
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "🔄 Updating kubeconfig for EKS cluster..."
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1

      echo "⏳ Waiting for EKS cluster to become active..."
      aws eks wait cluster-active --name ${module.eks.cluster_name}

      echo "⏳ Waiting 60s for cluster API stability..."
      sleep 60
    EOT
  }
}

# ✅ Verify cluster connectivity
resource "null_resource" "verify_connection" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "🔄 Checking cluster connectivity..."
      for i in {1..10}; do
        if kubectl get ns kube-system > /dev/null 2>&1; then
          echo "✅ Successfully connected to cluster"
          exit 0
        fi
        echo "⏳ Attempt $i: Waiting for cluster connectivity..."
        sleep $((10 * i))  # Exponential backoff (10s, 20s, 30s...)
      done
      echo "❌ ERROR: Failed to connect to cluster after multiple attempts"
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
      echo "🔄 Applying aws-auth ConfigMap for worker nodes..."
      for i in {1..5}; do
        if kubectl apply -f - <<EOF
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
          echo "✅ aws-auth ConfigMap applied successfully!"
          exit 0
        fi
        echo "⏳ Attempt $i: Retrying aws-auth ConfigMap creation..."
        sleep 30
      done
      echo "❌ ERROR: Failed to apply aws-auth ConfigMap after multiple attempts"
      exit 1
    EOT
  }
}
