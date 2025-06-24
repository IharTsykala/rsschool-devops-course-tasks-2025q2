resource "aws_instance" "nat_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type

  network_interface {
    network_interface_id = aws_network_interface.nat_eni.id
    device_index         = 0
  }

  # user_data = <<-EOF
  #   #!/bin/bash
  #   echo 1 > /proc/sys/net/ipv4/ip_forward
  #   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  # EOF

  user_data = <<-EOF
    #!/bin/bash
    echo "Enabling IP forwarding"
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p

    echo "Setting up iptables"
    yum install -y iptables-services
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    service iptables save
    systemctl enable iptables
  EOF

  tags = {
    Name = "nat-instance"
  }
}
