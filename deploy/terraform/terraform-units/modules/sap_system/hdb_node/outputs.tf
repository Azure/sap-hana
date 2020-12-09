output "hdb_vms" {
  value = azurerm_linux_virtual_machine.vm_dbnode
}

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

// Output for DNS
output "dns_info_vms" {
  value = local.enable_deployment ? (
    zipmap(
      concat(local.hdb_vms[*].name, slice(var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME, 0, local.db_server_count)),
      concat(azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address, azurerm_network_interface.nics_dbnodes_db[*].private_ip_address)
    )) : (
    null
  )
}

output "dns_info_loadbalancers" {
  value = local.enable_deployment ? (
    zipmap([format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb)], [azurerm_lb.hdb[0].private_ip_addresses[0]])) : (
    null
  )
}

output "hanadb_vm_ids" {
  value = local.enable_deployment ? azurerm_linux_virtual_machine.vm_dbnode[*].id : []
}
