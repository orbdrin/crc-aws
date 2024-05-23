#====================
# Providers
#====================

terraform { 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50.0"
    }
	
	archive = {
	  source  = "hashicorp/archive"
      version = "~> 2.4.2"
	}
  } 
}

#====================
# Module Source and Variables
#====================

module "frontend" {
  source               = "../modules/frontend"
  bucket_name          = "jinningtioh.com"
  cloudfront_origin_id = "crc-s3-cloudfront"
  domain_name          = "jinningtioh.com"
}

module "backend" {
  source               = "../modules/backend"
  api_gw_name          = "crc-http-lambda"
  api_gw_staging_name  = "crc-http-lambda-stage"
  api_gw_log_retention = 7
  dynamodb_table_name  = "crc-visitors"
  lambda_name          = "crc-visitors-count"
  lambda_bucket_name   = "crc-aws-lambda"
  lambda_log_retention = 7
}
