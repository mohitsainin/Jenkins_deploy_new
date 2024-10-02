# Public Route Table and Routes
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }
  tags = merge(var.tags, { "Name" = "Public Route Table" })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = element(var.public_subnet_ids, count.index)
  route_table_id = aws_route_table.public.id
}



# Private Route Table and Routes
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { "Name" = "Private Route Table" })
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = element(var.private_subnet_ids, count.index)
  route_table_id = aws_route_table.private.id
}
