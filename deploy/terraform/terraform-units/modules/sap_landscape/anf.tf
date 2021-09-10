resource "azurerm_netapp_account" "workload_netapp_account" {
  provider = azurerm.main
  count    = var.ANF_settings.use && length(var.ANF_settings.arm_id) == 0 ? 1 : 0
  name     = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.netapp_account)

  resource_group_name = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
}


data "azurerm_netapp_account" "workload_netapp_account" {
  provider            = azurerm.main
  count               = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? 1 : 0
  name                = split("/", var.ANF_settings.arm_id)[8]
  resource_group_name = split("/", var.ANF_settings.arm_id)[4]
}

resource "azurerm_netapp_pool" "workload_netapp_pool" {
  provider = azurerm.main
  count    = var.ANF_settings.use ? 1 : 0
  name     = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.netapp_pool)
  account_name = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
    data.azurerm_netapp_account.workload_netapp_account[0].name) : (
    azurerm_netapp_account.workload_netapp_account[0].name
  )
  location = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
    data.azurerm_netapp_account.workload_netapp_account[0].location) : (
    azurerm_netapp_account.workload_netapp_account[0].location
  )
  resource_group_name = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
    data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
    azurerm_netapp_account.workload_netapp_account[0].resource_group_name
  )

  service_level = var.ANF_settings.service_level
  size_in_tb    = var.ANF_settings.size_in_tb
}
