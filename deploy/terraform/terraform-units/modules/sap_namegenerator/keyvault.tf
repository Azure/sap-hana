locals {

  sdu_private_keyvault_name = format("%s%s%s%sp%s", replace(local.env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, replace(local.sap_vnet_verified, "/[^A-Za-z0-9]/", ""), var.sap_sid, local.random_id_verified)
  sdu_user_keyvault_name    = format("%s%s%s%su%s", replace(local.env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, replace(local.sap_vnet_verified, "/[^A-Za-z0-9]/", ""), var.sap_sid, local.random_id_verified)

  deployer_private_keyvault_name = format("%s%s%sprvt%s", replace(local.deployer_env_verified, "/[^A-Za-z0-9]/", ""), local.deployer_location_short, replace(local.dep_vnet_verified, "/[^A-Za-z0-9]/", ""), local.random_id_verified)
  deployer_user_keyvault_name    = format("%s%s%suser%s", replace(local.deployer_env_verified, "/[^A-Za-z0-9]/", ""), local.deployer_location_short, replace(local.dep_vnet_verified, "/[^A-Za-z0-9]/", ""), local.random_id_verified)

  landscape_private_keyvault_name = format("%s%s%sprvt%s", replace(local.landscape_env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, replace(local.sap_vnet_verified, "/[^A-Za-z0-9]/", ""), local.random_id_verified)
  landscape_user_keyvault_name    = format("%s%s%suser%s", replace(local.landscape_env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, replace(local.sap_vnet_verified, "/[^A-Za-z0-9]/", ""), local.random_id_verified)

  library_private_keyvault_name = format("%s%sSAPLIBprvt%s", replace(local.library_env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, local.random_id_verified)
  library_user_keyvault_name    = format("%s%sSAPLIBuser%s", replace(local.library_env_verified, "/[^A-Za-z0-9]/", ""), local.location_short, local.random_id_verified)

}
