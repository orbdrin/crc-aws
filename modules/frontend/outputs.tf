# Output Value Definitions

output "website_endpoint" {
  description = "S3 Bucket Website Endpoint"
  value       = aws_s3_bucket.crc_bucket.bucket_regional_domain_name
}