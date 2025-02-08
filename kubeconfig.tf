resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Updating kubeconfig..."
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1

      echo "Waiting for EKS cluster..."
      aws eks wait cluster-active --name ${module.eks.cluster_name}

      sleep 60
    EOT
  }
}

resource "null_resource" "create_aws_auth" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Applying aws-auth ConfigMap..."
      kubectl apply -f - <<EOF
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
    EOT
  }
}
