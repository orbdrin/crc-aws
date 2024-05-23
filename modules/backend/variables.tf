# Input Variable Definitions
# Values Can Be Modified at Runtime

variable "api_gw_name" {
  type        = string
  description = "API Gateway Name"
  default     = "crc-http-lambda"
}

variable "api_gw_staging_name" {
  type        = string
  description = "API Gateway Name"
  default     = "crc-http-lambda-stage"
}

variable "api_gw_log_retention" {
  type        = number
  description = "API Gateway Log Retention Period (In Days)"
  default     = 7
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB Table Name"
  default     = "crc-visitors"
}

variable "lambda_name" {
  type        = string
  description = "Lambda Function Name"
  default     = "crc-visitors-count"
}

variable "lambda_bucket_name" {
  type        = string
  description = "S3 Bucket for Lambda Function"
  default     = "crc-aws-lambda"
}

variable "lambda_log_retention" {
  type        = number
  description = "Lambda Function Log Retention Period (In Days)"
  default     = 7
}