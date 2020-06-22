output "loadbalancers" {
  value = azurerm_lb.anydb-lb
}

output "nics-anydb" {
  value = azurerm_network_interface.anydbnic
}