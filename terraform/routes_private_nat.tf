resource "aws_route_table" "routes_private_nat" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }

  depends_on = [aws_instance.nat_instance]

  tags = {
    Name = "routes_private_nat"
  }
}
