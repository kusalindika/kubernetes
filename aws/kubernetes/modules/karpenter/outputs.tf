output "karpenter_role_arn" {
  description = "ARN of the Karpenter controller IRSA role."
  value       = aws_iam_role.karpenter.arn
}

output "karpenter_queue_name" {
  description = "Name of the SQS interruption queue."
  value       = aws_sqs_queue.karpenter.name
}

output "karpenter_queue_arn" {
  description = "ARN of the SQS interruption queue."
  value       = aws_sqs_queue.karpenter.arn
}
