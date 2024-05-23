#====================
# DynamoDB Setup
#====================

resource "aws_dynamodb_table" "visitors" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "N"
  }  
}

resource "aws_dynamodb_table_item" "item" {
  table_name = aws_dynamodb_table.visitors.name
  hash_key   = aws_dynamodb_table.visitors.hash_key

  item       = <<ITEM

{
    "id": {"N": "0"},
    "count": {"N": "1"}
}
ITEM

  lifecycle {
    ignore_changes = [item]
  }
}

#========================================================================
# Lambda Setup
#========================================================================

// Setting Up Private Bucket and Uploading Zip of Lambda Function.

resource "aws_s3_bucket" "crc_bucket_lambda" {
  bucket = var.lambda_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "crc_bucket_lambda_ownership" {
  bucket = aws_s3_bucket.crc_bucket_lambda.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "crc_bucket_lambda_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.crc_bucket_lambda_ownership]

  bucket = aws_s3_bucket.crc_bucket_lambda.id
  acl    = "private"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/counter_function.py"
  output_path = "${path.module}/counter_function.zip"
}

resource "aws_s3_object" "upload_zip" {
  bucket = aws_s3_bucket.crc_bucket_lambda.id
  key    = "counter_function.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

// Defining Lambda Function.

resource "aws_lambda_function" "counter_func" {
  function_name    = var.lambda_name
  description      = "Visitor Counter Function"
  s3_bucket        = aws_s3_bucket.crc_bucket_lambda.id
  s3_key           = aws_s3_object.upload_zip.key
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.9"
  handler          = "counter_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      databaseName = var.dynamodb_table_name
	}
  }
  
  depends_on = [aws_cloudwatch_log_group.lambda_log]
}

// Defining Lambda Function IAM Role.

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
	Statement = [
	{
	  Action = [
	    "dynamodb:GetItem",
		"dynamodb:PutItem",
		"dynamodb:UpdateItem"
	  ]
	  Effect = "Allow"
	  Resource = "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
	},
	{
	  Action = [
	    "logs:CreateLogGroup",
		"logs:CreateLogStream",
		"logs:PutLogEvents"
	  ]
	  Effect = "Allow"
	  Resource = "*"
	}
	]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.lambda_log_retention
}

#========================================================================
# API Gateway Setup
#========================================================================

resource "aws_apigatewayv2_api" "http_lambda" {
  name          = var.api_gw_name
  description   = "Receives Count Increment from Frontend and Returns Count from DynamoDB"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET"]
    allow_headers  = ["content-type"]
    max_age        = 300
  }
}

resource "aws_apigatewayv2_stage" "http_lambda_stage" {
  api_id      = aws_apigatewayv2_api.http_lambda.id
  name        = var.api_gw_staging_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_log.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  
  depends_on = [aws_cloudwatch_log_group.api_gw_log]
}

resource "aws_apigatewayv2_integration" "api_gw_lambda" {
  api_id             = aws_apigatewayv2_api.http_lambda.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.counter_func.invoke_arn
}

resource "aws_apigatewayv2_route" "any" {
  api_id    = aws_apigatewayv2_api.http_lambda.id
  route_key = "ANY /${var.lambda_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api_gw_lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.counter_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_lambda.execution_arn}/*/*/*"
}

resource "aws_cloudwatch_log_group" "api_gw_log" {
  name              = "${aws_apigatewayv2_api.http_lambda.name}"
  retention_in_days = var.api_gw_log_retention
}