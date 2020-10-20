/*
Description:

  Define local variables.
*/

variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

variable "subnet-sap-admin" {
  description = "Information about SAP admin subnet"
}

variable "vnet-mgmt" {
  description = "Details about management vnet of deployer(s)"
}

variable "subnet-mgmt" {
  description = "Details about management subnet of deployer(s)"
}

variable "nsg-mgmt" {
  description = "Details about management nsg of deployer(s)"
}

variable "spn" {
  description = "Current SPN used to authenticate to Azure"
}

variable "deployer-uai" {
  description = "Details of the UAI used by deployer(s)"
}
/* Comment out code with users.object_id for the time being
variable "deployer_user" {
  description = "Details of the users"
  default     = []
}
*/
variable "region_mapping" {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"

  //28 Regions 

  default = {
    westus             = "weus"
    westus2            = "wus2"
    centralus          = "ceus"
    eastus             = "eaus"
    eastus2            = "eus2"
    northcentralus     = "ncus"
    southcentralus     = "scus"
    westcentralus      = "wcus"
    northeurope        = "noeu"
    westeurope         = "weeu"
    eastasia           = "eaas"
    southeastasia      = "seas"
    brazilsouth        = "brso"
    japaneast          = "jpea"
    japanwest          = "jpwe"
    centralindia       = "cein"
    southindia         = "soin"
    westindia          = "wein"
    uksouth2           = "uks2"
    uknorth            = "ukno"
    canadacentral      = "cace"
    canadaeast         = "caea"
    australiaeast      = "auea"
    australiasoutheast = "ause"
    uksouth            = "ukso"
    ukwest             = "ukwe"
    koreacentral       = "koce"
    koreasouth         = "koso"
  }
}

