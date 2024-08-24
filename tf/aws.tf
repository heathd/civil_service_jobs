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

  tags = {
    Environment = "production"
    Project     = "Civil Service Jobs"
  }
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

## DynamoDB

resource "aws_dynamodb_table" "civil_service_jobs" {
  name           = "civil_service_jobs"
  billing_mode   = "PAY_PER_REQUEST"  # Use "PROVISIONED" if you want to specify read and write capacity units
  hash_key       = "refcode"          # Partition key (Primary Key)
  range_key      = "record_type"      # Sort key (Secondary Key)

  attribute {
    name = "refcode"
    type = "S"  # S for String, N for Number, B for Binary
  }

  attribute {
    name = "record_type"
    type = "S"  # S for String, N for Number, B for Binary
  }

  tags = {
    Environment = "production"
    Project     = "Civil Service Jobs"
  }
}

resource "aws_dynamodb_table" "civil_service_jobs_activity" {
  name           = "civil_service_jobs_activity"
  billing_mode   = "PAY_PER_REQUEST"  # Use "PROVISIONED" if you want to specify read and write capacity units
  hash_key       = "id"          # Partition key (Primary Key)

  attribute {
    name = "id"
    type = "S"  # S for String, N for Number, B for Binary
  }

  tags = {
    Environment = "production"
    Project     = "Civil Service Jobs"
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

data "aws_iam_policy_document" "allow_github_actions_to_assume_role" {
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

  assume_role_policy = data.aws_iam_policy_document.allow_github_actions_to_assume_role.json
}

# Define policies granting access for github to resources
data "aws_iam_policy_document" "allow_push_to_s3_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.civil_service_jobs_data.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "allow_push_to_civil_service_jobs_s3_bucket_policy" {
  name        = "allow_push_to_civil_service_jobs_s3_bucket_policy"
  description = "Policy allowing write access to the Civil Service Jobs S3 bucket"
  policy      = data.aws_iam_policy_document.allow_push_to_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "github_can_write_to_s3" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.allow_push_to_civil_service_jobs_s3_bucket_policy.arn
}

# Policy allowing write access to DynamoDB
data "aws_iam_policy_document" "allow_write_to_civil_service_jobs_dynamodb_tables" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem", 
      "dynamodb:Query",
      "dynamodb:Scan",
    ]

    resources = [
      aws_dynamodb_table.civil_service_jobs.arn,
      aws_dynamodb_table.civil_service_jobs_activity.arn
    ]
  }
}

resource "aws_iam_policy" "allow_write_to_civil_service_jobs_dynamodb_policy" {
  name        = "allow_write_to_civil_service_jobs_dynamodb_policy"
  description = "Policy allowing write access to the Civil Service Jobs DynamoDB tables"
  policy      = data.aws_iam_policy_document.allow_write_to_civil_service_jobs_dynamodb_tables.json
}

resource "aws_iam_role_policy_attachment" "github_can_write_to_dynamodb" {
  role       = aws_iam_role.github_action_role.name
  policy_arn = aws_iam_policy.allow_write_to_civil_service_jobs_dynamodb_policy.arn
}
