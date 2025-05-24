resource "aws_iam_user" "developer_guy" {
  name = "developer_guy"
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


# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "developer_eks" {
  user       = aws_iam_user.developer_guy.name
  policy_arn = aws_iam_policy.developer_eks.arn
}

# eks access entry for the user
resource "aws_eks_access_entry" "developer_guy" {
  cluster_name      = "staging-demo"
  principal_arn     = aws_iam_user.developer_guy.arn
  kubernetes_groups = ["developer-viewer"]
}

