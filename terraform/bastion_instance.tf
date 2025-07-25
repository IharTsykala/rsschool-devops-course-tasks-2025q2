resource "aws_instance" "bastion_instance" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  key_name = aws_key_pair.cluster.key_name

  vpc_security_group_ids = [
    aws_security_group.security_group_public_from_bastion.id,
  ]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-ssm-agent
  EOF

  tags = {
    Name = "bastion-host"
  }
}
