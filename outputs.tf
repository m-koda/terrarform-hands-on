output "ec2-public-ip" {
  value = aws_instance.example.public_ip
}