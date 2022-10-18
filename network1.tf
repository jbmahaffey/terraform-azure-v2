// Create Virtual Network

resource "azurerm_virtual_network" "fgtvnetwork" {
  name                = "hub-fgtvnetwork"
  address_space       = [var.vnetcidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.Hub.name

  tags = {
    environment = "Terraform SASE"
  }
}

resource "azurerm_subnet" "publicsubnet" {
  name                 = "hub-publicSubnet"
  resource_group_name  = azurerm_resource_group.Hub.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = [var.publiccidr]
}

resource "azurerm_subnet" "privatesubnet" {
  name                 = "hub-privateSubnet"
  resource_group_name  = azurerm_resource_group.Hub.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = [var.privatecidr]
}

# Create Server subnet
resource "azurerm_subnet" "Servers" {
  name                 = "Hub-Servers"
  resource_group_name  = azurerm_resource_group.Hub.name
  virtual_network_name = azurerm_virtual_network.fgtvnetwork.name
  address_prefixes     = ["10.1.2.0/24"]
}


// Allocated Public IP
resource "azurerm_public_ip" "FGTPublicIp" {
  name                = "Hub-FGTPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.Hub.name
  allocation_method   = "Static"

  tags = {
    environment = "Terraform SASE"
  }
}

//  Network Security Group
resource "azurerm_network_security_group" "publicnetworknsg" {
  name                = "Hub-PublicNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.Hub.name

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

resource "azurerm_network_security_group" "privatenetworknsg" {
  name                = "Hub-PrivateNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.Hub.name

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

resource "azurerm_network_security_rule" "outgoing_public" {
  name                        = "egress"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Hub.name
  network_security_group_name = azurerm_network_security_group.publicnetworknsg.name
}

resource "azurerm_network_security_rule" "outgoing_private" {
  name                        = "egress-private"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Hub.name
  network_security_group_name = azurerm_network_security_group.privatenetworknsg.name
}

// FGT Network Interface port1
resource "azurerm_network_interface" "fgtport1" {
  name                = "hub-fgtport1"
  location            = var.location
  resource_group_name = azurerm_resource_group.Hub.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.publicsubnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.FGTPublicIp.id
  }

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_network_interface" "fgtport2" {
  name                 = "hub-fgtport2"
  location             = var.location
  resource_group_name  = azurerm_resource_group.Hub.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.privatesubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "Terraform Demo"
  }
}
# Connect the security group to the network interfaces
resource "azurerm_network_interface_security_group_association" "port1nsg" {
  depends_on                = [azurerm_network_interface.fgtport1]
  network_interface_id      = azurerm_network_interface.fgtport1.id
  network_security_group_id = azurerm_network_security_group.publicnetworknsg.id
}

resource "azurerm_network_interface_security_group_association" "port2nsg" {
  depends_on                = [azurerm_network_interface.fgtport2]
  network_interface_id      = azurerm_network_interface.fgtport2.id
  network_security_group_id = azurerm_network_security_group.privatenetworknsg.id
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Server_SG" {
  name                = "Hub-NetworkSecurityGroup"
  location            = azurerm_resource_group.Hub.location
  resource_group_name = azurerm_resource_group.Hub.name

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
resource "azurerm_network_interface" "ServerNIC1" {
  name                = "Hub-ServerNIC1"
  location            = azurerm_resource_group.Hub.location
  resource_group_name = azurerm_resource_group.Hub.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.Servers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Attach_SG" {
  network_interface_id      = azurerm_network_interface.ServerNIC1.id
  network_security_group_id = azurerm_network_security_group.Server_SG.id
}

# Create network interface
resource "azurerm_network_interface" "Server2NIC1" {
  name                = "Hub-Server2NIC1"
  location            = azurerm_resource_group.Hub.location
  resource_group_name = azurerm_resource_group.Hub.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.Servers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Attach_SG_Server2" {
  network_interface_id      = azurerm_network_interface.Server2NIC1.id
  network_security_group_id = azurerm_network_security_group.Server_SG.id
}