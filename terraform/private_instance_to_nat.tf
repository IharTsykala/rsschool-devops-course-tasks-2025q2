resource "aws_instance" "private_instance_to_nat" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.private_subnet_1.id

  tags = {
    Name = "private_instance_to_nat"
  }
}
