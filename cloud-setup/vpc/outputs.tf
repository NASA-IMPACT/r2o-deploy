output "vpc_id" {
  description = "ID of the created VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.create_vpc ? aws_subnet.public[*].id : null
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.create_vpc ? aws_subnet.private[*].id : null
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = var.create_vpc ? aws_route_table.private[0].id : null
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.create_vpc ? aws_route_table.public[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if created)"
  value       = var.create_vpc ? aws_nat_gateway.nat[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.create_vpc ? aws_vpc.main[0].cidr_block : null
}