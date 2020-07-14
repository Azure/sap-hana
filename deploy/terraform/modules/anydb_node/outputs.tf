
output "nics-anydb" {
  value = azurerm_network_interface.anydb
}

output "any-database-info" {
  value = try(local.enable_deployment ? local.anydb_database : map(false), {})
}
