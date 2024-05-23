# Output Value Definitions

output "api_gw_url" {
  description = "API Gateway Stage URL"
  value       = aws_apigatewayv2_stage.http_lambda_stage.invoke_url
}

output "api_gw_log_group" {
  description = "CloudWatch log group for API Gateway."
  value       = aws_cloudwatch_log_group.api_gw_log.id
}

output "lambda_log_group" {
  description = "CloudWatch log group for lambda function."
  value       = aws_cloudwatch_log_group.lambda_log.id
}