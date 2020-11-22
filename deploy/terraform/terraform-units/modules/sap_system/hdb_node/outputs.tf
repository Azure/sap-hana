
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
  value = concat(
    flatten([for idx, vm in local.virtualmachine_names :
      {
        format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm) = azurerm_network_interface.nics_dbnodes_admin[idx].private_ip_address
      }
    ]), 
    flatten([for idx, vm in var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME :
      {
        var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME[idx] = azurerm_network_interface.nics_dbnodes_db[idx].private_ip_address
      }
    ])
  )
}

output "dns_info_loadbalancers" {
  value = [
    { format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb) = azurerm_lb.hdb[0].private_ip_addresses[0] }
  ]
}


