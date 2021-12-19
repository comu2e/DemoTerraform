resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sigstore"]
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
}
# ECR.ECSの操作用に追加
resource "aws_iam_role_policy_attachment" "poweruser" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
resource "aws_iam_role" "github_actions" {
  name               = "${var.system}-github-actions"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Federated": "${aws_iam_openid_connect_provider.github_actions.id}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringLike": {"token.actions.githubusercontent.com:sub":"repo:${var.github_repo}:*"}
    }
  }
]
}
  EOF
}

variable "system" {
  type = string
}
variable "github_repo" {
  type = string
}

output "github_role" {
  value = aws_iam_role.github_actions
}
