data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_admin" {
  name               = "eks_admin"
  path               = "/admins/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "eks_admin" {
  name = "AmazonEKSAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

# Create the IAM user
resource "aws_iam_user" "admin_guy" {
  name = "admin_guy"
  path = "/admins/"
}

# Assume the role
resource "aws_iam_policy" "eks_assume_admin_role" {
  name = "AssumeEKSAdminRolePolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "${aws_iam_role.eks_admin.arn}"
        }
    ]

}
POLICY
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "eks_assume_admin_role" {
  user       = aws_iam_user.admin_guy.name
  policy_arn = aws_iam_policy.eks_assume_admin_role.arn
}

# eks access entry for the role
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name      = "staging-demo"
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["eks-admin"]
}

