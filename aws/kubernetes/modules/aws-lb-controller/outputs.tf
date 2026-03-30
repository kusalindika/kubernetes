output "lb_controller_role_arn" {
  description = "ARN of the IRSA role used by the AWS Load Balancer Controller."
  value       = aws_iam_role.lb_controller.arn
}

output "lb_controller_role_name" {
  description = "Name of the IRSA role used by the AWS Load Balancer Controller."
  value       = aws_iam_role.lb_controller.name
}

output "lb_controller_chart_version" {
  description = "Installed AWS Load Balancer Controller Helm chart version."
  value       = helm_release.aws_lb_controller.version
}

output "lb_controller_namespace" {
  description = "Namespace where the AWS Load Balancer Controller is installed."
  value       = helm_release.aws_lb_controller.namespace
}
