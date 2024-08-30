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

# S3 Module
module "s3" {
  source = "./modules/s3"

  bucket_name = "civil-service-jobs-data"
  environment = "production"
  project     = "Civil Service Jobs"
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  environment = "production"
  project     = "Civil Service Jobs"
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  s3_bucket_arn         = module.s3.bucket_arn
  dynamodb_table_arns   = module.dynamodb.table_arns
  github_repo           = "heathd/civil_service_jobs"
  github_branch         = "main"
}


# Moved things

moved {
  from = aws_s3_bucket.civil_service_jobs_data
  to = module.s3.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket.civil_service_jobs_data
  to = module.s3.aws_s3_bucket.this
}

moved {
  from = aws_dynamodb_table.civil_service_jobs
  to = module.dynamodb.aws_dynamodb_table.jobs
}

moved {
  from = aws_dynamodb_table.civil_service_jobs_activity
  to = module.dynamodb.aws_dynamodb_table.jobs_activity
}

moved {
  from = aws_iam_openid_connect_provider.github_actions_oidc
  to = module.iam.aws_iam_openid_connect_provider.github_actions_oidc
}

moved {
  from = aws_iam_policy.allow_push_to_civil_service_jobs_s3_bucket_policy
  to = module.iam.aws_iam_policy.allow_push_to_civil_service_jobs_s3_bucket_policy
}

moved {
  from = aws_iam_policy.allow_write_to_civil_service_jobs_dynamodb_policy
  to = module.iam.aws_iam_policy.allow_write_to_civil_service_jobs_dynamodb_policy
}
moved {
  from = aws_s3_bucket_lifecycle_configuration.civil_service_jobs_data_lifecycle
  to = module.s3.aws_s3_bucket_lifecycle_configuration.this
}