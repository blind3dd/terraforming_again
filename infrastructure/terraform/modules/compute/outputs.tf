# Compute Module Outputs

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.main[*].id
}

output "instance_arns" {
  description = "ARNs of the EC2 instances"
  value       = aws_instance.main[*].arn
}

output "private_ips" {
  description = "Private IPs of the EC2 instances"
  value       = aws_instance.main[*].private_ip
}

output "public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = aws_eip.main[*].public_ip
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.main.key_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.main.arn
}



