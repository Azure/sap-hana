
// Create/Import management subnet
resource "azurerm_subnet" "firewall" {
  count                = var.firewall_deployment && !local.sub_fw_snet_exists ? 1 : 0
  name                 = local.sub_fw_snet_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.sub_fw_snet_prefix]
}

data "azurerm_subnet" "firewall" {
  count                = var.firewall_deployment && local.sub_fw_snet_exists ? 1 : 0
  name                 = split("/", local.sub_fw_snet_arm_id)[10]
  resource_group_name  = split("/", local.sub_fw_snet_arm_id)[4]
  virtual_network_name = split("/", local.sub_fw_snet_arm_id)[8]
}

resource "azurerm_public_ip" "firewall" {
  count               = var.firewall_deployment ? 1 : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, "firewall", local.resource_suffixes.pip)
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  count               = var.firewall_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, "firewall")
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = local.sub_fw_snet_exists ? data.azurerm_subnet.firewall[0].id : azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

