
locals {
  resource_group = {
    name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
    arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
  }
  resource_group_defined = (length(local.resource_group.name) + length(local.resource_group.arm_id)) > 0

  temp_infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = coalesce(var.location, try(var.infrastructure.region, ""))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))

  }
  deployer = {
    environment = coalesce(var.deployer_environment, try(var.deployer.environment, ""))
    region      = coalesce(var.deployer_location, try(var.deployer.region, ""))
    vnet        = coalesce(var.deployer_vnet, try(var.deployer.vnet, ""))
    use         = coalesce(var.deployer_use, try(var.deployer.use, true))

  }
  storage_account_sapbits = {
    arm_id                   = try(coalesce(var.library_sapmedia_arm_id, try(var.storage_account_sapbits.arm_id, "")), "")
    account_tier             = coalesce(var.library_sapmedia_account_tier, try(var.storage_account_sapbits.account_tier, "Standard"))
    account_replication_type = coalesce(var.library_sapmedia_account_replication_type, try(var.storage_account_sapbits.account_replication_type, "LRS"))
    account_kind             = coalesce(var.library_sapmedia_account_kind, try(var.storage_account_sapbits.account_kind, "StorageV2"))
    file_share = {
      enable_deployment = coalesce(var.library_sapmedia_file_share_enable_deployment, try(var.storage_account_sapbits.file_share.enable_deployment, true))
      is_existing       = coalesce(var.library_sapmedia_file_share_is_existing, try(var.storage_account_sapbits.file_share.is_existing, false))
      name              = coalesce(var.library_sapmedia_file_share_name, try(var.storage_account_sapbits.file_share.name, "sapbits"))
    }
    sapbits_blob_container = {
      enable_deployment = coalesce(var.library_sapmedia_blob_container_enable_deployment, try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, true))
      is_existing       = coalesce(var.library_sapmedia_blob_container_is_existing, try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false))
      name              = coalesce(var.library_sapmedia_blob_container_name, try(var.storage_account_sapbits.sapbits_blob_container.name, "sapbits"))
    }
  }
  storage_account_tfstate = {
    arm_id                   = try(coalesce(var.library_terraform_state_arm_id, try(var.storage_account_tfstate.arm_id, "")), "")
    account_tier             = coalesce(var.library_terraform_state_account_tier, try(var.storage_account_tfstate.account_tier, "Standard"))
    account_replication_type = coalesce(var.library_terraform_state_account_replication_type, try(var.storage_account_tfstate.account_replication_type, "LRS"))
    account_kind             = coalesce(var.library_terraform_state_account_kind, try(var.storage_account_tfstate.account_kind, "StorageV2"))
    tfstate_blob_container = {
      is_existing = coalesce(var.library_terraform_state_blob_container_is_existing, try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false))
      name        = coalesce(var.library_terraform_state_blob_container_name, try(var.storage_account_tfstate.tfstate_blob_container.name, "tfstate"))
    }
    ansible_blob_container = {
      is_existing = coalesce(var.library_ansible_blob_container_is_existing, try(var.storage_account_tfstate.ansible_blob_container.is_existing, false))
      name        = coalesce(var.library_ansible_blob_container_name, try(var.storage_account_tfstate.ansible_blob_container.name, "ansible"))
    }
  }

  key_vault_temp = {
  }

  user_kv_specified = (length(var.user_keyvault_id) + length(try(var.key_vault.kv_user_id, ""))) > 0
  user_kv           = local.user_kv_specified ? try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "") : ""
  prvt_kv_specified = (length(var.automation_keyvault_id) + length(try(var.key_vault.kv_prvt, ""))) > 0
  prvt_kv           = local.prvt_kv_specified ? try(coalesce(var.automation_keyvault_id, try(var.key_vault.kv_prvt_id, "")), "") : ""
  spn_kv_specified  = (length(var.spn_keyvault_id) + length(try(var.key_vault.kv_spn_id, ""))) > 0
  spn_kv            = local.spn_kv_specified ? try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "") : ""


  key_vault = merge(local.key_vault_temp, (
    local.user_kv_specified ? { "kv_user_id" = local.user_kv } : null), (
    local.prvt_kv_specified ? { "kv_prvt_id" = local.prvt_kv } : null), (
    local.spn_kv_specified ? { "kv_spn_id" = local.spn_kv } : null
    )
  )


  infrastructure = merge(local.temp_infrastructure, (
    local.resource_group_defined ? { "resource_group" = local.resource_group } : null)

  )

}
