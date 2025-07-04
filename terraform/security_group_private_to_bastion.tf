# resource "aws_security_group" "security_group_private_to_bastion" {
#   vpc_id = aws_vpc.main.id
#
#   ingress {
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"
#     # cidr_blocks = [aws_subnet.public_subnet_1.cidr_block]
#     security_groups = [aws_security_group.security_group_public_from_bastion.id]
#     description     = "Allow SSH only from Bastion SG"
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "security_group_private_to_bastion"
#   }
# }
