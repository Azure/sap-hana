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
  value = concat(
    flatten([for idx, vm in local.virtualmachine_names :
      {
        // If dual nics are used the admin NIC is first
        format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm) = local.anydb_dual_nics ? (
          azurerm_network_interface.anydb_admin[idx].private_ip_address) : (
          azurerm_network_interface.anydb_db[idx].private_ip_address
        )
      }
    ]), ! local.anydb_dual_nics ? null :
    flatten([for idx, vm in var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME :
      {
        var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME[idx] = azurerm_network_interface.anydb_db[idx].private_ip_address
      }
    ])
  )
}

output "dns_info_loadbalancers" {
  value = [
    { format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb) = azurerm_lb.anydb[0].private_ip_addresses[0] }
  ]
}
