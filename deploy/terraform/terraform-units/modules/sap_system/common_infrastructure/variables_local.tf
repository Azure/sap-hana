/*
Description:

  Define local variables.
*/

variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
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

variable naming {
  description = "Defines the names for the resources"
}

//Set defaults
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

  vnet_prefix                 = var.naming.prefix.VNET
  storageaccount_name         = var.naming.storageaccount_names.SDU
  keyvault_names              = var.naming.keyvault_names.SDU
  virtualmachine_names        = var.naming.virtualmachine_names.ISCSI_COMPUTERNAME
  anchor_virtualmachine_names = var.naming.virtualmachine_names.ANCHOR_VMNAME
  anchor_computer_names       = var.naming.virtualmachine_names.ANCHOR_COMPUTERNAME
  resource_suffixes           = var.naming.resource_suffixes


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

  var_infra = try(var.infrastructure, {})

  //Anchor VM

  anchor                = try(local.var_infra.anchor_vms, {})
  deploy_anchor         = length(local.anchor) > 0 ? true : false
  anchor_size           = try(local.anchor.sku, "Standard_D8s_v3")
  anchor_authentication = try(local.anchor.authentication, local.db_auth)
  anchor_nic_ips        = local.sub_admin_exists ? try(local.anchor.nic_ips, []) : []

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
  rg_name   = local.rg_exists ? try(split("/", local.rg_arm_id)[4], "") : try(local.var_rg.name, format("%s%s", local.prefix, local.resource_suffixes.sdu-rg))

  //PPG
  var_ppg    = try(local.var_infra.ppg, {})
  ppg_arm_id = try(local.var_ppg.arm_id, "")
  ppg_exists = length(local.ppg_arm_id) > 0 ? true : false
  ppg_name   = local.ppg_exists ? try(split("/", local.ppg_arm_id)[8], "") : try(local.var_ppg.name, format("%s%s", local.prefix, local.resource_suffixes.ppg))

  //iSCSI
  var_iscsi = try(local.var_infra.iscsi, {})

  enable_admin_subnet = try(var.application.dual_nics, false) || try(var.databases[0].dual_nics, false) || (upper(local.db.platform) == "HANA")

  //iSCSI target device(s) is only created when below conditions met:
  //- iscsi is defined in input JSON
  //- AND
  //  - HANA database has high_availability set to true
  //  - HANA database uses SUSE
  iscsi_count = (local.db_ha && upper(local.db_os.publisher) == "SUSE") ? try(local.var_iscsi.iscsi_count, 0) : 0
  iscsi_size  = try(local.var_iscsi.size, "Standard_D2s_v3")
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
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, format("%s%s", local.vnet_prefix, local.resource_suffixes.vnet))
  vnet_sap_addr   = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.address_space, "")

  //Admin subnet
  var_sub_admin    = try(local.var_vnet_sap.subnet_admin, {})
  sub_admin_arm_id = try(local.var_sub_admin.arm_id, "")
  sub_admin_exists = length(local.sub_admin_arm_id) > 0 ? true : false

  sub_admin_name   = local.sub_admin_exists ? try(split("/", local.sub_admin_arm_id)[10], "") : try(local.var_sub_admin.name, format("%s%s", local.prefix, local.resource_suffixes.admin-subnet))
  sub_admin_prefix = local.sub_admin_exists ? "" : try(local.var_sub_admin.prefix, "")

  //Admin NSG
  var_sub_admin_nsg    = try(local.var_sub_admin.nsg, {})
  sub_admin_nsg_arm_id = try(local.var_sub_admin_nsg.arm_id, "")
  sub_admin_nsg_exists = length(local.sub_admin_nsg_arm_id) > 0 ? true : false
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? try(split("/", local.sub_admin_nsg_arm_id)[8], "") : try(local.var_sub_admin_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.admin-subnet-nsg))

  //DB subnet
  var_sub_db    = try(local.var_vnet_sap.subnet_db, {})
  sub_db_arm_id = try(local.var_sub_db.arm_id, "")
  sub_db_exists = length(local.sub_db_arm_id) > 0 ? true : false
  sub_db_name   = local.sub_db_exists ? try(split("/", local.sub_db_arm_id)[10], "") : try(local.var_sub_db.name, format("%s%s", local.prefix, local.resource_suffixes.db-subnet))
  sub_db_prefix = local.sub_db_exists ? "" : try(local.var_sub_db.prefix, "")

  //DB NSG
  var_sub_db_nsg    = try(local.var_sub_db.nsg, {})
  sub_db_nsg_arm_id = try(local.var_sub_db_nsg.arm_id, "")
  sub_db_nsg_exists = length(local.sub_db_nsg_arm_id) > 0 ? true : false
  sub_db_nsg_name   = local.sub_db_nsg_exists ? try(split("/", local.sub_db_nsg_arm_id)[8], "") : try(local.var_sub_db_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.db-subnet-nsg))

  //iSCSI subnet
  var_sub_iscsi    = try(local.var_vnet_sap.subnet_iscsi, {})
  sub_iscsi_arm_id = try(local.var_sub_iscsi.arm_id, "")
  sub_iscsi_exists = length(local.sub_iscsi_arm_id) > 0 ? true : false
  sub_iscsi_name   = local.sub_iscsi_exists ? try(split("/", local.sub_iscsi_arm_id)[10], "") : try(local.var_sub_iscsi.name, format("%s%s", local.prefix, local.resource_suffixes.iscsi-subnet))
  sub_iscsi_prefix = local.sub_iscsi_exists ? "" : try(local.var_sub_iscsi.prefix, "")

  //iSCSI NSG
  var_sub_iscsi_nsg    = try(local.var_sub_iscsi.nsg, {})
  sub_iscsi_nsg_arm_id = try(local.var_sub_iscsi_nsg.arm_id, "")
  sub_iscsi_nsg_exists = length(local.sub_iscsi_nsg_arm_id) > 0 ? true : false
  sub_iscsi_nsg_name   = local.sub_iscsi_nsg_exists ? try(split("/", local.sub_iscsi_nsg_arm_id)[8], "") : try(local.var_sub_iscsi_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.iscsi-subnet-nsg))

  //APP subnet
  var_sub_app    = try(local.var_vnet_sap.subnet_app, {})
  sub_app_arm_id = try(local.var_sub_app.arm_id, "")
  sub_app_exists = length(local.sub_app_arm_id) > 0 ? true : false
  sub_app_name   = local.sub_app_exists ? "" : try(local.var_sub_app.name, format("%s%s", local.prefix, local.resource_suffixes.app-subnet))
  sub_app_prefix = local.sub_app_exists ? "" : try(local.var_sub_app.prefix, "")

  //APP NSG
  var_sub_app_nsg    = try(local.var_sub_app.nsg, {})
  sub_app_nsg_arm_id = try(local.var_sub_app_nsg.arm_id, "")
  sub_app_nsg_exists = length(local.sub_app_nsg_arm_id) > 0 ? true : false
  sub_app_nsg_name   = local.sub_app_nsg_exists ? try(split("/", local.sub_app_nsg_arm_id)[8], "") : try(local.var_sub_app_nsg.name, format("%s%s", local.prefix, local.resource_suffixes.app-subnet-nsg))

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
  sap_user     = try(var.software.downloader.credentials.sap_user, "sap_smp_user")
  sap_password = try(var.software.downloader.credentials.sap_password, "sap_smp_password")
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
}
