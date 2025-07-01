
resource "aws_security_group" "k3s_control_sg" {
  name        = "k3s-control-sg"
  description = "Allow SSH from bastion and k8s API inside VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_public_from_bastion.id]
  }

  ingress {
    description = "k8s API from VPC"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-k3s-control"
  }
}

resource "aws_security_group" "k3s_worker_sg" {
  name        = "k3s-worker-sg"
  description = "Allow SSH from bastion and k3s node communication"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.security_group_public_from_bastion.id]
  }

  ingress {
    description = "kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-k3s-worker"
  }
}
