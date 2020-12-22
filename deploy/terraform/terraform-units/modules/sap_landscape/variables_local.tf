/*
  Description:
  Define local variables
*/

variable "deployer_tfstate" {
  description = "Deployer remote tfstate file"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable naming {
  description = "Defines the names for the resources"
}

locals {
  // Resources naming
  vnet_prefix              = var.naming.prefix.VNET
  storageaccount_name      = var.naming.storageaccount_names.VNET
  landscape_keyvault_names = var.naming.keyvault_names.VNET
  sid_keyvault_names       = var.naming.keyvault_names.SDU
  virtualmachine_names     = var.naming.virtualmachine_names.ISCSI_COMPUTERNAME
  resource_suffixes        = var.naming.resource_suffixes
}

locals {
  var_infra = try(var.infrastructure, {})

  // Region and metadata
  region = try(local.var_infra.region, "")
  prefix = try(var.infrastructure.resource_group.name, var.naming.prefix.VNET)

  // Retrieve information about Deployer from tfstate file
  deployer_tfstate = var.deployer_tfstate
  vnet_mgmt        = local.deployer_tfstate.vnet_mgmt
  subnet_mgmt      = local.deployer_tfstate.subnet_mgmt
  nsg_mgmt         = local.deployer_tfstate.nsg_mgmt

  // Resource group
  var_rg    = try(local.var_infra.resource_group, {})
  rg_arm_id = try(local.var_rg.arm_id, "")
  rg_exists = length(local.rg_arm_id) > 0 ? true : false
  rg_name   = local.rg_exists ? try(split("/", local.rg_arm_id)[4], "") : try(local.var_rg.name, format("%s%s", local.prefix, local.resource_suffixes.vnet_rg))

  // iSCSI
  var_iscsi    = try(local.var_infra.iscsi, {})
  iscsi_count  = try(local.var_iscsi.iscsi_count, 0)
  enable_iscsi = local.iscsi_count > 0
  iscsi_size   = try(local.var_iscsi.size, "Standard_D2s_v3")

  use_DHCP = try(local.var_iscsi.use_DHCP, false)

  iscsi_os = try(local.var_iscsi.os,
    {
      "publisher" = try(local.var_iscsi.os.publisher, "SUSE")
      "offer"     = try(local.var_iscsi.os.offer, "sles-sap-12-sp5")
      "sku"       = try(local.var_iscsi.os.sku, "gen1")
      "version"   = try(local.var_iscsi.os.version, "latest")
  })
  iscsi_auth_type     = local.enable_iscsi ? try(local.var_iscsi.authentication.type, "key") : ""
  iscsi_auth_username = local.enable_iscsi ? (local.iscsi_username_exist ? data.azurerm_key_vault_secret.iscsi_username[0].value : try(local.var_iscsi.authentication.username, "azureadm")) : ""
  iscsi_nic_ips       = local.sub_iscsi_exists ? try(local.var_iscsi.iscsi_nic_ips, []) : []

  // By default, ssh key for iSCSI uses generated public key. Provide sshkey.path_to_public_key and path_to_private_key overides it
  enable_iscsi_auth_key = local.enable_iscsi && local.iscsi_auth_type == "key"
  iscsi_public_key      = local.enable_iscsi_auth_key ? (local.iscsi_key_exist ? data.azurerm_key_vault_secret.iscsi_pk[0].value : try(file(var.sshkey.path_to_public_key), tls_private_key.iscsi[0].public_key_openssh)) : null
  iscsi_private_key     = local.enable_iscsi_auth_key ? (local.iscsi_key_exist ? data.azurerm_key_vault_secret.iscsi_ppk[0].value : try(file(var.sshkey.path_to_private_key), tls_private_key.iscsi[0].private_key_pem)) : null

  // By default, authentication type of iSCSI target is ssh key pair but using username/password is a potential usecase.
  enable_iscsi_auth_password = local.enable_iscsi && local.iscsi_auth_type == "password"
  iscsi_auth_password        = local.enable_iscsi_auth_password ? (local.iscsi_pwd_exist ? data.azurerm_key_vault_secret.iscsi_password[0].value : try(local.var_iscsi.authentication.password, random_password.iscsi_password[0].result)) : null

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

  // SAP vnet
  var_vnet_sap    = try(local.var_infra.vnets.sap, {})
  vnet_sap_arm_id = try(local.var_vnet_sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0 ? true : false
  vnet_sap_name   = local.vnet_sap_exists ? try(split("/", local.vnet_sap_arm_id)[8], "") : try(local.var_vnet_sap.name, format("%s%s", local.vnet_prefix, local.resource_suffixes.vnet))
  vnet_sap_addr   = local.vnet_sap_exists ? "" : try(local.var_vnet_sap.address_space, "")

  // By default, Ansible ssh key for SID uses generated public key. Provide sshkey.path_to_public_key and path_to_private_key overides it
  enable_landscape_kv = true
  sid_public_key      = local.enable_landscape_kv ? (local.sid_key_exist ? data.azurerm_key_vault_secret.sid_pk[0].value : try(file(var.sshkey.path_to_public_key), tls_private_key.sid[0].public_key_openssh)) : null
  sid_private_key     = local.enable_landscape_kv ? (local.sid_key_exist ? data.azurerm_key_vault_secret.sid_ppk[0].value : try(file(var.sshkey.path_to_private_key), tls_private_key.sid[0].private_key_pem)) : null

  // iSCSI subnet
  var_sub_iscsi    = try(local.var_vnet_sap.subnet_iscsi, null)
  enable_sub_iscsi = local.var_sub_iscsi != null
  sub_iscsi_arm_id = try(local.var_sub_iscsi.arm_id, "")
  sub_iscsi_exists = length(local.sub_iscsi_arm_id) > 0
  sub_iscsi_name = local.sub_iscsi_exists ? (
    try(split("/", local.sub_iscsi_arm_id)[10], "")) : (
    try(local.var_sub_iscsi.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.iscsi_subnet))
  )
  sub_iscsi_prefix = local.sub_iscsi_exists ? "" : try(local.var_sub_iscsi.prefix, "")

  // iSCSI NSG
  var_sub_iscsi_nsg    = try(local.var_sub_iscsi.nsg, {})
  sub_iscsi_nsg_arm_id = try(local.var_sub_iscsi_nsg.arm_id, "")
  sub_iscsi_nsg_exists = length(local.sub_iscsi_nsg_arm_id) > 0
  sub_iscsi_nsg_name = local.sub_iscsi_nsg_exists ? (
    try(split("/", local.sub_iscsi_nsg_arm_id)[8], "")) : (
    try(local.var_sub_iscsi_nsg.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.iscsi_subnet_nsg))
  )

  // Update infrastructure with defaults
  infrastructure = {
    resource_group = {
      is_existing = local.rg_exists,
      name        = local.rg_name,
      arm_id      = local.rg_arm_id
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
        }
      }
    }
  }

  // Current service principal
  service_principal = try(var.service_principal, {})

  full_iscsiserver_names = flatten([for vm in local.virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults
  user_key_vault_id = try(var.key_vault.kv_user_id, "")
  prvt_key_vault_id = try(var.key_vault.kv_prvt_id, "")
  user_kv_exist     = try(length(local.user_key_vault_id) > 0, false)
  prvt_kv_exist     = try(length(local.prvt_key_vault_id) > 0, false)

  // If the user specifies the secret name of key pair/password in input, the secrets will be imported instead of creating new secrets
  input_sid_public_key_secret_name  = try(var.key_vault.kv_sid_sshkey_pub, "")
  input_sid_private_key_secret_name = try(var.key_vault.kv_sid_sshkey_prvt, "")
  sid_key_exist                     = try(length(local.input_sid_public_key_secret_name) > 0, false)

  input_iscsi_public_key_secret_name  = try(var.key_vault.kv_iscsi_sshkey_pub, "")
  input_iscsi_private_key_secret_name = try(var.key_vault.kv_iscsi_sshkey_prvt, "")
  input_iscsi_password_secret_name    = try(var.key_vault.kv_iscsi_pwd, "")
  input_iscsi_username_secret_name    = try(var.key_vault.kv_iscsi_username, "")
  iscsi_key_exist                     = try(length(local.input_iscsi_public_key_secret_name) > 0, false)
  iscsi_pwd_exist                     = try(length(local.input_iscsi_password_secret_name) > 0, false)
  iscsi_username_exist                = try(length(local.input_iscsi_username_secret_name) > 0, false)

  sid_ppk_name = local.sid_key_exist ? local.input_sid_private_key_secret_name : format("%s-sid-sshkey", local.prefix)
  sid_pk_name  = local.sid_key_exist ? local.input_sid_public_key_secret_name : format("%s-sid-sshkey-pub", local.prefix)

  iscsi_ppk_name      = local.iscsi_key_exist ? local.input_iscsi_private_key_secret_name : format("%s-iscsi-sshkey", local.prefix)
  iscsi_pk_name       = local.iscsi_key_exist ? local.input_iscsi_public_key_secret_name : format("%s-iscsi-sshkey-pub", local.prefix)
  iscsi_pwd_name      = local.iscsi_pwd_exist ? local.input_iscsi_password_secret_name : format("%s-iscsi-password", local.prefix)
  iscsi_username_name = local.iscsi_username_exist ? local.input_iscsi_username_secret_name : format("%s-iscsi-username", local.prefix)

  // Extract information from the specified key vault arm ids
  user_kv_name    = local.user_kv_exist ? split("/", local.user_key_vault_id)[8] : local.landscape_keyvault_names.user_access
  user_kv_rg_name = local.user_kv_exist ? split("/", local.user_key_vault_id)[4] : ""

  prvt_kv_name    = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[8] : local.landscape_keyvault_names.private_access
  prvt_kv_rg_name = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[4] : ""

}
