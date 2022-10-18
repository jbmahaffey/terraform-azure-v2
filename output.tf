output "ResourceGroup" {
  value = azurerm_resource_group.Hub.name
}

output "BranchResourceGroup" {
  value = azurerm_resource_group.Branch.name
}

output "Hub-FGTPublicIP" {
  value = azurerm_public_ip.FGTPublicIp.ip_address
}

output "Branch-FGTPublicIP" {
  value = azurerm_public_ip.branchFGTPublicIp.ip_address
}

output "UbuntuSSH" {
    value = tls_private_key.azure_key.id
}

output "Username" {
  value = var.adminusername
}

output "Password" {
  value = var.adminpassword
}

output "tls_private_key" {
  value     = tls_private_key.azure_key.private_key_pem
  sensitive = true
}