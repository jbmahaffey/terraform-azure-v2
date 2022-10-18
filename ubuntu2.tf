# Create virtual machine
resource "azurerm_linux_virtual_machine" "Branch-Ubuntu-Server" {
  name                  = "Branch-Test-VM1"
  location              = azurerm_resource_group.Branch.location
  resource_group_name   = azurerm_resource_group.Branch.name
  network_interface_ids = [azurerm_network_interface.branchServerNIC1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "UbuntuOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "Branch-Test-VM1"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  custom_data = base64encode(templatefile("${path.module}/ubuntu.sh", {ip = azurerm_network_interface.branchServerNIC1.private_ip_address}))

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.azure_key.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform SASE"
  }
}
