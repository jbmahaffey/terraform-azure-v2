resource "azurerm_route_table" "branchinternal" {
  depends_on          = [azurerm_virtual_machine.branchfgtvm]
  name                = "Branch-InternalRouteTable1"
  location            = azurerm_resource_group.Branch.location
  resource_group_name = azurerm_resource_group.Branch.name
}

resource "azurerm_route" "branchdefault" {
  name                   = "branch-default"
  resource_group_name    = azurerm_resource_group.Branch.name
  route_table_name       = azurerm_route_table.branchinternal.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.branchfgtport2.private_ip_address
}

resource "azurerm_subnet_route_table_association" "branchinternalassociate" {
  depends_on     = [azurerm_route_table.branchinternal]
  subnet_id      = azurerm_subnet.branchprivatesubnet.id
  route_table_id = azurerm_route_table.branchinternal.id
}

resource "azurerm_subnet_route_table_association" "branchServerSubnetAssociation" {
  depends_on     = [azurerm_route_table.branchinternal]
  subnet_id      = azurerm_subnet.branchServers.id
  route_table_id = azurerm_route_table.branchinternal.id
}