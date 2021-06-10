
locals {
  infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = coalesce(var.location, try(var.infrastructure.region, ""))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))
    resource_group = {
      name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
      arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
    }
    vnets = {
      sap = {
        name          = try(coalesce(var.sap_network_name, try(var.infrastructure.vnets.sap.name, "")), "")
        arm_id        = try(coalesce(var.sap_network_arm_id, try(var.infrastructure.vnets.sap.arm_id, "")), "")
        address_space = try(coalesce(var.sap_network_address_space, try(var.infrastructure.vnets.sap.address_space, "")), "")
        subnet_admin = {
          name   = try(coalesce(var.sap_admin_subnet_name, try(var.infrastructure.vnets.sap.subnet_admin.name, "")), "")
          arm_id = try(coalesce(var.sap_admin_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_admin.arm_id, "")), "")
          prefix = try(coalesce(var.sap_admin_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")), "")
          nsg = {
            name   = try(coalesce(var.sap_admin_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")), "")
            arm_id = try(coalesce(var.sap_admin_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, "")), "")
          }
        }
        subnet_db = {
          name   = try(coalesce(var.sap_db_subnet_name, try(var.infrastructure.vnets.sap.subnet_db.name, "")), "")
          arm_id = try(coalesce(var.sap_db_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_db.arm_id, "")), "")
          prefix = try(coalesce(var.sap_db_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_db.prefix, "")), "")
          nsg = {
            name   = try(coalesce(var.sap_db_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")), "")
            arm_id = try(coalesce(var.sap_db_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, "")), "")
          }
        }
        subnet_app = {
          name   = try(coalesce(var.sap_app_subnet_name, try(var.infrastructure.vnets.sap.subnet_app.name, "")), "")
          arm_id = try(coalesce(var.sap_app_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_app.arm_id, "")), "")
          prefix = try(coalesce(var.sap_app_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_app.prefix, "")), "")
          nsg = {
            name   = try(coalesce(var.sap_app_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")), "")
            arm_id = try(coalesce(var.sap_app_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, "")), "")
          }
        }
        subnet_web = {
          name   = try(coalesce(var.sap_web_subnet_name, try(var.infrastructure.vnets.sap.subnet_web.name, "")), "")
          arm_id = try(coalesce(var.sap_web_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_web.arm_id, "")), "")
          prefix = try(coalesce(var.sap_web_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_web.prefix, "")), "")
          nsg = {
            name   = try(coalesce(var.sap_web_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")), "")
            arm_id = try(coalesce(var.sap_web_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, "")), "")
          }
        }
        subnet_iscsi = {
          name   = try(coalesce(var.sap_iscsi_subnet_name, try(var.infrastructure.vnets.sap.subnet_iscsi.name, "")), "")
          arm_id = try(coalesce(var.sap_iscsi_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, "")), "")
          prefix = try(coalesce(var.sap_iscsi_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_iscsi.prefix, "")), "")
          nsg = {
            name   = try(coalesce(var.sap_iscsi_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.name, "")), "")
            arm_id = try(coalesce(var.sap_iscsi_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.arm_id, "")), "")
          }
        }

      }
    }
    iscsi = {
      iscsi_count = max(var.iscsi_count, try(var.infrastructure.iscsi.iscsi_count, 0))
      use_DHCP    = try(coalesce(var.iscsi_useDHCP, try(var.infrastructure.iscsi.use_DHCP, false)), "")
      size        = try(coalesce(var.iscsi_size, try(var.infrastructure.iscsi.size, "Standard_D2s_v3")), "Standard_D2s_v3")
      os = {
        source_image_id = try(coalesce(var.iscsi_image.source_image_id, try(var.infrastructure.iscsi.os.source_image_id, "")), "")
        publisher       = try(coalesce(var.iscsi_image.publisher, try(var.infrastructure.iscsi.os.publisher, "")), "")
        offer           = try(coalesce(var.iscsi_image.offer, try(var.infrastructure.iscsi.os.offer, "")), "")
        sku             = try(coalesce(var.iscsi_image.sku, try(var.infrastructure.iscsi.os.sku, "")), "")
        version         = try(coalesce(var.iscsi_image.version, try(var.infrastructure.iscsi.sku, "")), "")
      }

      authentication = {
        type     = try(coalesce(var.iscsi_authentication_type, try(var.infrastructure.iscsi.authentication.type, "key")), "key")
        username = try(coalesce(var.iscsi_authentication_username, try(var.authentication.username, "azureadm")), "azureadm")
      }
    },

  }
  authentication = {
    username            = try(coalesce(var.automation_username, try(var.authentication.username, "azureadm")), "azureadm")
    password            = try(coalesce(var.automation_password, try(var.authentication.password, "")), "")
    path_to_public_key  = try(coalesce(var.automation_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
    path_to_private_key = try(coalesce(var.automation_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")

  }
  options = {

  }
  key_vault = {
    kv_user_id = try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "")
    kv_prvt_id = try(coalesce(var.automation_keyvault_id, try(var.key_vault.kv_prvt_id, "")), "")
    kv_prvt_id = try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "")

  }
  diagnostics_storage_account = {
    arm_id = try(coalesce(var.diagnostics_storage_account_arm_id, try(var.diagnostics_storage_account.arm_id, "")), "")
  }
  witness_storage_account = {
    arm_id = try(coalesce(var.witness_storage_account_arm_id, try(var.witness_storage_account.arm_id, "")), "")
  }

}
