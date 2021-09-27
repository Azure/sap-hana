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

variable "naming" {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

variable "deployment" {
  description = "The type of deployment"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""

}

variable "enable_purge_control_for_keyvaults" {
  description = "Allow the deployment to control the purge protection"
}

variable "anf_transport_volume_size" {
  description = "The volume size in GB for shared"
}

variable "anf_sapmnt_volume_size" {
  description = "The volume size in GB for sapmnt"
}

variable "use_ANF" {
  default = false
}

locals {
  // Resources naming
  vnet_prefix                 = trimspace(var.naming.prefix.VNET)
  sid_keyvault_names          = var.naming.keyvault_names.SDU
  anchor_virtualmachine_names = var.naming.virtualmachine_names.ANCHOR_VMNAME
  anchor_computer_names       = var.naming.virtualmachine_names.ANCHOR_COMPUTERNAME
  resource_suffixes           = var.naming.resource_suffixes
  //Region and metadata
  region    = var.infrastructure.region
  sid       = upper(var.application.sid)
  prefix    = length(try(var.infrastructure.resource_group.name, "")) > 0 ? var.infrastructure.resource_group.name : trimspace(var.naming.prefix.SDU)
  rg_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  // Resource group
  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    length(try(var.infrastructure.resource_group.name, "")) > 0 ? var.infrastructure.resource_group.name : try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))

  )

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

  //Flag to control if nsg is creates in virtual network resource group
  nsg_asg_with_vnet = var.options.nsg_asg_with_vnet

  // Retrieve information about Deployer from tfstate file
  deployer_tfstate = var.deployer_tfstate

  storageaccount_name    = try(var.landscape_tfstate.storageaccount_name, "")
  storageaccount_rg_name = try(var.landscape_tfstate.storageaccount_rg_name, "")
  // Retrieve information about Sap Landscape from tfstate file
  landscape_tfstate = var.landscape_tfstate

  iscsi_private_ip = try(local.landscape_tfstate.iscsi_private_ip, [])

  // Firewall routing logic
  // If the environment deployment created a route table use it to populate a route

  route_table_id   = try(var.landscape_tfstate.route_table_id, "")
  route_table_name = try(split("/", var.landscape_tfstate.route_table_id)[8], "")

  firewall_ip = try(var.deployer_tfstate.firewall_ip, "")

  // Firewall
  firewall_id     = try(var.deployer_tfstate.firewall_id, "")
  firewall_exists = length(local.firewall_id) > 0
  firewall_name   = local.firewall_exists ? try(split("/", local.firewall_id)[8], "") : ""
  firewall_rgname = local.firewall_exists ? try(split("/", local.firewall_id)[4], "") : ""

  firewall_service_tags = format("AzureCloud.%s", local.region)

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
    "publisher"       = try(local.db.os.publisher, local.db_custom_image ? "" : "SUSE")
    "offer"           = try(local.db.os.offer, local.db_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(local.db.os.sku, local.db_custom_image ? "" : "gen1")
    "version"         = try(local.db.os.version, local.db_custom_image ? "" : "latest")
  }

  db_ostype = upper(try(local.db.os.os_type, "LINUX"))

  db_auth = try(local.db.authentication,
    {
      "type" = "key"
  })

  //Enable DB deployment 
  hdb_list = [
    for db in var.databases : db
    if contains(["HANA"], upper(try(db.platform, "NONE")))
  ]

  enable_hdb_deployment = (length(local.hdb_list) > 0) ? true : false

  default_filepath = local.enable_hdb_deployment ? (
    format("%s%s", path.module, "/../../../../../configs/hdb_sizes.json")) : (
    format("%s%s", path.module, "/../../../../../configs/anydb_sizes.json")
  )

  custom_sizing = length(var.custom_disk_sizes_filename) > 0

  // Imports database sizing information
  file_name = local.custom_sizing ? (
    fileexists(var.custom_disk_sizes_filename) ? (
      var.custom_disk_sizes_filename) : (
      format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
    )) : (
    local.default_filepath

  )


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

  sizes = jsondecode(file(local.file_name))

  db_sizing = local.enable_sid_deployment ? lookup(local.sizes.db, var.databases[0].size).storage : []

  enable_ultradisk = try(
    compact(
      [
        for storage in local.db_sizing : storage.disk_type == "UltraSSD_LRS" ? true : ""
      ]
    )[0],
    false
  )
  //ANF support
  use_ANF = try(local.db.use_ANF, false)
  //Scalout subnet is needed if ANF is used and there are more than one hana node 
  dbnode_per_site       = length(try(local.db.dbnodes, [{}]))
  enable_storage_subnet = local.use_ANF && local.dbnode_per_site > 1

  var_infra = try(var.infrastructure, {})

  //Anchor VM
  deploy_anchor               = try(var.infrastructure.anchor_vms.deploy, false)
  anchor_size                 = try(var.infrastructure.anchor_vms.sku, "")
  anchor_auth_type            = try(var.infrastructure.anchor_vms.authentication.type, "key")
  enable_anchor_auth_password = local.deploy_anchor && local.anchor_auth_type == "password"
  enable_anchor_auth_key      = !local.enable_anchor_auth_password

  //If the db uses ultra disks ensure that the anchore sets the ultradisk flag but only for the zones that will contain db servers
  enable_anchor_ultra = [
    for zone in local.zones :
    contains(local.db_list[0].zones, zone) ? local.enable_ultradisk : false
  ]

  anchor_custom_image = length(try(var.infrastructure.anchor_vms.os.source_image_id, "")) > 0

  anchor_os = local.deploy_anchor ? (
    {
      "source_image_id" = local.anchor_custom_image ? var.infrastructure.anchor_vms.os.source_image_id : ""
      "publisher"       = try(var.infrastructure.anchor_vms.os.publisher, local.anchor_custom_image ? "" : local.db_os.publisher)
      "offer"           = try(var.infrastructure.anchor_vms.os.offer, local.anchor_custom_image ? "" : local.db_os.offer)
      "sku"             = try(var.infrastructure.anchor_vms.os.sku, local.anchor_custom_image ? "" : local.db_os.sku)
      "version"         = try(var.infrastructure.anchor_vms.os.version, local.anchor_custom_image ? "" : local.db_os.version)
    }) : (
    null
  )

  anchor_ostype = upper(try(var.infrastructure.anchor_vms.os.os_type, local.db_ostype))
  // Support dynamic addressing
  anchor_use_DHCP = try(var.infrastructure.anchor_vms.use_DHCP, false)

  //PPG
  var_ppg     = try(local.var_infra.ppg, {})
  ppg_arm_ids = try(local.var_ppg.arm_ids, [])
  ppg_exists  = length(local.ppg_arm_ids) > 0 ? true : false
  ppg_names   = try(local.var_ppg.names, [format("%s%s", local.prefix, local.resource_suffixes.ppg)])

  /* Comment out code with users.object_id for the time being
  // Additional users add to user KV
  kv_users = var.deployer_user
  */

  //SAP vnet
  vnet_sap_arm_id              = try(var.landscape_tfstate.vnet_sap_arm_id, "")
  vnet_sap_name                = split("/", local.vnet_sap_arm_id)[8]
  vnet_sap_resource_group_name = split("/", local.vnet_sap_arm_id)[4]

  vnet_sap                         = data.azurerm_virtual_network.vnet_sap
  vnet_sap_resource_group_location = try(local.vnet_sap.location, local.region)
  vnet_sap_addr                    = local.vnet_sap.address_space
  var_vnet_sap                     = try(local.var_infra.vnets.sap, {})

  //Admin subnet
  enable_admin_subnet = try(var.application.dual_nics, false) || try(var.databases[0].dual_nics, false) || (try(upper(local.db.platform), "NONE") == "HANA")

  sub_admin_defined = length(try(var.infrastructure.vnets.sap.subnet_admin, {})) > 0
  sub_admin_arm_id  = try(var.infrastructure.vnets.sap.subnet_admin.arm_id, try(var.landscape_tfstate.admin_subnet_id, ""))
  sub_admin_exists  = length(local.sub_admin_arm_id) > 0

  sub_admin_name = local.sub_admin_exists ? (
    try(split("/", var.infrastructure.vnets.sap.subnet_admin.arm_id)[10], "")) : (
    length(var.infrastructure.vnets.sap.subnet_admin.name) > 0 ? (
      var.infrastructure.vnets.sap.subnet_admin.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.admin_subnet)
    )
  )
  sub_admin_prefix = local.sub_admin_defined ? try(var.infrastructure.vnets.sap.subnet_admin.prefix, "") : ""

  sub_db_defined = length(try(var.infrastructure.vnets.sap.subnet_db, {})) > 0
  sub_db_arm_id  = try(var.infrastructure.vnets.sap.subnet_db.arm_id, try(var.landscape_tfstate.db_subnet_id, ""))
  sub_db_exists  = length(local.sub_db_arm_id) > 0
  sub_db_name = local.sub_db_exists ? (
    try(split("/", var.infrastructure.vnets.sap.subnet_db.arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_db.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_db.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_subnet)
    )
  )
  sub_db_prefix = local.sub_db_defined ? try(var.infrastructure.vnets.sap.subnet_db.prefix, "") : ""

  //APP subnet
  sub_app_defined = length(try(var.infrastructure.vnets.sap.subnet_app, {})) > 0
  sub_app_arm_id  = try(var.infrastructure.vnets.sap.subnet_app.arm_id, try(var.landscape_tfstate.app_subnet_id, ""))
  sub_app_exists  = length(local.sub_app_arm_id) > 0
  sub_app_name = local.sub_app_exists ? (
    try(split("/", var.infrastructure.vnets.sap.subnet_app.arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_app.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_app.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_subnet)
    )

  )
  sub_app_prefix = local.sub_app_defined ? try(var.infrastructure.vnets.sap.subnet_app.prefix, "") : ""

  sub_admin_nsg_arm_id = try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, try(var.landscape_tfstate.admin_nsg_id, ""))
  sub_admin_nsg_exists = length(local.sub_admin_nsg_arm_id) > 0
  sub_admin_nsg_name = local.sub_admin_nsg_exists ? (
    try(split("/", local.sub_admin_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_admin.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.admin_subnet_nsg)
    )
  )

  sub_db_nsg_arm_id = try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, try(var.landscape_tfstate.db_nsg_id, ""))
  sub_db_nsg_exists = length(local.sub_db_nsg_arm_id) > 0
  sub_db_nsg_name = local.sub_db_nsg_exists ? (
    try(split("/", local.sub_db_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_db.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_subnet_nsg)
    )
  )

  sub_app_nsg_arm_id = try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, try(var.landscape_tfstate.app_nsg_id, ""))
  sub_app_nsg_exists = length(local.sub_app_nsg_arm_id) > 0
  sub_app_nsg_name = local.sub_app_nsg_exists ? (
    try(split("/", local.sub_app_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_app.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_subnet_nsg)
    )
  )

  //Storage subnet

  sub_storage_defined = (length(try(var.infrastructure.vnets.sap.subnet_storage.arm_id, "")) + length(try(var.infrastructure.vnets.sap.subnet_storage.prefix, ""))) > 0
  sub_storage_arm_id  = try(var.infrastructure.vnets.sap.subnet_storage.arm_id, "")
  sub_storage_exists  = length(local.sub_storage_arm_id) > 0
  sub_storage_name = local.sub_storage_exists ? (
    try(split("/", local.sub_storage_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_storage.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_storage.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.storage_subnet)
    )

  )
  sub_storage_prefix = local.sub_storage_defined ? try(var.infrastructure.vnets.sap.subnet_storage.prefix, "") : ""

  //Storage NSG
  sub_storage_nsg_exists = length(try(var.infrastructure.vnets.sap.subnet_storage.nsg.arm_id, "")) > 0
  sub_storage_nsg_name = local.sub_storage_nsg_exists ? (
    try(split("/", var.infrastructure.vnets.sap.subnet_storage.nsg.arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_storage.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_storage.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.storage_subnet_nsg)
    )
  )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of using the landscape key vault
  user_key_vault_id = length(try(var.key_vault.kv_user_id, "")) > 0 ? var.key_vault.kv_user_id : local.landscape_tfstate.landscape_key_vault_user_arm_id
  prvt_key_vault_id = length(try(var.key_vault.kv_prvt_id, "")) > 0 ? var.key_vault.kv_prvt_id : local.landscape_tfstate.landscape_key_vault_private_arm_id


  // Extract information from the specified key vault arm ids
  user_kv_name    = length(local.user_key_vault_id) > 0 ? split("/", local.user_key_vault_id)[8] : local.sid_keyvault_names.user_access
  user_kv_rg_name = length(local.user_key_vault_id) > 0 ? split("/", local.user_key_vault_id)[4] : local.rg_name

  prvt_kv_name    = length(local.prvt_key_vault_id) > 0 ? split("/", local.prvt_key_vault_id)[8] : local.sid_keyvault_names.private_access
  prvt_kv_rg_name = length(local.prvt_key_vault_id) > 0 ? split("/", local.prvt_key_vault_id)[4] : local.rg_name

  use_local_credentials = length(var.authentication) > 0

  // If local credentials are used then try the parameter file.
  // If the username is empty retrieve it from the keyvault
  // If password or sshkeys are empty create them
  sid_auth_username = coalesce(
    try(var.authentication.username, ""),
    try(data.azurerm_key_vault_secret.sid_username[0].value, "azureadm")
  )

  sid_auth_password = coalesce(
    try(var.authentication.password, ""),
    try(data.azurerm_key_vault_secret.sid_password[0].value, local.use_local_credentials ? random_password.password[0].result : "")
  )

  sid_public_key = local.use_local_credentials ? (
    try(file(var.authentication.path_to_public_key), tls_private_key.sdu[0].public_key_openssh)) : (
    data.azurerm_key_vault_secret.sid_pk[0].value
  )
  sid_private_key = local.use_local_credentials ? (
    try(file(var.authentication.path_to_private_key), tls_private_key.sdu[0].private_key_pem)) : (
    ""
  )

  password_required = try(var.databases[0].authentication.type, "key") == "password" || try(var.application.authentication.type, "key") == "password"

  // Current service principal
  service_principal = try(var.service_principal, {})

  ANF_pool_settings = var.use_ANF ? (
    try(var.landscape_tfstate.ANF_pool_settings, { use_ANF = false })
    ) : (
    { use_ANF = false }
  )

}

locals {
  // 'Cg==` is empty string, base64 encoded.
  cloudinit_growpart_config = null # This needs more though as changing of it is a destructive action try(data.template_cloudinit_config.config_growpart.rendered, "Cg==")
}
