output "nics-scs" {
  value = azurerm_network_interface.scs
}

output "nics-app" {
  value = azurerm_network_interface.app
}

output "nics-web" {
  value = azurerm_network_interface.web
}

output "application" {
  value = local.application
}
