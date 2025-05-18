resource "aws_iam_user" "developer" {
  name = "developer"
  path = "/developers/"
}

resource "aws_iam_policy" "developer_eks" {
  name = "AmazonEKSDeveloperPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

# Create a iam group for developers
resource "aws_iam_group" "developer_group" {
  name = "developer-group"
  path = "/developers/"
}

# Attach the policy to the group
resource "aws_iam_group_policy_attachment" "developer_eks" {
  group      = aws_iam_group.developer_group.name
  policy_arn = aws_iam_policy.developer_eks.arn
}

# attach the group to the user
resource "aws_iam_user_group_membership" "developer_group_membership" {
  user = aws_iam_user.developer.name
  groups = [
    aws_iam_group.developer_group.name,
  ]
}

# eks access entry for the group
resource "aws_eks_access_entry" "developer_group" {
  cluster_name = "staging-demo"
  principal_arn = aws_iam_user.developer.arn
  kubernetes_groups = ["my-viewer"]
}

# Create access keys for the user
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

output "access_key_id" {
  value = aws_iam_access_key.developer.id
}

output "secret_key" {
  value = aws_iam_access_key.developer.secret
  sensitive = true
}