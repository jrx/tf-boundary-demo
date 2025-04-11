output "boundary_public_ip" {
  value = aws_instance.boundary.*.public_ip
}

output "linux_private_ip" {
  value = aws_instance.linux.*.private_ip
}

output "win_private_ip" {
  value = aws_instance.win.*.private_ip
}