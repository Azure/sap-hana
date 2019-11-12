output "nics-dbnodes-admin" {
  value = azurerm_network_interface.nics-dbnodes-admin
}

output "nics-dbnodes-db" {
  value = azurerm_network_interface.nics-dbnodes-db
}

# Workaround to create dependency betweeen ../main.tf ansible_execution and module hdb_node
output "dbnodes" {
  value = azurerm_virtual_machine.vm-dbnode
}
