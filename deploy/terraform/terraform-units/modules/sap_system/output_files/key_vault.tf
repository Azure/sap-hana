data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = var.cockpit_admin
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "xsa_admin" {
  name         = var.xsa_admin
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "db_systemdb" {
  name         = var.db_systemdb
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "os_sidadm" {
  name         = var.os_sidadm
  key_vault_id = var.hdb_kv_id
}

data "azurerm_key_vault_secret" "os_sapadm" {
  name         = var.os_sapadm
  key_vault_id = var.hdb_kv_id
}

data "azurerm_key_vault_secret" "ha_cluster" {
  name         = var.ha_cluster
  key_vault_id = var.hdb_kv_id
}
