/*
  Description:
  Define local variables
*/

variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

variable "deployer_tfstate" {
  description = "Deployer remote tfstate file"
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

/* Comment out code with users.object_id for the time being
variable "deployer_user" {
  description = "Details of the users"
  default     = []
}
*/

variable naming {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

locals {
  // Resources naming
  vnet_prefix                 = var.naming.prefix.VNET
  storageaccount_name         = var.naming.storageaccount_names.SDU
  sid_keyvault_names          = var.naming.keyvault_names.SDU
  anchor_virtualmachine_names = var.naming.virtualmachine_names.ANCHOR_VMNAME
  anchor_computer_names       = var.naming.virtualmachine_names.ANCHOR_COMPUTERNAME
  resource_suffixes           = var.naming.resource_suffixes
}

locals {
  //Region and metadata
  region = try(local.var_infra.region, "")
  sid    = upper(try(var.application.sid, ""))
  prefix = try(var.infrastructure.resource_group.name, var.naming.prefix.SDU)

  // Zonal support - 1 PPG by default and with zonal 1 PPG per zone
  db_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") != "NONE"
  ]
  db_zones         = try(local.db_list[0].zones, [])
  app_zones        = try(var.application.app_zones, [])
  scs_zones        = try(var.application.scs_zones, [])
  web_zones        = try(var.application.web_zones, [])
  zones            = distinct(concat(local.db_zones, local.app_zones, local.scs_zones, local.web_zones))
  zonal_deployment = length(local.zones) > 0 ? true : false

  // Retrieve information about Deployer from tfstate file
  deployer_tfstate = var.deployer_tfstate

  // Retrieve information about Sap Landscape from tfstate file
  landscape_tfstate  = var.landscape_tfstate
  kv_landscape_id    = try(local.landscape_tfstate.landscape_key_vault_user_arm_id, "")
  secret_sid_pk_name = try(local.landscape_tfstate.sid_public_key_secret_name, "")
  iscsi_private_ip   = try(local.landscape_tfstate.iscsi_private_ip, [])

  //Filter the list of databases to only HANA platform entries
  databases = [
    for database in var.databases : database
    if try(database.platform, "NONE") != "NONE"
  ]

  db    = try(local.databases[0], {})
  db_ha = try(local.db.high_availability, "false")

  //If custom image is used, we do not overwrite os reference with default value
  db_custom_image = try(local.db.os.source_image_id, "") != "" ? true : false

  db_os = {
    "source_image_id" = local.db_custom_image ? local.db.os.source_image_id : ""
    "publisher"       = try(local.db.os.publisher, local.db_custom_image ? "" : "suse")
    "offer"           = try(local.db.os.offer, local.db_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.db.os.sku, local.db_custom_image ? "" : "gen1")
    "version"         = try(local.db.os.version, local.db_custom_image ? "" : "latest")
  }

  db_ostype = upper(try(local.db.os.os_type, "LINUX"))

  db_auth = try(local.db.authentication,
    {
      "type"     = "key"
      "username" = "azureadm"
  })

  //Enable DB deployment 
  hdb_list = [
    for db in var.databases : db
    if contains(["HANA"], upper(try(db.platform, "NONE")))
  ]

  enable_hdb_deployment = (length(local.hdb_list) > 0) ? true : false

  default_filepath = local.enable_hdb_deployment ? "${path.module}/../../../../../configs/hdb_sizes.json" : "${path.module}/../../../../../configs/anydb_sizes.json"
  sizes            = jsondecode(file(length(var.custom_disk_sizes_filename) > 0 ? var.custom_disk_sizes_filename : local.default_filepath))
  storage_list     = length(var.databases) > 0 ? lookup(local.sizes, var.databases[0].size).storage : []
  enable_ultradisk = try(compact([
    for storage in local.storage_list :
    storage.disk_type == "UltraSSD_LRS" ? true : ""
  ])[0], false)

  //Enable xDB deployment 
  xdb_list = [
    for db in var.databases : db
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(db.platform, "NONE")))
  ]
  
  enable_xdb_deployment = (length(local.xdb_list) > 0) ? true : false
  enable_db_deployment  = local.enable_xdb_deployment || local.enable_hdb_deployment

  //Enable APP deployment
  enable_app_deployment = try(var.application.enable_deployment, false)

  //Enable SID deployment
  enable_sid_deployment = local.enable_db_deployment || local.enable_app_deployment 

  var_infra = try(var.infrastructure, {})

  //Anchor VM
  anchor                      = try(local.var_infra.anchor_vms, {})
  deploy_anchor               = length(local.anchor) > 0 ? true : false
  anchor_size                 = try(local.anchor.sku, "Standard_D8s_v3")
  anchor_authentication       = try(local.anchor.authentication, local.db_auth)
  anchor_auth_type            = try(local.anchor.authentication.type, "key")
  enable_anchor_auth_password = local.deploy_anchor && local.anchor_auth_type == "password"
  enable_anchor_auth_key      = local.deploy_anchor && local.anchor_auth_type == "key"

  //If the db uses ultra disks ensure that the anchore sets the ultradisk flag but only for the zones that will contain db servers
  enable_anchor_ultra = [
    for zone in local.zones :
    contains(local.db_zones, zone) ? local.enable_ultradisk : false
  ]

  enable_accelerated_networking = try(local.anchor.accelerated_networking, false)
  anchor_nic_ips                = local.sub_admin_exists ? try(local.anchor.nic_ips, []) : []

  anchor_custom_image = try(local.anchor.os.source_image_id, "") != "" ? true : false

  anchor_os = {
    "source_image_id" = local.anchor_custom_image ? local.anchor.os.source_image_id : ""
    "publisher"       = try(local.anchor.os.publisher, local.anchor_custom_image ? "" : local.db_os.publisher)
    "offer"           = try(local.anchor.os.offer, local.anchor_custom_image ? "" : local.db_os.offer)
    "sku"             = try(local.anchor.os.sku, local.anchor_custom_image ? "" : local.db_os.sku)
    "version"         = try(local.anchor.os.version, local.anchor_custom_image ? "" : local.db_os.version)
  }

  anchor_ostype = upper(try(local.anchor.os.os_type, local.db_ostype))

  //Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_arm_id = try(local.var_rg.arm_id, "")
  rg_exists = length(local.rg_arm_id) > 0 ? true : false
  rg_name   = local.rg_exists ? try(split("/", local.rg_arm_id)[4], "") : try(local.var_rg.name, format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))

  //PPG
  var_ppg    = try(local.var_infra.ppg, {})
  ppg_arm_id = try(local.var_ppg.arm_id, "")
  ppg_exists = length(local.ppg_arm_id) > 0 ? true : false
  ppg_name   = local.ppg_exists ? try(split("/", local.ppg_arm_id)[8], "") : try(local.var_ppg.name, format("%s%s", local.prefix, local.resource_suffixes.ppg))

  /* Comment out code with users.object_id for the time being
  // Additional users add to user KV
  kv_users = var.deployer_user
  */

  // SAP Landscape infrastructure
  landscape_infrastructure = try(local.landscape_tfstate.landscape_infrastructure, {})
  
  //SAP vnet
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, format("%s%s", local.vnet_prefix, local.resource_suffixes.vnet))
  vnet_sap_addr   = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.address_space, "")

  //Admin subnet
  enable_admin_subnet = try(var.application.dual_nics, false) || try(var.databases[0].dual_nics, false) || (try(upper(local.db.platform), "NONE") == "HANA")
  var_sub_admin       = try(local.var_vnet_sap.subnet_admin, {})
  sub_admin_arm_id    = try(local.var_sub_admin.arm_id, "")
  sub_admin_exists    = length(local.sub_admin_arm_id) > 0

  sub_admin_name   = local.sub_admin_exists ? try(split("/", local.sub_admin_arm_id)[10], "") : try(local.var_sub_admin.name, format("%s%s", local.prefix, local.resource_suffixes.admin_subnet))
  sub_admin_prefix = local.sub_admin_exists ? "" : try(local.var_sub_admin.prefix, "")

  //Admin NSG
  var_sub_admin_nsg    = try(local.var_sub_admin.nsg, {})
  sub_admin_nsg_arm_id = try(local.var_sub_admin_nsg.arm_id, "")
  sub_admin_nsg_exists = length(local.sub_admin_nsg_arm_id) > 0 ? true : false
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? try(split("/", local.sub_admin_nsg_arm_id)[8], "") : try(local.var_sub_admin_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.admin_subnet_nsg))

  //DB subnet
  var_sub_db    = try(local.var_vnet_sap.subnet_db, {})
  sub_db_arm_id = try(local.var_sub_db.arm_id, "")
  sub_db_exists = length(local.sub_db_arm_id) > 0 ? true : false
  sub_db_name   = local.sub_db_exists ? try(split("/", local.sub_db_arm_id)[10], "") : try(local.var_sub_db.name, format("%s%s", local.prefix, local.resource_suffixes.db_subnet))
  sub_db_prefix = local.sub_db_exists ? "" : try(local.var_sub_db.prefix, "")

  //DB NSG
  var_sub_db_nsg    = try(local.var_sub_db.nsg, {})
  sub_db_nsg_arm_id = try(local.var_sub_db_nsg.arm_id, "")
  sub_db_nsg_exists = length(local.sub_db_nsg_arm_id) > 0 ? true : false
  sub_db_nsg_name   = local.sub_db_nsg_exists ? try(split("/", local.sub_db_nsg_arm_id)[8], "") : try(local.var_sub_db_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.db_subnet_nsg))

  //APP subnet
  var_sub_app    = try(local.var_vnet_sap.subnet_app, {})
  sub_app_arm_id = try(local.var_sub_app.arm_id, "")
  sub_app_exists = length(local.sub_app_arm_id) > 0 ? true : false
  sub_app_name   = local.sub_app_exists ? "" : try(local.var_sub_app.name, format("%s%s", local.prefix, local.resource_suffixes.app_subnet))
  sub_app_prefix = local.sub_app_exists ? "" : try(local.var_sub_app.prefix, "")

  //APP NSG
  var_sub_app_nsg    = try(local.var_sub_app.nsg, {})
  sub_app_nsg_arm_id = try(local.var_sub_app_nsg.arm_id, "")
  sub_app_nsg_exists = length(local.sub_app_nsg_arm_id) > 0 ? true : false
  sub_app_nsg_name   = local.sub_app_nsg_exists ? try(split("/", local.sub_app_nsg_arm_id)[8], "") : try(local.var_sub_app_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.app_subnet_nsg))

  //---- Update infrastructure with defaults ----//
  infrastructure = {
    resource_group = {
      is_existing = local.rg_exists,
      name        = local.rg_name,
      arm_id      = local.rg_arm_id
    },
    ppg = {
      is_existing = local.ppg_exists,
      name        = local.ppg_name,
      arm_id      = local.ppg_arm_id
    },
    iscsi = local.landscape_infrastructure.iscsi
    vnets = {
      sap = merge(local.landscape_infrastructure.vnets.sap, {
        subnet_admin = {
          is_existing = local.sub_admin_exists,
          arm_id      = local.sub_admin_arm_id,
          name        = local.sub_admin_name,
          prefix      = local.sub_admin_prefix,
          nsg = {
            is_existing = local.sub_admin_nsg_exists,
            arm_id      = local.sub_admin_nsg_arm_id,
            name        = local.sub_admin_nsg_name
          }
        },
        subnet_db = {
          is_existing = local.sub_db_exists,
          arm_id      = local.sub_db_arm_id,
          name        = local.sub_db_name,
          prefix      = local.sub_db_prefix,
          nsg = {
            is_existing = local.sub_db_nsg_exists,
            arm_id      = local.sub_db_nsg_arm_id,
            name        = local.sub_db_nsg_name
          }
        },
        subnet_app = {
          is_existing = local.sub_app_exists,
          arm_id      = local.sub_app_arm_id,
          name        = local.sub_app_name,
          prefix      = local.sub_app_prefix,
          nsg = {
            is_existing = local.sub_app_nsg_exists,
            arm_id      = local.sub_app_nsg_arm_id,
            name        = local.sub_app_nsg_name
          }
        }
      })
    }
  }

  // Current service principal
  service_principal = try(var.service_principal, {})

}
