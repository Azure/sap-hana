
output "nics_dbnodes_admin" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_admin : []
}

output "nics_dbnodes_db" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db : []
}

output "loadbalancers" {
  value = azurerm_lb.hdb
}

output "hdb_sid" {
  value = local.hana_database.instance.sid
}

output "hana_database_info" {
  value = try(local.enable_deployment ? local.hana_database : map(false), {})
}

