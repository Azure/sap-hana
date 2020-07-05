output "loadbalancers" {
  value = azurerm_lb.lb
}

output "nics-anydb" {
  value = azurerm_network_interface.nic
}

output "any-database-info" {
  value = try(local.enable_deployment ? local.anydb_database : map(false), {})
}
