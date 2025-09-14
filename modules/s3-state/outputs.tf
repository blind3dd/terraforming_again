# S3 State Bucket Module Outputs

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.state_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.state_bucket.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.state_bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.state_bucket.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.state_bucket.hosted_zone_id
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.state_bucket.region
}

output "bucket_website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = aws_s3_bucket.state_bucket.website_endpoint
}

output "bucket_website_domain" {
  description = "The website domain, if the bucket is configured with a website"
  value       = aws_s3_bucket.state_bucket.website_domain
}
