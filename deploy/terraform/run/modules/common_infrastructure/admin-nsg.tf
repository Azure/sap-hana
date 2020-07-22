/*-----------------------------------------------------------------------------8
|                                                                              |
|                                Admin - NSG                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/

# NSGs ===========================================================================================================

# Creates mgmt subnet nsg
resource "azurerm_network_security_group" "nsg-mgmt" {
  count               = local.sub_mgmt_nsg_exists ? 0 : 1
  name                = local.sub_mgmt_nsg_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource-group[0].location : azurerm_resource_group.resource-group[0].location
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource-group[0].name : azurerm_resource_group.resource-group[0].name
}

# Imports the mgmt subnet nsg data
data "azurerm_network_security_group" "nsg-mgmt" {
  count               = local.sub_mgmt_nsg_exists ? 1 : 0
  name                = split("/", local.sub_mgmt_nsg_arm_id)[8]
  resource_group_name = split("/", local.sub_mgmt_nsg_arm_id)[4]
}
