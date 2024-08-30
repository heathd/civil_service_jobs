resource "aws_dynamodb_table" "jobs" {
  name           = "civil_service_jobs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "refcode"
  range_key      = "record_type"

  attribute {
    name = "refcode"
    type = "S"
  }

  attribute {
    name = "record_type"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_dynamodb_table" "jobs_activity" {
  name         = "civil_service_jobs_activity"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}