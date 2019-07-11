output "resource_group" {
  value = azurerm_resource_group.rg
}
   
output "mgmt_subnet" {
  value = azurerm_subnet.mgmt-subnet
}

output "hana_client_subnet" {
  value = azurerm_subnet.hana-client-subnet
}

output "hana_admin_subnet" {
  value = azurerm_subnet.hana-admin-subnet
}

output "bootdiag_sa" {
  value = azurerm_storage_account.bootdiag-storageaccount
}
