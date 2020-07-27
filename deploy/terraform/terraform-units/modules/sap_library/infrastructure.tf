/*
  Description:
  Set up infrastructure for sap library 
*/

resource "azurerm_resource_group" "library" {
  count    = local.rg_exists ? 0 : 1
  name     = local.rg_name
  location = local.region
}

// Imports data of existing resource group
data "azurerm_resource_group" "library" {
  count = local.rg_exists ? 1 : 0
  name  = split("/", local.rg_arm_id)[4]
}

resource "azurerm_management_lock" "library" {
  count      = local.rg_exists ? 0 : 1
  name       = "resource-group-level"
  scope      = azurerm_resource_group.library[0].id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by Azure Automated Deployment"
}
