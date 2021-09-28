output "hdb_vms" {
  sensitive = false
  value     = azurerm_linux_virtual_machine.vm_dbnode[*].id
}

output "nics_dbnodes_admin" {
  value = local.enable_deployment && var.hana_dual_nics ? azurerm_network_interface.nics_dbnodes_admin : []
}

output "nics_dbnodes_db" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db : []
}

output "loadbalancers" {
  value = local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || local.hdb_ha) ? azurerm_lb.hdb : null
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
        (
          var.hana_dual_nics ? local.hdb_vms[*].name : [""]
        ),
        (
          slice(var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME, 0, local.db_server_count)
        )
      ),
      concat(
        (
          var.hana_dual_nics ? slice(azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address, 0, local.db_server_count) : [""]
        ),
        (
          slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, local.db_server_count)
        )
    ))) : (
    null
  )
}

output "dns_info_loadbalancers" {
  value = local.enable_db_lb_deployment ? (
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

output "db_ha" {
  value = local.hdb_ha
}

output "db_lb_ip" {
  value = local.enable_db_lb_deployment ? azurerm_lb.hdb[0].frontend_ip_configuration[0].private_ip_address : ""
}

output "db_admin_ip" {
  value = local.enable_deployment && var.hana_dual_nics ? azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address : []
}

output "db_ip" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db[*].private_ip_address : []
}
