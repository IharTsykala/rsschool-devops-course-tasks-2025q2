resource "aws_instance" "test_instance_public" {
  ami                         = "ami-0df0e7600ad0913a9"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.allow_internal_traffic.id,
  ]

  tags = {
    Name = "test-instance-public"
  }
}
