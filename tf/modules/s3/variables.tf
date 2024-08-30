variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
}

variable "project" {
  description = "Project tag for resources"
  type        = string
}
