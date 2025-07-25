resource "aws_network_acl" "network_acls_private" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
  ]

  tags = {
    Name = "private-nacl"
  }
}

resource "aws_network_acl_rule" "allow_ssh_from_bastion" {
  network_acl_id = aws_network_acl.network_acls_private.id
  rule_number    = 100
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "10.0.1.0/24"
  from_port      = 22
  to_port        = 22
  egress         = false
}

resource "aws_network_acl_rule" "all_outbound_private" {
  network_acl_id = aws_network_acl.network_acls_private.id
  rule_number    = 200
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  egress         = true
}

resource "aws_network_acl_rule" "allow_return_from_nat" {
  network_acl_id = aws_network_acl.network_acls_private.id
  rule_number    = 110
  protocol       = "-1"
  cidr_block     = "10.0.1.0/24"
  from_port      = 0
  to_port        = 0
  egress         = false
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "allow_all_inbound" {
  network_acl_id = aws_network_acl.network_acls_private.id
  rule_number    = 120
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  egress         = false
}
