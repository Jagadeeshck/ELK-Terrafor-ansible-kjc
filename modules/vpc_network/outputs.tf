output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "route_table_ids" {
  value = var.is_routable ? [aws_route_table.public[0].id] : aws_route_table.private[*].id
}