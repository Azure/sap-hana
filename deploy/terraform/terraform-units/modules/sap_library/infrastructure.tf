/*
  Description:
  Set up infrastructure for sap library 
*/

resource "azurerm_resource_group" "library" {
  provider = azurerm.main
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
  tags     = var.infrastructure.tags

}

// Imports data of existing resource group
data "azurerm_resource_group" "library" {
  provider = azurerm.main
  count    = local.rg_exists ? 1 : 0
  name     = split("/", local.rg_arm_id)[4]
}

// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473


resource "azurerm_private_dns_zone" "dns" {
  depends_on = [
    azurerm_resource_group.library
  ]
  provider            = azurerm.main
  count               = length(var.dns_label) > 0 ? 1 : 0
  name                = var.dns_label
  resource_group_name = local.rg_exists ? split("/", local.rg_arm_id)[4] : azurerm_resource_group.library[0].name
}
