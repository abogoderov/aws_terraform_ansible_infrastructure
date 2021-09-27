# ----------------------------------------------------------------
# This code block provides instance info for Ansible inventory file
# 
resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      private-dns = aws_instance.ws_private_instance.*.private_dns,
      private-ip  = aws_instance.ws_private_instance.*.private_ip,
      private-id  = aws_instance.ws_private_instance.*.id
    }
  )
  filename = "inventory"
}

#------------------------------------------------------------------


