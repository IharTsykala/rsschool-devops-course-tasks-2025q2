resource "aws_instance" "test_instance_private" {
  ami           = "ami-0df0e7600ad0913a9"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.allow_internal_traffic.id,
  ]

  tags = {
    Name = "test-instance-private"
  }
}
