
locals {
  infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = coalesce(var.location, try(var.infrastructure.region, ""))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))
    resource_group = {
      name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
      arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
    }
    tags = try(coalesce(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
  }
  deployer = {
    environment = coalesce(var.deployer_environment, try(var.deployer.environment, ""))
    region      = coalesce(var.deployer_location, try(var.deployer.region, ""))
    vnet        = coalesce(var.deployer_vnet, try(var.deployer.vnet, ""))
    use         = coalesce(var.use_deployer, try(var.deployer.use, true))

  }
  key_vault = {
    kv_user_id = try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "")
    kv_prvt_id = try(coalesce(var.automation_keyvault_id, try(var.key_vault.kv_prvt_id, "")), "")
    kv_prvt_id = try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "")
  }
  storage_account_sapbits = {
    arm_id                   = try(coalesce(var.library_sapmedia_arm_id, try(var.storage_account_sapbits.arm_id, "")), "")
    account_tier             = coalesce(var.library_sapmedia_account_tier, try(var.storage_account_sapbits.account_tier, ""))
    account_replication_type = coalesce(var.library_sapmedia_account_replication_type, try(var.storage_account_sapbits.account_replication_type, ""))
    account_kind             = coalesce(var.library_sapmedia_account_kind, try(var.storage_account_sapbits.account_kind, ""))
    file_share = {
      enable_deployment = var.library_sapmedia_file_share_enable_deployment || try(var.storage_account_sapbits.file_share.enable_deployment, true)
      is_existing       = var.library_sapmedia_file_share_is_existing && try(var.storage_account_sapbits.file_share.is_existing, false)
      name              = coalesce(var.library_sapmedia_file_share_name, try(var.storage_account_sapbits.file_share.name, "sapbits"))
    }
    sapbits_blob_container = {
      enable_deployment = var.library_sapmedia_blob_container_enable_deployment || try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, true)
      is_existing       = var.library_sapmedia_blob_container_is_existing && try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false)
      name              = coalesce(var.library_sapmedia_blob_container_name, try(var.storage_account_sapbits.sapbits_blob_container.name, "sapbits"))
    }
  }
  storage_account_tfstate = {
    arm_id                   = try(coalesce(var.library_terraform_state_arm_id, try(var.storage_account_tfstate.arm_id, "")), "")
    account_tier             = coalesce(var.library_terraform_state_account_tier, try(var.storage_account_tfstate.account_tier, ""))
    account_replication_type = coalesce(var.library_terraform_state_account_replication_type, try(var.storage_account_tfstate.account_replication_type, ""))
    account_kind             = coalesce(var.library_terraform_state_account_kind, try(var.storage_account_tfstate.account_kind, ""))
    tfstate_blob_container = {
      is_existing = var.library_terraform_state_blob_container_is_existing && try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
      name        = coalesce(var.library_terraform_state_blob_container_name, try(var.storage_account_tfstate.tfstate_blob_container.name, "tfstate"))
    }
    ansible_blob_container = {
      is_existing = var.library_ansible_blob_container_is_existing && try(var.storage_account_tfstate.ansible_blob_container.is_existing, false)
      name        = coalesce(var.library_ansible_blob_container_name, try(var.storage_account_tfstate.ansible_blob_container.name, "ansible"))
    }
  }

}