output "tls_private_key" {
  value = tls_private_key.ssh_key_cicd.private_key_pem 
}

output "tls_public_key" {
  value = tls_private_key.ssh_key_cicd.public_key_pem
}

output "public_ip_address" {
  value = aws_instance.cicd_server.public_ip
}

output "security_group_id" {
  value = aws_security_group.sg_cicd.id
}

output "subnet_id" {
  value = aws_subnet.subnet_cicd.id
}

output "ec2_instance_availability_zone" {
  value = aws_instance.cicd_server.availability_zone
}

output "subnet_availability_zone" {
  value = aws_subnet.subnet_cicd.availability_zone
}

output "eip_address" {
  value = aws_eip.cicd_server_public_ip.public_ip
}

output "server_dns_public_address" {
  value = aws_instance.cicd_server.public_dns
}