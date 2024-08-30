resource "aws_iam_openid_connect_provider" "github_actions_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_action_role" {
  name               = "github_action_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_write" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject"
    ]
    resources = ["${var.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "allow_push_to_civil_service_jobs_s3_bucket_policy"
  policy = data.aws_iam_policy_document.s3_write.json
}

resource "aws_iam_role_policy_attachment" "github_can_write_to_s3" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.s3.arn
}

data "aws_iam_policy_document" "dynamodb_write" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem", 
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = var.dynamodb_table_arns
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name   = "allow_write_to_civil_service_jobs_dynamodb_policy"
  policy = data.aws_iam_policy_document.dynamodb_write.json
}

resource "aws_iam_role_policy_attachment" "dynamodb" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}