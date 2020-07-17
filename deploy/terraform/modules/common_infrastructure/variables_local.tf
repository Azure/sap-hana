variable "is_single_node_hana" {
  description = "Checks if single node hana architecture scenario is being deployed"
  default     = false
}

variable "subnet-sap-admin" {
  description = "Information about SAP admin subnet"
}

# Set defaults
locals {

  # Filter the list of databases to only HANA platform entries
  hana-databases = [
    for database in var.databases : database
    if try(database.platform, "NONE") == "HANA"
  ]
  hdb    = try(local.hana-databases[0], {})
  hdb_ha = try(local.hdb.high_availability, "false")
  # If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image = try(local.hdb.os.source_image_id, "") != "" ? true : false
  hdb_os = {
    "source_image_id" = local.hdb_custom_image ? local.hdb.os.source_image_id : ""
    "publisher"       = try(local.hdb.os.publisher, local.hdb_custom_image ? "" : "suse")
    "offer"           = try(local.hdb.os.offer, local.hdb_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.hdb.os.sku, local.hdb_custom_image ? "" : "gen1")
    "version"         = try(local.hdb.os.version, local.hdb_custom_image ? "" : "latest")
  }

  var_infra = try(var.infrastructure, {})

  # Region
  region = try(local.var_infra.region, "eastus")

  # Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_exists = try(local.var_rg.is_existing, false)
  rg_arm_id = local.rg_exists ? try(local.var_rg.arm_id, "") : ""
  rg_name   = local.rg_exists ? "" : try(local.var_rg.name, "azure-test-rg")

  # PPG
  var_ppg    = try(local.var_infra.ppg, {})
  ppg_exists = try(local.var_ppg.is_existing, false)
  ppg_arm_id = local.ppg_exists ? try(local.var_ppg.arm_id, "") : ""
  ppg_name   = local.ppg_exists ? "" : try(local.var_ppg.name, "azure-test-ppg")

  # iSCSI
  var_iscsi = try(local.var_infra.iscsi, {})

  # iSCSI target device(s) is only created when below conditions met:
  # - iscsi is defined in input JSON
  # - AND
  #   - HANA database has high_availability set to true
  #   - HANA database uses SUSE
  iscsi_count = (local.hdb_ha && upper(local.hdb_os.publisher) == "SUSE") ? try(local.var_iscsi.iscsi_count, 0) : 0

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

  # Management vnet
  var_vnet_mgmt    = try(local.var_infra.vnets.management, {})
  vnet_mgmt_exists = try(local.var_vnet_mgmt.is_existing, false)
  vnet_mgmt_arm_id = local.vnet_mgmt_exists ? try(local.var_vnet_mgmt.arm_id, "") : ""
  vnet_mgmt_name   = local.vnet_mgmt_exists ? "" : try(local.var_vnet_mgmt.name, "vnet-mgmt")
  vnet_mgmt_addr   = local.vnet_mgmt_exists ? "" : try(local.var_vnet_mgmt.address_space, "10.0.0.0/16")

  # Management subnet
  var_sub_mgmt    = try(local.var_vnet_mgmt.subnet_mgmt, {})
  sub_mgmt_exists = try(local.var_sub_mgmt.is_existing, false)
  sub_mgmt_arm_id = local.sub_mgmt_exists ? try(local.var_sub_mgmt.arm_id, "") : ""
  sub_mgmt_name   = local.sub_mgmt_exists ? "" : try(local.var_sub_mgmt.name, "subnet-mgmt")
  sub_mgmt_prefix = local.sub_mgmt_exists ? "" : try(local.var_sub_mgmt.prefix, "10.0.1.0/24")

  # Management NSG
  var_sub_mgmt_nsg         = try(local.var_sub_mgmt.nsg, {})
  sub_mgmt_nsg_exists      = try(local.var_sub_mgmt_nsg.is_existing, false)
  sub_mgmt_nsg_arm_id      = local.sub_mgmt_nsg_exists ? try(local.var_sub_mgmt_nsg.arm_id, "") : ""
  sub_mgmt_nsg_name        = local.sub_mgmt_nsg_exists ? "" : try(local.var_sub_mgmt_nsg.name, "nsg-mgmt")
  sub_mgmt_nsg_allowed_ips = local.sub_mgmt_nsg_exists ? [] : try(local.var_sub_mgmt_nsg.allowed_ips, [])

  # SAP vnet
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_exists = try(local.var_vnet_sap.is_existing, false)
  vnet_sap_arm_id = local.vnet_sap_exists ? try(local.var_vnet_sap.arm_id, "") : ""
  vnet_sap_name   = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.name, "vnet-sap")
  vnet_sap_addr   = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.address_space, "10.1.0.0/16")

  # Admin subnet
  var_sub_admin    = try(local.var_vnet_sap.subnet_admin, {})
  sub_admin_exists = try(local.var_sub_admin.is_existing, false)
  sub_admin_arm_id = local.sub_admin_exists ? try(local.var_sub_admin.arm_id, "") : ""
  sub_admin_name   = local.sub_admin_exists ? "" : try(local.var_sub_admin.name, "subnet-admin")
  sub_admin_prefix = local.sub_admin_exists ? "" : try(local.var_sub_admin.prefix, "10.1.1.0/24")

  # Admin NSG
  var_sub_admin_nsg    = try(local.var_sub_admin.nsg, {})
  sub_admin_nsg_exists = try(local.var_sub_admin_nsg.is_existing, false)
  sub_admin_nsg_arm_id = local.sub_admin_nsg_exists ? try(local.var_sub_admin_nsg.arm_id, "") : ""
  sub_admin_nsg_name   = local.sub_admin_nsg_exists ? "" : try(local.var_sub_admin_nsg.name, "nsg-admin")

  # DB subnet
  var_sub_db    = try(local.var_vnet_sap.subnet_db, {})
  sub_db_exists = try(local.var_sub_db.is_existing, false)
  sub_db_arm_id = local.sub_db_exists ? try(local.var_sub_db.arm_id, "") : ""
  sub_db_name   = local.sub_db_exists ? "" : try(local.var_sub_db.name, "subnet-db")
  sub_db_prefix = local.sub_db_exists ? "" : try(local.var_sub_db.prefix, "10.1.2.0/24")

  # DB NSG
  var_sub_db_nsg    = try(local.var_sub_db.nsg, {})
  sub_db_nsg_exists = try(local.var_sub_db_nsg.is_existing, false)
  sub_db_nsg_arm_id = local.sub_db_nsg_exists ? try(local.var_sub_db_nsg.arm_id, "") : ""
  sub_db_nsg_name   = local.sub_db_nsg_exists ? "" : try(local.var_sub_db_nsg.name, "nsg-db")

  # iSCSI subnet
  var_sub_iscsi    = try(local.var_vnet_sap.subnet_iscsi, {})
  sub_iscsi_exists = try(local.var_sub_iscsi.is_existing, false)
  sub_iscsi_arm_id = local.sub_iscsi_exists ? try(local.var_sub_iscsi.arm_id, "") : ""
  sub_iscsi_name   = local.sub_iscsi_exists ? "" : try(local.var_sub_iscsi.name, "subnet-iscsi")
  sub_iscsi_prefix = local.sub_iscsi_exists ? "" : try(local.var_sub_iscsi.prefix, "10.1.3.0/24")

  # iSCSI NSG
  var_sub_iscsi_nsg    = try(local.var_sub_iscsi.nsg, {})
  sub_iscsi_nsg_exists = try(local.var_sub_iscsi_nsg.is_existing, false)
  sub_iscsi_nsg_arm_id = local.sub_iscsi_nsg_exists ? try(local.var_sub_iscsi_nsg.arm_id, "") : ""
  sub_iscsi_nsg_name   = local.sub_iscsi_nsg_exists ? "" : try(local.var_sub_iscsi_nsg.name, "nsg-iscsi")

  # APP subnet
  var_sub_app    = try(local.var_vnet_sap.subnet_app, {})
  sub_app_exists = try(local.var_sub_app.is_existing, false)
  sub_app_arm_id = local.sub_app_exists ? try(local.var_sub_app.arm_id, "") : ""
  sub_app_name   = local.sub_app_exists ? "" : try(local.var_sub_app.name, "subnet-app")
  sub_app_prefix = local.sub_app_exists ? "" : try(local.var_sub_app.prefix, "10.1.4.0/24")

  # APP NSG
  var_sub_app_nsg    = try(local.var_sub_app.nsg, {})
  sub_app_nsg_exists = try(local.var_sub_app_nsg.is_existing, false)
  sub_app_nsg_arm_id = local.sub_app_nsg_exists ? try(local.var_sub_app_nsg.arm_id, "") : ""
  sub_app_nsg_name   = local.sub_app_nsg_exists ? "" : try(local.var_sub_app_nsg.name, "nsg-app")

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
      management = {
        is_existing   = local.vnet_mgmt_exists,
        arm_id        = local.vnet_mgmt_arm_id,
        name          = local.vnet_mgmt_name,
        address_space = local.vnet_mgmt_addr,
        subnet_mgmt = {
          is_existing = local.sub_mgmt_exists,
          arm_id      = local.sub_mgmt_arm_id,
          name        = local.sub_mgmt_name,
          prefix      = local.sub_mgmt_prefix,
          nsg = {
            is_existing = local.sub_mgmt_nsg_exists,
            arm_id      = local.sub_mgmt_nsg_arm_id,
            name        = local.sub_mgmt_nsg_name,
            allowed_ips = local.sub_mgmt_nsg_allowed_ips
          }
        }
      },
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

  # Storage account for sapbits
  sa_sapbits_exists           = try(var.software.storage_account_sapbits.is_existing, false)
  sa_account_tier             = local.sa_sapbits_exists ? "" : try(var.software.storage_account_sapbits.account_tier, "Premium")
  sa_account_replication_type = local.sa_sapbits_exists ? "" : try(var.software.storage_account_sapbits.account_replication_type, "LRS")
  sa_account_kind             = local.sa_sapbits_exists ? "" : try(var.software.storage_account_sapbits.account_kind, "FileStorage")
  sa_file_share_name          = "bits"
  sa_blob_container_name      = "null"
  sa_container_access_type    = "blob"
  sa_name                     = local.sa_sapbits_exists ? try(var.software.storage_account_sapbits.Storage_account_name, "") : "sapbits${random_id.random-id.hex}"
  sa_key                      = local.sa_sapbits_exists ? try(var.software.storage_account_sapbits.Storage_access_key, "") : ""
  sa_arm_id                   = local.sa_sapbits_exists ? try(var.software.storage_account_sapbits.arm_id, "") : ""

  # Downloader
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
    storage_account_sapbits = {
      is_existing              = local.sa_sapbits_exists,
      account_tier             = local.sa_account_tier,
      account_replication_type = local.sa_account_replication_type,
      account_kind             = local.sa_account_kind,
      file_share_name          = local.sa_file_share_name,
      blob_container_name      = local.sa_blob_container_name,
      Storage_account_name     = local.sa_name,
      Storage_access_key       = local.sa_key,
      arm_id                   = local.sa_arm_id
    },
    downloader = local.downloader
  })
}
