resource "tls_private_key" "cluster" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cluster" {
  key_name   = "cluster-key"
  public_key = tls_private_key.cluster.public_key_openssh
}

output "cluster_private_key_pem" {
  value     = tls_private_key.cluster.private_key_pem
  sensitive = true
}
