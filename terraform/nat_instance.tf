resource "aws_instance" "nat_instance" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.security_group_public_from_nat.id]
  key_name                    = aws_key_pair.cluster.key_name

  user_data = <<-EOF
    #!/bin/bash
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    yum install -y iptables-services
    export IFACE=$(ip route get 8.8.8.8 | awk '{print $5}')
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    service iptables save
    systemctl enable iptables
  EOF

  tags = {
    Name = "nat-instance"
  }
}
