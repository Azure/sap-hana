output "nics_anydb" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db : []
}

output "nics_anydb_admin" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_admin : []
}

output "anydb_admin_ip" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_admin[*].private_ip_address : []
}

output "anydb_db_ip" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db[*].private_ip_address : []
}

output "anydb_lb_ip" {
  value = local.enable_deployment ? azurerm_lb.anydb[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "any_database_info" {
  value = try(local.enable_deployment ? local.anydb_database : map(false), {})
}

output "anydb_loadbalancers" {
  value = azurerm_lb.anydb
}
