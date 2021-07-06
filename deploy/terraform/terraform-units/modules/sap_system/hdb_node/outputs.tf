output "hdb_vms" {
  sensitive = false
  value     = azurerm_linux_virtual_machine.vm_dbnode[*].id
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
  sensitive = false
  value     = local.hdb_sid
}

output "hana_database_info" {
  sensitive = false
  value     = try(local.enable_deployment ? local.hana_database : map(false), {})
}

// Output for DNS
output "dns_info_vms" {
  value = local.enable_deployment ? (
    zipmap(
      concat(
        local.hdb_vms[*].name,
        slice(var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME, 0, local.db_server_count)
      ),
      concat(
        slice(azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address, 0, local.db_server_count),
        slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, local.db_server_count)
    ))) : (
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


output "dbtier_disks" {
  value = local.enable_deployment ? local.db_disks_ansible : []
}
<<<<<<< HEAD
=======

output "db_ha" {
  value = local.hdb_ha
}
>>>>>>> c645d159518e3e6d485293e8ff8e51c836593cb3
