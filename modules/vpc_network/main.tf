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

resource "aws_route_table" "public" {
  count  = var.is_routable ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.is_routable ? var.az_count : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}