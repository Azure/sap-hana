output "nics-scs" {
  value = azurerm_network_interface.scs
}

output "nics-app" {
  value = azurerm_network_interface.app
}

output "nics-web" {
  value = azurerm_network_interface.web
}

output "user_vault_name" {
  value = azurerm_key_vault.kv_user
}
