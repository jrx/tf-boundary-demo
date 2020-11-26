output "boundary_public_ip" {
  value = aws_instance.boundary.*.public_ip
}

output "test_private_ip" {
  value = aws_instance.test.*.private_ip
}

output "win_private_ip" {
  value = aws_instance.win.*.private_ip
}