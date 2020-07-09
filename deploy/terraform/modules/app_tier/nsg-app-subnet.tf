# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (local.sub_app_nsg_exists ? 0 : 1) : 0
  name                = local.sub_app_nsg_name
  location            = var.resource-group[0].location
  resource_group_name = var.resource-group[0].name
}

# Imports the SAP app subnet nsg data
data "azurerm_network_security_group" "nsg-app" {
  count               = local.enable_deployment ? (local.sub_app_nsg_exists ? 1 : 0) : 0
  name                = split("/", local.sub_app_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_app_nsg_arm_id)[4]
}

# Associates SAP app nsg to SAP app subnet
resource "azurerm_subnet_network_security_group_association" "Associate-nsg-app" {
  count                     = local.enable_deployment ? (signum((local.sub_app_exists ? 0 : 1) + (local.sub_app_nsg_exists ? 0 : 1))) : 0
  subnet_id                 = local.sub_app_exists ? data.azurerm_subnet.subnet-sap-app[0].id : azurerm_subnet.subnet-sap-app[0].id
  network_security_group_id = local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg-app[0].id : azurerm_network_security_group.nsg-app[0].id
}
