# AVAILABILITY SET ================================================================================================

resource "azurerm_availability_set" "hdb" {
  count                        = local.enable_deployment ? max(length(local.zones), 1) : 0
  name                         = local.zonal_deployment ? format("%s%sz%s%s", local.prefix, var.naming.separator, local.zones[count.index], local.resource_suffixes.db_avset) : format("%s%s", local.prefix, local.resource_suffixes.db_avset)
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = 2
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % length(local.zones)].id : var.ppg[0].id
  managed                      = true
}
