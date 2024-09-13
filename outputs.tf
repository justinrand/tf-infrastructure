
output "zk_public_ips" {
  description = "Public IP addresses for the zk instances"
  value       = aws_instance.zk.*.public_ip
}
