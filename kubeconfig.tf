# First update kubeconfig
resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1
      echo "Waiting 60 seconds for cluster endpoint..."
      sleep 60
    EOT
  }
}

# Create aws-auth ConfigMap
resource "null_resource" "create_aws_auth" {
  depends_on = [null_resource.update_kubeconfig]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      kubectl apply -f - --validate=false <<EOF
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