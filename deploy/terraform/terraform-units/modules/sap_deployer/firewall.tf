
// Create/Import management subnet
resource "azurerm_subnet" "subnet_firewall" {
  count = var.deploy_firewall ? 1 : 0
  name                 = local.sub_fw_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.sub_fw_prefix]
}

data "azurerm_subnet" "subnet_firewall" {
  count = var.deploy_firewall ? 0 : 1
  name                 = split("/", local.sub_fw_arm_id)[10]
  resource_group_name  = split("/", local.sub_fw_arm_id)[4]
  virtual_network_name = split("/", local.sub_fw_arm_id)[8]
}