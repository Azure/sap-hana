output "subnet-sap-admin" {
  value = try(local.sub_admin_exists ? data.azurerm_subnet.sap-admin[0] : azurerm_subnet.sap-admin[0], {})
}

output "nics-dbnodes-admin" {
  value = azurerm_network_interface.nics-dbnodes-admin
  #value = local.enable_deployment ? azurerm_network_interface.nics-dbnodes-admin : []
}

output "nics-dbnodes-db" {
  value = azurerm_network_interface.nics-dbnodes-db
  #value = local.enable_deployment ? azurerm_network_interface.nics-dbnodes-db : []
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

output "user_vault_name" {
  value = azurerm_key_vault.kv_user
}

output "secret_name_cockpit_admin"{
  value = azurerm_key_vault_secret.cockpit_admin
}

output "secret_name_xsa_admin"{
  value = azurerm_key_vault_secret.xsa_admin
}
output "secret_name_ha_cluster"{
  value = azurerm_key_vault_secret.ha_cluster
}
output "secret_name_db_systemdb"{
  value = azurerm_key_vault_secret.db_systemdb
}
output "secret_name_os_sidadm"{
  value = azurerm_key_vault_secret.os_sidadm
}
output "secret_name_os_sapadm"{
  value = azurerm_key_vault_secret.os_sapadm
}
