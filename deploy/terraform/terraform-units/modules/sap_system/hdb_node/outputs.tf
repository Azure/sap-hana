
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

# Workaround to create dependency betweeen ../main.tf ansible_execution and module hdb_node
output "dbnode_data_disk_att" {
  value = azurerm_virtual_machine_data_disk_attachment.vm_dbnode_data_disk
}
