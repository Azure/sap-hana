resource "azurerm_netapp_volume" "transport" {

  count = local.ANF_pool_settings.use_ANF ? 1 : 0
  name  = format("%s%s%s", local.prefix, var.naming.separator,local.resource_suffixes.transport_volume)

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s", local.sid, local.resource_suffixes.transport_volume)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.anf_transport_volume_size

}

resource "azurerm_netapp_volume" "sapmnt" {

  count = local.ANF_pool_settings.use_ANF ? 1 : 0
  name  = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.sapmnt)

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s", local.sid, local.resource_suffixes.sapmnt)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.anf_sapmnt_volume_size

}
