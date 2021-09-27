variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "v2"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "HANA Database"
}

variable "db_disk_sizes_filename" {
  description = "Custom disk configuration json file for database tier"
  default     = ""
}

variable "app_disk_sizes_filename" {
  description = "Custom disk configuration json file for application tier"
  default     = ""
}

variable "tfstate_resource_id" {
  description = "Resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""
}

variable "landscape_tfstate_key" {
  description = "The key of sap landscape's remote tfstate file"

  validation {
    condition = (
      length(trimspace(try(var.landscape_tfstate_key, ""))) != 0
    )
    error_message = "The Landscape state file name must be specified."
  }

}

variable "deployment" {
  description = "The type of deployment"
  default     = "update"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
  default     = ""
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""

}

locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))
  // The environment of sap landscape and sap system
  environment     = upper(local.infrastructure.environment)
  vnet_sap_arm_id = try(data.terraform_remote_state.landscape.outputs.vnet_sap_arm_id, "")

  vnet_logical_name = local.infrastructure.vnets.sap.name
  vnet_sap_exists   = length(local.vnet_sap_arm_id) > 0 ? true : false

  //SID determination

  hana-databases = [
    for db in local.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  // Filter the list of databases to only AnyDB platform entries
  // Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in local.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  hdb            = try(local.hana-databases[0], {})
  hdb_ins        = try(local.hdb.instance, {})
  hanadb_sid     = try(local.hdb_ins.sid, "HDB") // HANA database sid from the Databases array for use as reference to LB/AS
  anydb_platform = try(local.anydb-databases[0].platform, "NONE")
  anydb_sid      = (length(local.anydb-databases) > 0) ? try(local.anydb-databases[0].instance.sid, lower(substr(local.anydb_platform, 0, 3))) : lower(substr(local.anydb_platform, 0, 3))
  db_sid         = length(local.hana-databases) > 0 ? local.hanadb_sid : local.anydb_sid
  sap_sid        = upper(try(local.application.sid, local.db_sid))

  app_ostype            = try(local.application.os.os_type, "LINUX")
  db_ostype             = try(local.databases[0].os.os_type, "LINUX")
  db_server_count       = try(length(local.databases[0].dbnodes), 1)
  app_server_count      = try(local.application.application_server_count, 0)
  webdispatcher_count   = try(local.application.webdispatcher_count, 0)
  scs_high_availability = try(local.application.scs_high_availability, false)
  scs_server_count      = try(local.application.scs_server_count, 0) * (local.scs_high_availability ? 2 : 1)

  db_zones  = try(local.databases[0].zones, [])
  app_zones = try(local.application.app_zones, [])
  scs_zones = try(local.application.scs_zones, [])
  web_zones = try(local.application.web_zones, [])

  anchor        = try(local.infrastructure.anchor_vms, {})
  anchor_ostype = upper(try(local.anchor.os.os_type, "LINUX"))

  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate
  deployer_tfstate_key         = try(var.deployer_tfstate_key, "")
  landscape_tfstate_key        = var.landscape_tfstate_key

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = coalesce(try(local.key_vault.kv_spn_id, ""), try(data.terraform_remote_state.landscape.outputs.landscape_key_vault_spn_arm_id, ""), try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, ""))

  deployer_subscription_id = length(local.spn_key_vault_arm_id) > 0 ? split("/", local.spn_key_vault_arm_id)[2] : ""

  use_spn = !try(var.options.nospn, false)


  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = local.use_spn ? try(data.azurerm_key_vault_secret.client_id[0].value, null) : null,
    client_secret   = local.use_spn ? try(data.azurerm_key_vault_secret.client_secret[0].value, null) : null,
    tenant_id       = local.use_spn ? try(data.azurerm_key_vault_secret.tenant_id[0].value, null) : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = local.use_spn ? try(data.azuread_service_principal.sp[0].id, null) : null
  }

  account = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }
}
