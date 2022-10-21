# If this is the first Fortinet Fortigate deployed, uncomment the lines below

# resource "azurerm_marketplace_agreement" "fortinet" {
#   publisher = var.publisher
#   plan = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
#   offer = var.fgtoffer
# }

resource "azurerm_virtual_machine" "branchfgtvm" {
  count                        = var.custom ? 0 : 1
  name                         = "branch-fgtvm"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.Branch.name
  network_interface_ids        = [azurerm_network_interface.branchfgtport1.id, azurerm_network_interface.branchfgtport2.id]
  primary_network_interface_id = azurerm_network_interface.branchfgtport1.id
  vm_size                      = var.size
  storage_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    version   = var.fgtversion
  }

  plan {
    name      = var.license_type == "byol" ? var.fgtsku["byol"] : var.fgtsku["payg"]
    publisher = var.publisher
    product   = var.fgtoffer
  }

  storage_os_disk {
    name              = "branchosDisk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  # Log data disks
  storage_data_disk {
    name              = "branchfgtvmdatadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "30"
  }

  os_profile {
    computer_name  = "branchfgtvm"
    admin_username = var.adminusername
    admin_password = var.adminpassword
    custom_data    = templatefile("${path.module}/fgt2.conf", {type = var.license_type, license_file = var.license2, 
            privateip = azurerm_network_interface.branchfgtport1.private_ip_address, server1ip = azurerm_network_interface.branchServerNIC1.private_ip_address})
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.fgtstorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform SASE"
  }
}
