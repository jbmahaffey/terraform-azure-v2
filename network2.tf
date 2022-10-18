// Create Virtual Network

resource "azurerm_virtual_network" "branchfgtvnetwork" {
  name                = "branch-fgtvnetwork"
  address_space       = [var.branchvnetcidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.Branch.name

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_subnet" "branchpublicsubnet" {
  name                 = "branch-publicSubnet"
  resource_group_name  = azurerm_resource_group.Branch.name
  virtual_network_name = azurerm_virtual_network.branchfgtvnetwork.name
  address_prefixes     = [var.branchpubliccidr]
}

resource "azurerm_subnet" "branchprivatesubnet" {
  name                 = "branch-privateSubnet"
  resource_group_name  = azurerm_resource_group.Branch.name
  virtual_network_name = azurerm_virtual_network.branchfgtvnetwork.name
  address_prefixes     = [var.branchprivatecidr]
}

# Create Server subnet
resource "azurerm_subnet" "branchServers" {
  name                 = "Branch-Servers"
  resource_group_name  = azurerm_resource_group.Branch.name
  virtual_network_name = azurerm_virtual_network.branchfgtvnetwork.name
  address_prefixes     = ["172.16.2.0/24"]
}


// Allocated Public IP
resource "azurerm_public_ip" "branchFGTPublicIp" {
  name                = "Branch-FGTPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.Branch.name
  allocation_method   = "Static"

  tags = {
    environment = "Terraform SASE"
  }
}

//  Network Security Group
resource "azurerm_network_security_group" "branchpublicnetworknsg" {
  name                = "Branch-PublicNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.Branch.name

  security_rule {
    name                       = "TCP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_network_security_group" "branchprivatenetworknsg" {
  name                = "Branch-PrivateNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.Branch.name

  security_rule {
    name                       = "All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_network_security_rule" "branch_outgoing_public" {
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Branch.name
  network_security_group_name = azurerm_network_security_group.branchpublicnetworknsg.name
}

resource "azurerm_network_security_rule" "branch_outgoing_private" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Branch.name
  network_security_group_name = azurerm_network_security_group.branchprivatenetworknsg.name
}

// FGT Network Interface port1
resource "azurerm_network_interface" "branchfgtport1" {
  name                = "branch-fgtport1"
  location            = var.location
  resource_group_name = azurerm_resource_group.Branch.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.branchpublicsubnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.branchFGTPublicIp.id
  }

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_network_interface" "branchfgtport2" {
  name                 = "branch-fgtport2"
  location             = var.location
  resource_group_name  = azurerm_resource_group.Branch.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.branchprivatesubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Terraform SASE"
  }
}
# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "branchport1nsg" {
  depends_on                = [azurerm_network_interface.branchfgtport1]
  network_interface_id      = azurerm_network_interface.branchfgtport1.id
  network_security_group_id = azurerm_network_security_group.branchpublicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "branchport2nsg" {
  depends_on                = [azurerm_network_interface.branchfgtport2]
  network_interface_id      = azurerm_network_interface.branchfgtport2.id
  network_security_group_id = azurerm_network_security_group.branchprivatenetworknsg.id
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "branch_Server_SG" {
  name                = "Branch-NetworkSecurityGroup"
  location            = azurerm_resource_group.Branch.location
  resource_group_name = azurerm_resource_group.Branch.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "branchServerNIC1" {
  name                = "Branch-ServerNIC1"
  location            = azurerm_resource_group.Branch.location
  resource_group_name = azurerm_resource_group.Branch.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.branchServers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "branchAttach_SG" {
  network_interface_id      = azurerm_network_interface.branchServerNIC1.id
  network_security_group_id = azurerm_network_security_group.branch_Server_SG.id
}
