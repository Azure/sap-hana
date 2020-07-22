output "subnet-sap-admin" {
  value = try(local.sub_admin_exists ? data.azurerm_subnet.subnet-sap-admin[0] : azurerm_subnet.subnet-sap-admin[0], {})
}

output "nics-dbnodes-admin" {
  value = azurerm_network_interface.nics-dbnodes-admin
}

output "nics-dbnodes-db" {
  value = azurerm_network_interface.nics-dbnodes-db
}

output "loadbalancers" {
  value = azurerm_lb.hdb
}

output "hdb-sid" {
  value = local.hana_database.instance.sid
}

output "hana-database-info" {
  value = try(local.enable_deployment ? local.hana_database : map(false), {})
}

# Workaround to create dependency betweeen ../main.tf ansible_execution and module hdb_node
output "dbnode-data-disk-att" {
  value = azurerm_virtual_machine_data_disk_attachment.vm-dbnode-data-disk
}
