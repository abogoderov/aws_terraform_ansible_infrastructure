
#------------------------------------------------------------------

output "BalancerDNS" {
  value = aws_elb.ws_balancer.dns_name
}
output "public_ip_bastion" {
  value = aws_instance.bastion_host.public_ip
}
output "WebServers_private_IPs" {
  value = aws_instance.ws_private_instance.*.private_ip
}
output "WebServers_public_IPs" {
  value = aws_instance.ws_private_instance.*.public_ip
}

