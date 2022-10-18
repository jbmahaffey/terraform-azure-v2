resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.Hub.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.Hub.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = {
    environment = "Terraform SASE"
  }
}

resource "random_id" "branchrandomId" {
  keepers = {
    resource_group = azurerm_resource_group.Branch.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "branchfgtstorageaccount" {
  name                     = "diag${random_id.branchrandomId.hex}"
  resource_group_name      = azurerm_resource_group.Branch.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = {
    environment = "Terraform SASE"
  }
}