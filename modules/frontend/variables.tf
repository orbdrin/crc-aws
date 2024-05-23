# Input Variable Definitions
# Values Can Be Modified at Runtime

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
  default     = "jinningtioh.com"
}
 
variable "domain_name" {
  type        = string
  description = "Custom Domain Name"
  default     = "jinningtioh.com"
}

variable "cloudfront_origin_id" {
  type        = string
  description = "CloudFront Origin ID"
  default     = "crc-s3-cloudfront"
}
