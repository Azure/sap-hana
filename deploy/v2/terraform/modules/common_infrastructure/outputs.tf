output "resource-group" {
  value = var.infrastructure.resource_group.is_existing ? data.azurerm_resource_group.resource-group : azurerm_resource_group.resource-group
}

output "subnet-mgmt" {
  value = var.infrastructure.vnets.management.subnet_mgmt.is_existing ? data.azurerm_subnet.subnet-mgmt : azurerm_subnet.subnet-mgmt
}

output "nsg-mgmt" {
  value = var.infrastructure.vnets.management.subnet_mgmt.nsg.is_existing ? data.azurerm_network_security_group.nsg-mgmt : azurerm_network_security_group.nsg-mgmt
}
