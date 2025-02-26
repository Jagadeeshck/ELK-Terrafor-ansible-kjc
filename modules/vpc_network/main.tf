resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags       = { Name = var.vpc_name }
}

resource "aws_subnet" "public" {
  count             = var.is_routable ? var.az_count : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = { Name = "${var.vpc_name}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.az_count)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags              = { Name = "${var.vpc_name}-private-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  count  = var.is_routable ? 1 : 0
  vpc_id = aws_vpc.main.id
}

data "aws_availability_zones" "available" {
  state = "available"
}