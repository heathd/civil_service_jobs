output "table_arns" {
  value = [aws_dynamodb_table.jobs.arn, aws_dynamodb_table.jobs_activity.arn]
}