//Set defaults
locals {

  //Filter the list of databases to only HANA platform entries
  hana-databases = [
    for database in var.databases : database
    if try(database.platform, "NONE") == "HANA"
  ]
  hdb    = try(local.hana-databases[0], {})
  hdb_ha = try(local.hdb.high_availability, "false")
  //If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image = try(local.hdb.os.source_image_id, "") != "" ? true : false
  hdb_os = {
    "source_image_id" = local.hdb_custom_image ? local.hdb.os.source_image_id : ""
    "publisher"       = try(local.hdb.os.publisher, local.hdb_custom_image ? "" : "suse")
    "offer"           = try(local.hdb.os.offer, local.hdb_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.hdb.os.sku, local.hdb_custom_image ? "" : "gen1")
    "version"         = try(local.hdb.os.version, local.hdb_custom_image ? "" : "latest")
  }

  //Enable DB deployment 
  hdb_list = [
    for db in var.databases : db
    if contains(["HANA"], upper(try(db.platform, "NONE")))
  ]
  enable_hdb_deployment = (length(local.hdb_list) > 0) ? true : false

  //Enable xDB deployment 
  xdb_list = [
    for db in var.databases : db
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(db.platform, "NONE")))
  ]
  enable_xdb_deployment = (length(local.xdb_list) > 0) ? true : false

  //Enable APP deployment
  enable_app_deployment = try(var.application.enable_deployment, false)

  //Enable SID deployment
  enable_sid_deployment = local.enable_hdb_deployment || local.enable_app_deployment || local.enable_xdb_deployment

  var_infra = try(var.infrastructure, {})

  //Region and metadata
  region         = try(local.var_infra.region, "")
  environment    = lower(try(local.var_infra.environment, ""))
  sid            = upper(try(var.application.sid, ""))
  codename       = lower(try(local.var_infra.codename, ""))
  location_short = lower(try(var.region_mapping[local.region], "unkn"))
  // Using replace "--" with "-" and "_-" with "-" in case of one of the components like codename is empty
  prefix      = try(local.var_infra.resource_group.name, upper(replace(replace(format("%s-%s-%s_%s-%s", local.environment, local.location_short, substr(local.vnet_sap_name_prefix, 0, 7), local.codename, local.sid), "_-", "-"), "--", "-")))
  sa_prefix   = lower(format("%s%s%s%sdiag", substr(local.environment, 0, 5), local.location_short, substr(local.codename, 0, 7), local.sid))
  vnet_prefix = try(local.var_infra.resource_group.name, upper(format("%s-%s-%s", local.environment, local.location_short, local.vnet_sap_name_prefix)))

  //Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_exists = try(local.var_rg.is_existing, false)
  rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
  rg_name   = local.rg_exists ? try(split("/", local.rg_arm_id)[4], "") : try(local.var_rg.name, local.prefix)

  //PPG
  var_ppg    = try(local.var_infra.ppg, {})
  ppg_exists = try(local.var_ppg.is_existing, false)
  ppg_arm_id = local.ppg_exists ? try(local.var_ppg.arm_id, "") : ""
  ppg_name   = local.ppg_exists ? try(split("/", local.ppg_arm_id)[8], "") : try(local.var_ppg.name, format("%s_ppg", local.prefix))

  // Post fix for all deployed resources
  postfix = random_id.saplandscape.hex

  /* Comment out code with users.object_id for the time being
  // Additional users add to user KV
  kv_users = var.deployer_user
*/
  // kv for sap landscape
  kv_prefix       = upper(format("%s%s%s", substr(local.environment, 0, 5), local.location_short, substr(local.vnet_sap_name_prefix, 0, 7)))
  kv_private_name = format("%sprvt%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))
  kv_user_name    = format("%suser%s", local.kv_prefix, upper(substr(local.postfix, 0, 3)))

  // key vault naming for sap system
  sid_kv_prefix       = upper(format("%s%s%s", substr(local.environment, 0, 5), local.location_short, substr(local.vnet_sap_name_prefix, 0, 7)))
  sid_kv_private_name = format("%s%sp%s", local.kv_prefix, local.sid, upper(substr(local.postfix, 0, 3)))
  sid_kv_user_name    = format("%s%su%s", local.kv_prefix, local.sid, upper(substr(local.postfix, 0, 3)))

  /* 
     TODO: currently sap landscape and sap system haven't been decoupled. 
     The key vault information of sap landscape will be obtained via input json.
     At phase 2, the logic will be updated and the key vault information will be obtained from tfstate file of sap landscape.  
  */
  kv_landscape_id     = try(local.var_infra.landscape.key_vault_arm_id, "")
  secret_sid_pk_name  = try(local.var_infra.landscape.sid_public_key_secret_name, "")
  enable_landscape_kv = local.kv_landscape_id == "" ? true : false

  //iSCSI
  var_iscsi = try(local.var_infra.iscsi, {})

  //iSCSI target device(s) is only created when below conditions met:
  //- iscsi is defined in input JSON
  iscsi_count = try(local.var_iscsi.iscsi_count, 0)

  iscsi_size = try(local.var_iscsi.size, "Standard_D2s_v3")
  iscsi_os = try(local.var_iscsi.os,
    {
      "publisher" = try(local.var_iscsi.os.publisher, "SUSE")
      "offer"     = try(local.var_iscsi.os.offer, "sles-sap-12-sp5")
      "sku"       = try(local.var_iscsi.os.sku, "gen1")
      "version"   = try(local.var_iscsi.os.version, "latest")
  })
  iscsi_auth_type     = try(local.var_iscsi.authentication.type, "key")
  iscsi_auth_username = try(local.var_iscsi.authentication.username, "azureadm")
  iscsi_nic_ips       = local.sub_iscsi_exists ? try(local.var_iscsi.iscsi_nic_ips, []) : []

  // By default, ssh key for iSCSI uses generated public key. Provide sshkey.path_to_public_key and path_to_private_key overides it
  enable_iscsi_auth_key = local.iscsi_count > 0 && local.iscsi_auth_type == "key"
  iscsi_public_key      = local.enable_iscsi_auth_key ? try(file(var.sshkey.path_to_public_key), tls_private_key.iscsi[0].public_key_openssh) : null
  iscsi_private_key     = local.enable_iscsi_auth_key ? try(file(var.sshkey.path_to_private_key), tls_private_key.iscsi[0].private_key_pem) : null

  // By default, authentication type of iSCSI target is ssh key pair but using username/password is a potential usecase.
  enable_iscsi_auth_password = local.iscsi_count > 0 && local.iscsi_auth_type == "password"
  iscsi_auth_password        = local.enable_iscsi_auth_password ? try(local.var_iscsi.authentication.password, random_password.iscsi_password[0].result) : null

  iscsi = merge(local.var_iscsi, {
    iscsi_count = local.iscsi_count,
    size        = local.iscsi_size,
    os          = local.iscsi_os,
    authentication = {
      type     = local.iscsi_auth_type,
      username = local.iscsi_auth_username
    },
    iscsi_nic_ips = local.iscsi_nic_ips
  })

  //SAP vnet
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_exists = try(local.var_vnet_sap.is_existing, false)
  vnet_sap_arm_id = local.vnet_sap_exists ? try(local.var_vnet_sap.arm_id, "") : ""
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, format("%s-%s-SAP-vnet", upper(local.environment), upper(local.location_short)))
  vnet_nr_parts   = length(split("-", local.vnet_sap_name))
  // Default naming of vnet has multiple parts. Taking the second-last part as the name 
  vnet_sap_name_prefix = local.vnet_nr_parts >= 3 ? split("-", upper(local.vnet_sap_name))[local.vnet_nr_parts - 1] == "VNET" ? split("-", local.vnet_sap_name)[local.vnet_nr_parts - 2] : local.vnet_sap_name : local.vnet_sap_name
  vnet_sap_addr        = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.address_space, "")

  // By default, Ansible ssh key for SID uses generated public key. Provide sshkey.path_to_public_key and path_to_private_key overides it
  sid_public_key  = local.enable_landscape_kv ? try(file(var.sshkey.path_to_public_key), tls_private_key.sid[0].public_key_openssh) : null
  sid_private_key = local.enable_landscape_kv ? try(file(var.sshkey.path_to_private_key), tls_private_key.sid[0].private_key_pem) : null

  //Admin subnet
  var_sub_admin    = try(local.var_vnet_sap.subnet_admin, {})
  sub_admin_exists = try(local.var_sub_admin.is_existing, false)
  sub_admin_arm_id = local.sub_admin_exists ? try(local.var_sub_admin.arm_id, "") : ""
  sub_admin_name   = local.sub_admin_exists ? try(split("/", local.sub_admin_arm_id)[10], "") : try(local.var_sub_admin.name, format("%s-sap-vnet_admin-subnet", local.vnet_prefix))
  sub_admin_prefix = local.sub_admin_exists ? "" : try(local.var_sub_admin.prefix, "")

  //Admin NSG
  var_sub_admin_nsg    = try(local.var_sub_admin.nsg, {})
  sub_admin_nsg_exists = try(local.var_sub_admin_nsg.is_existing, false)
  sub_admin_nsg_arm_id = local.sub_admin_nsg_exists ? try(local.var_sub_admin_nsg.arm_id, "") : ""
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? try(split("/", local.sub_admin_nsg_arm_id)[8], "") : try(local.var_sub_admin_nsg.name, format("%s_adminSubnet-nsg", local.vnet_prefix))

  //DB subnet
  var_sub_db    = try(local.var_vnet_sap.subnet_db, {})
  sub_db_exists = try(local.var_sub_db.is_existing, false)
  sub_db_arm_id = local.sub_db_exists ? try(local.var_sub_db.arm_id, "") : ""
  sub_db_name   = local.sub_db_exists ? try(split("/", local.sub_db_arm_id)[10], "") : try(local.var_sub_db.name, format("%s_db-subnet", local.vnet_prefix))
  sub_db_prefix = local.sub_db_exists ? "" : try(local.var_sub_db.prefix, "")

  //DB NSG
  var_sub_db_nsg    = try(local.var_sub_db.nsg, {})
  sub_db_nsg_exists = try(local.var_sub_db_nsg.is_existing, false)
  sub_db_nsg_arm_id = local.sub_db_nsg_exists ? try(local.var_sub_db_nsg.arm_id, "") : ""
  sub_db_nsg_name   = local.sub_db_nsg_exists ? try(split("/", local.sub_db_nsg_arm_id)[8], "") : try(local.var_sub_db_nsg.name, format("%s_dbSubnet-nsg", local.vnet_prefix))

  //iSCSI subnet
  var_sub_iscsi    = try(local.var_vnet_sap.subnet_iscsi, {})
  sub_iscsi_exists = try(local.var_sub_iscsi.is_existing, false)
  sub_iscsi_arm_id = local.sub_iscsi_exists ? try(local.var_sub_iscsi.arm_id, "") : ""
  sub_iscsi_name   = local.sub_iscsi_exists ? try(split("/", local.sub_iscsi_arm_id)[10], "") : try(local.var_sub_iscsi.name, format("%s-_iscsi-subnet", local.vnet_prefix))
  sub_iscsi_prefix = local.sub_iscsi_exists ? "" : try(local.var_sub_iscsi.prefix, "")

  //iSCSI NSG
  var_sub_iscsi_nsg    = try(local.var_sub_iscsi.nsg, {})
  sub_iscsi_nsg_exists = try(local.var_sub_iscsi_nsg.is_existing, false)
  sub_iscsi_nsg_arm_id = local.sub_iscsi_nsg_exists ? try(local.var_sub_iscsi_nsg.arm_id, "") : ""
  sub_iscsi_nsg_name   = local.sub_iscsi_nsg_exists ? try(split("/", local.sub_iscsi_nsg_arm_id)[8], "") : try(local.var_sub_iscsi_nsg.name, format("%s-_iscsiSubnet-nsg", local.vnet_prefix))

  //APP subnet
  var_sub_app    = try(local.var_vnet_sap.subnet_app, {})
  sub_app_exists = try(local.var_sub_app.is_existing, false)
  sub_app_arm_id = local.sub_app_exists ? try(local.var_sub_app.arm_id, "") : ""
  sub_app_name   = local.sub_app_exists ? "" : try(local.var_sub_app.name, format("%s_app-subnet", local.vnet_prefix))
  sub_app_prefix = local.sub_app_exists ? "" : try(local.var_sub_app.prefix, "")

  //APP NSG
  var_sub_app_nsg    = try(local.var_sub_app.nsg, {})
  sub_app_nsg_exists = try(local.var_sub_app_nsg.is_existing, false)
  sub_app_nsg_arm_id = local.sub_app_nsg_exists ? try(local.var_sub_app_nsg.arm_id, "") : ""
  sub_app_nsg_name   = local.sub_app_nsg_exists ? try(split("/", local.sub_app_nsg_arm_id)[8], "") : try(local.var_sub_app_nsg.name, format("%s_appSubnet-nsg", local.vnet_prefix))

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
    }
    iscsi = { iscsi_count = local.iscsi_count,
      size = local.iscsi_size,
      os   = local.iscsi_os,
      authentication = {
        type     = local.iscsi_auth_type
        username = local.iscsi_auth_username
      }
    },
    vnets = {
      sap = {
        is_existing   = local.vnet_sap_exists,
        arm_id        = local.vnet_sap_arm_id,
        name          = local.vnet_sap_name,
        address_space = local.vnet_sap_addr,
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
        subnet_iscsi = {
          is_existing = local.sub_iscsi_exists,
          arm_id      = local.sub_iscsi_arm_id,
          name        = local.sub_iscsi_name,
          prefix      = local.sub_iscsi_prefix,
          nsg = {
            is_existing = local.sub_iscsi_nsg_exists,
            arm_id      = local.sub_iscsi_nsg_arm_id,
            name        = local.sub_iscsi_nsg_name
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
      }
    }
  }

  //Downloader
  sap_user     = "sap_smp_user"
  sap_password = "sap_smp_password"
  hdb_versions = [
    for scenario in try(var.software.downloader.scenarios, []) : scenario.product_version
    if scenario.scenario_type == "DB"
  ]
  hdb_version = try(local.hdb_versions[0], "2.0")

  downloader = merge({
    credentials = {
      sap_user     = local.sap_user,
      sap_password = local.sap_password
    }
    },
    {
      scenarios = [
        {
          scenario_type   = "DB",
          product_name    = "HANA",
          product_version = local.hdb_version,
          os_type         = "LINUX_X64",
          os_version      = "SLES12.3",
          components = [
            "PLATFORM"
          ]
        },
        {
          scenario_type = "RTI",
          product_name  = "RTI",
          os_type       = "LINUX_X64"
        },
        {
          scenario_type = "BASTION",
          os_type       = "NT_X64"
        },
        {
          scenario_type = "BASTION",
          os_type       = "LINUX_X64"
        }
      ],
      debug = {
        enabled = false,
        cert    = "charles.pem",
        proxies = {
          http  = "http://127.0.0.1:8888",
          https = "https://127.0.0.1:8888"
        }
      }
  })

  //---- Update software with defaults ----//
  software = merge(var.software, {
    downloader = local.downloader
  })

  // SPN
  spn = try(var.spn, {})

}
