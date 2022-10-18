// Resource Group

resource "azurerm_resource_group" "Hub" {
  name     = "CSE-NA-SASE-Hub"
  location = var.location

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_resource_group" "Branch" {
  name     = "CSE-NA-SASE-Branch"
  location = var.location

  tags = {
    environment = "Terraform SASE"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "azure_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}