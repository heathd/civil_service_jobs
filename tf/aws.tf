terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59.0"
    }
  }

  required_version = ">= 1.9.2"
}

provider "aws" {
  region = "eu-west-1"
}

# Create the S3 bucket
resource "aws_s3_bucket" "civil_service_jobs_data" {
  bucket = "civil-service-jobs-data"
}

# Policy to allow public read access to the bucket
resource "aws_s3_bucket_policy" "civil_service_jobs_data_policy" {
  bucket = aws_s3_bucket.civil_service_jobs_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.civil_service_jobs_data.arn}/*"
        Principal = "*"
      }
    ]
  })
}


# Disable block all public access setting
resource "aws_s3_bucket_public_access_block" "civil_service_jobs_data_public_access" {
  bucket = aws_s3_bucket.civil_service_jobs_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "civil_service_jobs_data_versioning" {
  bucket = aws_s3_bucket.civil_service_jobs_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "civil_service_jobs_data_lifecycle" {
  bucket = aws_s3_bucket.civil_service_jobs_data.id

  rule {
    id     = "limit-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      newer_noncurrent_versions = 7
      noncurrent_days = 30
    }
  }
}

# Create IAM Role for GitHub Action

resource "aws_iam_openid_connect_provider" "github_actions_oidc_role" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  #the following thumbprint value is not used by github/aws but is required in the config
  #see: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html#manage-oidc-provider-console
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

data "aws_iam_policy_document" "github_action_role_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"
    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions_oidc_role.arn]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:heathd/civil_service_jobs:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_action_role" {
  name = "github_action_role"

  assume_role_policy = data.aws_iam_policy_document.github_action_role_policy.json
}

# Attach policy to the role to allow pushing to S3 bucket
resource "aws_iam_policy" "github_action_s3_policy" {
  name        = "github_action_s3_policy"
  description = "Policy for GitHub Actions to push to S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.civil_service_jobs_data.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_action_policy_attachment" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.github_action_s3_policy.arn
}
