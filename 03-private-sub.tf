resource "aws_subnet" "private_subnet_01" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                        = "private_subnet_01_new"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private_subnet_02" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                        = "private_subnet_02_new"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# NAT gateway so worker nodes in the private subnets can reach the internet
# (pull container images, register with the EKS control plane).
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat_eip_new"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_01.id

  tags = {
    Name = "nat_gateway_new"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private_route_table_new"
  }
}

resource "aws_route_table_association" "private_assocate_01" {
  subnet_id      = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_assocate_02" {
  subnet_id      = aws_subnet.private_subnet_02.id
  route_table_id = aws_route_table.private.id
}
