output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "public_vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "public_vm_ssh" {
  value = "ssh -i tf_generated_key.pem ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}

output "private_vm_private_ip" {
  value = azurerm_network_interface.private_nic.ip_configuration[0].private_ip_address
}

output "generated_private_key_pem" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
  description = "Private key (PEM). Store securely; prefer moving to Jenkins credentials or vault."
}
