output "anydb_vms" {
  value = (upper(local.anydb_ostype) == "LINUX") ? [
    azurerm_linux_virtual_machine.dbserver, azurerm_linux_virtual_machine.observer] : [
    azurerm_windows_virtual_machine.dbserver, azurerm_windows_virtual_machine.observer
  ]
}

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

// Output for DNS
output "dns_info_vms" {
  value = local.enable_deployment ? local.anydb_dual_nics ? (
    zipmap(
      compact(concat(
        local.anydb_vms[*].name,
        slice(var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME,0, local.db_server_count)
      )),
      compact(concat(
        azurerm_network_interface.anydb_admin[*].private_ip_address,
        azurerm_network_interface.anydb_db[*].private_ip_address
      ))
    )
    ) : (
    zipmap(local.anydb_vms[*].name, azurerm_network_interface.anydb_db[*].private_ip_address)
  ) : null

}


output "dns_info_loadbalancers" {
  value = local.enable_deployment ? (
    zipmap([format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb)], [azurerm_lb.anydb[0].private_ip_addresses[0]])) : (
    null
  )
}
