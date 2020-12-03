// AVAILABILITY SET
resource "azurerm_availability_set" "hdb" {
  count = local.enable_deployment ? max(length(local.zones), 1) : 0
  name = local.zonal_deployment ? (
    format("%s%sz%s%s%s", local.prefix, var.naming.separator, local.zones[count.index], var.naming.separator, local.resource_suffixes.db_avset)) : (
    format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_avset)
  )
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.zonal_deployment ? var.ppg[count.index % length(local.zones)].id : var.ppg[0].id
  managed                      = true
}

data "azurerm_availability_set" "hdb" {
  count               = local.enable_deployment && local.availabilitysets_exist ? max(length(local.zones), 1) : 0
  name                = split("/", local.availabilityset_arm_ids[count.index])[8]
  resource_group_name = split("/", local.availabilityset_arm_ids[count.index])[4]
}
