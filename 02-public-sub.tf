data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet_01" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "public_subnet_01_new"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "route_assocate_01" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = data.aws_route_table.default-route-table.id
}

resource "aws_subnet" "public_subnet_02" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "public_subnet_02_new"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "route_assocate_02" {
  subnet_id      = aws_subnet.public_subnet_02.id
  route_table_id = data.aws_route_table.default-route-table.id
}
