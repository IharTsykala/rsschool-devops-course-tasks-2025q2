resource "aws_security_group" "allow_internal_traffic" {
  name   = "allow-internal"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow all TCP from inside the VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-internal"
  }
}
