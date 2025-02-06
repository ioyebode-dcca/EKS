resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1
      echo "Waiting for EKS cluster endpoint to be available..."
      until kubectl get svc; do sleep 10; done
    EOT
  }
}

# Create aws-auth ConfigMap
resource "null_resource" "create_aws_auth" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for cluster to be ready
      echo "Waiting for EKS cluster to be fully ready..."
      sleep 30

      # Create aws-auth configmap
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
      
      # Verify the configmap was created
      kubectl get configmap aws-auth -n kube-system
    EOT
  }
}

# Add a verification step
resource "null_resource" "verify_aws_auth" {
  depends_on = [null_resource.create_aws_auth]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying aws-auth configmap..."
      kubectl get configmap aws-auth -n kube-system -o yaml
    EOT
  }
}