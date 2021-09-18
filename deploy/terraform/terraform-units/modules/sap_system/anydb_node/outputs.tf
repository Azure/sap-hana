output "anydb_vms" {
  value = (upper(local.anydb_ostype) == "LINUX") ? [
    azurerm_linux_virtual_machine.dbserver[*].id, azurerm_linux_virtual_machine.observer[*].id] : [
    azurerm_windows_virtual_machine.dbserver[*].id, azurerm_windows_virtual_machine.observer[*].id
  ]
}

output "nics_anydb" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db : []
}

output "nics_anydb_admin" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_admin : []
}

output "anydb_admin_ip" {
  value = local.enable_deployment ? (local.anydb_dual_nics ? azurerm_network_interface.anydb_admin[*].private_ip_address : azurerm_network_interface.anydb_db[*].private_ip_address) : []
}

output "anydb_db_ip" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db[*].private_ip_address : []
}

output "db_lb_ip" {
  value = local.enable_db_lb_deployment  && (var.use_loadbalancers_for_standalone_deployments || local.anydb_ha) ? try(azurerm_lb.anydb[0].frontend_ip_configuration[0].private_ip_address, "") : ""
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
        slice(var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME, 0, local.db_server_count)
      )),
      compact(concat(
        slice(azurerm_network_interface.anydb_admin[*].private_ip_address, 0, local.db_server_count),
        slice(azurerm_network_interface.anydb_db[*].private_ip_address, 0, local.db_server_count)
      ))
    )
    ) : (
    zipmap(local.anydb_vms[*].name, azurerm_network_interface.anydb_db[*].private_ip_address)
  ) : null

}

output "dns_info_loadbalancers" {
  value = local.enable_db_lb_deployment  ? (
    zipmap([format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb)], [azurerm_lb.anydb[0].private_ip_addresses[0]])) : (
    null
  )
}

output "anydb_vm_ids" {
  value = local.enable_deployment ? concat(azurerm_windows_virtual_machine.dbserver[*].id, azurerm_linux_virtual_machine.dbserver[*].id) : []
}

output "dbtier_disks" {
  value = local.enable_deployment ? local.db_disks_ansible : []
}


output "db_ha" {
  value = local.anydb_ha
}
