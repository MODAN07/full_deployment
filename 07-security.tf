resource "aws_security_group" "sec_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "sec_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_443_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = var.security_group_ingress_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = var.security_group_ingress_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = var.security_group_ingress_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_3000_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = var.security_group_ingress_cidr
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sec_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
