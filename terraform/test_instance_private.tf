# resource "aws_instance" "test_instance_private" {
#   ami           = data.aws_ami.amazon_linux_2.id
#   instance_type = var.bastion_instance_type
#   subnet_id     = aws_subnet.private_subnet_1.id
#
#   vpc_security_group_ids = [
#     aws_security_group.allow_internal_traffic.id,
#   ]
#
#   tags = {
#     Name = "test-instance-private"
#   }
# }
