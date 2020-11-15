output "nics_scs" {
  value = azurerm_network_interface.scs
}

output "nics_app" {
  value = azurerm_network_interface.app
}

output "nics_web" {
  value = azurerm_network_interface.web
}

output "nics_scs_admin" {
  value = azurerm_network_interface.scs_admin
}

output "nics_app_admin" {
  value = azurerm_network_interface.app_admin
}

output "nics_web_admin" {
  value = azurerm_network_interface.web_admin
}

output "app_ip" {
  value = azurerm_network_interface.app[*].private_ip_address
}

output "app_admin_ip" {
  value = azurerm_network_interface.app_admin[*].private_ip_address
}

output "scs_ip" {
  value = azurerm_network_interface.scs[*].private_ip_address
}

output "scs_admin_ip" {
  value = azurerm_network_interface.scs_admin[*].private_ip_address
}

output "web_ip" {
  value = azurerm_network_interface.web[*].private_ip_address
}

output "web_admin_ip" {
  value = azurerm_network_interface.web_admin[*].private_ip_address
}

output "web_lb_ip" {
  value = local.enable_deployment && local.webdispatcher_count > 0 ? azurerm_lb.web[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "scs_lb_ip" {
  value = local.enable_deployment ? azurerm_lb.scs[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "ers_lb_ip" {
  value = local.enable_deployment ? azurerm_lb.scs[0].frontend_ip_configuration[1].private_ip_address : ""
}

output "application" {
  value = local.application
}
