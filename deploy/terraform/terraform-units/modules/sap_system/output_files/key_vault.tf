data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = var.cockpit_admin
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "xsa_admin " {
  name         = local.xsa_admin
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = local.secret_sid_pk_name
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = local.secret_sid_pk_name
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = local.secret_sid_pk_name
  key_vault_id = var.hdb_kv_id
}
data "azurerm_key_vault_secret" "cockpit_admin" {
  name         = local.secret_sid_pk_name
  key_vault_id = var.hdb_kv_id
}