# DynamoDB State Lock Module Outputs

output "table_id" {
  description = "The name of the table"
  value       = aws_dynamodb_table.state_lock.id
}

output "table_arn" {
  description = "The ARN of the table"
  value       = aws_dynamodb_table.state_lock.arn
}

output "table_name" {
  description = "The name of the table"
  value       = aws_dynamodb_table.state_lock.name
}

output "table_stream_arn" {
  description = "The ARN of the Table Stream"
  value       = aws_dynamodb_table.state_lock.stream_arn
}

output "table_stream_label" {
  description = "A timestamp, in ISO 8601 format, for this stream"
  value       = aws_dynamodb_table.state_lock.stream_label
}

output "table_hash_key" {
  description = "The attribute to use as the hash (partition) key"
  value       = aws_dynamodb_table.state_lock.hash_key
}

output "table_range_key" {
  description = "The attribute to use as the range (sort) key"
  value       = aws_dynamodb_table.state_lock.range_key
}

output "table_billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  value       = aws_dynamodb_table.state_lock.billing_mode
}

output "table_read_capacity" {
  description = "The number of read units for this table"
  value       = aws_dynamodb_table.state_lock.read_capacity
}

output "table_write_capacity" {
  description = "The number of write units for this table"
  value       = aws_dynamodb_table.state_lock.write_capacity
}
