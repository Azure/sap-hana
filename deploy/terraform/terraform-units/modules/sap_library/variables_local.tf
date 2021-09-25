/*
Description:

  Define local variables.
*/

// Input arguments 
variable "naming" {
  description = "naming convention"
}

variable "deployer_tfstate" {
  description = "terraform.tfstate of deployer"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable "use_private_endpoint" {
  default = false
}

locals {

  storageaccount_names = var.naming.storageaccount_names.LIBRARY
  keyvault_names       = var.naming.keyvault_names.LIBRARY
  resource_suffixes    = var.naming.resource_suffixes

  // Infrastructure
  var_infra = try(var.infrastructure, {})

  // Region
  region = try(local.var_infra.region, "")
  prefix = length(local.var_infra.resource_group.name) > 0 ? local.var_infra.resource_group.name : trimspace(var.naming.prefix.LIBRARY)

  // Resource group
  rg_arm_id = try(var.infrastructure.resource_group.arm_id, "")
  rg_exists = length(local.rg_arm_id) > 0

  rg_name = local.rg_exists ? (
    try(split("/", local.rg_arm_id)[4], "")) : (
    length(local.var_infra.resource_group.name) > 0 ? (
      local.var_infra.resource_group.name) : (
      format("%s%s", local.prefix, local.resource_suffixes.library_rg)
    )
  )

  // Storage account for sapbits
  sa_sapbits_arm_id = try(var.storage_account_sapbits.arm_id, "")
  sa_sapbits_exists = length(local.sa_sapbits_arm_id) > 0 ? true : false
  sa_sapbits_name   = local.sa_sapbits_exists ? split("/", local.sa_sapbits_arm_id)[8] : local.storageaccount_names.library_storageaccount_name

  sa_sapbits_account_tier             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_tier, "Standard")
  sa_sapbits_account_replication_type = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_replication_type, "LRS")
  sa_sapbits_account_kind             = local.sa_sapbits_exists ? "" : try(var.storage_account_sapbits.account_kind, "StorageV2")
  sa_sapbits_enable_secure_transfer   = true

  // File share for sapbits
  sa_sapbits_file_share_enable = try(var.storage_account_sapbits.file_share.enable_deployment, true)
  sa_sapbits_file_share_exists = try(var.storage_account_sapbits.file_share.is_existing, false)
  sa_sapbits_file_share_name   = try(var.storage_account_sapbits.file_share.name, local.resource_suffixes.sapbits)

  // Blob container for sapbits
  sa_sapbits_blob_container_enable = try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, true)
  sa_sapbits_blob_container_exists = try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false)
  sa_sapbits_blob_container_name   = try(var.storage_account_sapbits.sapbits_blob_container.name, local.resource_suffixes.sapbits)
  sa_sapbits_container_access_type = "private"

  // Storage account for tfstate
  sa_tfstate_arm_id                   = try(var.storage_account_tfstate.arm_id, "")
  sa_tfstate_exists                   = length(local.sa_tfstate_arm_id) > 0 ? true : false
  sa_tfstate_account_tier             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_tier, "Standard")
  sa_tfstate_account_replication_type = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_replication_type, "LRS")
  sa_tfstate_account_kind             = local.sa_tfstate_exists ? "" : try(var.storage_account_tfstate.account_kind, "StorageV2")
  sa_tfstate_container_access_type    = "private"
  sa_tfstate_name                     = local.sa_tfstate_exists ? split("/", local.sa_tfstate_arm_id)[8] : local.storageaccount_names.terraformstate_storageaccount_name
  sa_tfstate_enable_secure_transfer   = true
  sa_tfstate_delete_retention_policy  = 7

  sa_tfstate_container_exists = try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
  sa_tfstate_container_name   = try(var.storage_account_tfstate.tfstate_blob_container.name, local.resource_suffixes.tfstate)

  //Ansible
  sa_ansible_container_exists = try(var.storage_account_tfstate.ansible_blob_container.is_existing, false)
  sa_ansible_container_name   = try(var.storage_account_tfstate.ansible_blob_container.name, local.resource_suffixes.ansible)

  // deployer
  deployer      = try(var.deployer, {})
  deployer_vnet = try(local.deployer.vnet, "")

  // Comment out code with users.object_id for the time being.
  // deployer_users_id = try(local.deployer.users.object_id, [])

  // Current service principal
  service_principal = try(var.service_principal, {})

  // deployer terraform.tfstate
  deployer_tfstate          = var.deployer_tfstate
  deployer_defined          = length(var.deployer_tfstate) > 0
  deployer_msi_principal_id = local.deployer_defined ? try(local.deployer_tfstate.deployer_uai.principal_id, local.deployer_tfstate.deployer_uai) : ""

  subnet_mgmt_id = local.deployer_defined ? local.deployer_tfstate.subnet_mgmt_id : ""

  deployer_public_ip_address = local.deployer_defined ? local.deployer_tfstate.deployer_public_ip_address : ""

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults
  user_key_vault_id = try(var.key_vault.kv_user_id, "")
  prvt_key_vault_id = try(var.key_vault.kv_prvt_id, "")
  user_kv_exist     = length(local.user_key_vault_id) > 0
  prvt_kv_exist     = length(local.prvt_key_vault_id) > 0

  // Extract information from the specified key vault arm ids
  user_kv_name    = local.user_kv_exist ? split("/", local.user_key_vault_id)[8] : local.keyvault_names.user_access
  user_kv_rg_name = local.user_kv_exist ? split("/", local.user_key_vault_id)[4] : ""

  prvt_kv_name    = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[8] : local.keyvault_names.private_access
  prvt_kv_rg_name = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[4] : ""

  rg_library_location           = local.rg_exists ? data.azurerm_resource_group.library[0].location : azurerm_resource_group.library[0].location
  storagecontainer_sapbits_name = local.sa_sapbits_blob_container_enable ? local.sa_sapbits_blob_container_name : null
  fileshare_sapbits_name        = local.sa_sapbits_file_share_enable ? local.sa_sapbits_file_share_name : null


  deployer_kv_user_arm_id = local.deployer_defined ? try(local.deployer_tfstate.deployer_kv_user_arm_id, "") : ""

}
