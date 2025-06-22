resource "aws_instance" "private_instance_to_bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.security_group_private_to_bastion.id,
  ]

  tags = {
    Name = "private_instance_to_bastion"
  }
}
