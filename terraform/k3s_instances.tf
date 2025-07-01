resource "aws_instance" "k3s_control" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.k3s_instance_type
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.k3s_control_sg.id]
  key_name               = aws_key_pair.cluster.key_name

  user_data = <<-EOF
#!/bin/bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode=644
EOF
  tags      = { Name = "k3s-control" }
}

resource "aws_instance" "k3s_worker" {
  count         = var.worker_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.k3s_instance_type
  subnet_id = element(
    [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id],
    count.index
  )
  vpc_security_group_ids = [aws_security_group.k3s_worker_sg.id]
  key_name               = aws_key_pair.cluster.key_name

  depends_on = [aws_instance.k3s_control]

  #   user_data = <<-EOF
  # #!/bin/bash
  # CONTROL_IP=${aws_instance.k3s_control.private_ip}
  # TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
  # curl -sfL https://get.k3s.io | K3S_URL=https://$CONTROL_IP:6443 K3S_TOKEN=$TOKEN sh -
  # EOF
  tags = { Name = "k3s-worker-${count.index + 1}" }
}
