locals {

  sdu_name = length(var.codename) > 0 ? (
    upper(format("%s-%s-%s_%s-%s", local.env_verified, local.location_short, local.sap_vnet_verified, var.codename, var.sap_sid))) : (
    upper(format("%s-%s-%s-%s", local.env_verified, local.location_short, local.sap_vnet_verified, var.sap_sid))
  )

  deployer_name  = upper(format("%s-%s-%s", local.deployer_env_verified, local.deployer_location_short, local.dep_vnet_verified))
  landscape_name = upper(format("%s-%s-%s", local.landscape_env_verified, local.location_short, local.sap_vnet_verified))
  library_name   = upper(format("%s-%s", local.library_env_verified, local.location_short))

  // Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only. The name must be unique.
  deployer_storageaccount_name       = substr(replace(lower(format("%s%s%sdiag%s", local.deployer_env_verified, local.deployer_location_short, local.dep_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  landscape_storageaccount_name      = substr(replace(lower(format("%s%s%sdiag%s", local.landscape_env_verified, local.location_short, local.sap_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  library_storageaccount_name        = substr(replace(lower(format("%s%ssaplib%s", local.library_env_verified, local.location_short, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  sdu_storageaccount_name            = substr(replace(lower(format("%s%s%sdiag%s", local.env_verified, local.location_short, local.sap_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  terraformstate_storageaccount_name = substr(replace(lower(format("%s%stfstate%s", local.library_env_verified, local.location_short, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)

}
