output "boundary_public_ip" {
  value = aws_instance.boundary.*.public_ip
}

output "test_private_ip" {
  value = aws_instance.test.*.private_ip
}