/*
Description:

  Define local variables.
*/

// Set defaults
locals {

  // Post fix for all deployed resources
  postfix = random_id.deployer.hex

  // Default option(s):
  enable_secure_transfer = try(var.options.enable_secure_transfer, true)

  // Management vnet
  vnet_mgmt        = try(var.infrastructure.vnets.management, {})
  vnet_mgmt_exists = try(local.vnet_mgmt.is_existing, false)
  vnet_mgmt_arm_id = local.vnet_mgmt_exists ? try(local.vnet_mgmt.arm_id, "") : ""
  vnet_mgmt_name   = local.vnet_mgmt_exists ? "" : try(local.vnet_mgmt.name, "vnet-mgmt")
  vnet_mgmt_addr   = local.vnet_mgmt_exists ? "" : try(local.vnet_mgmt.address_space, "10.0.0.0/24")

  // Management subnet
  sub_mgmt          = try(local.vnet_mgmt.subnet_mgmt, {})
  sub_mgmt_exists   = try(local.sub_mgmt.is_existing, false)
  sub_mgmt_arm_id   = local.sub_mgmt_exists ? try(local.sub_mgmt.arm_id, "") : ""
  sub_mgmt_name     = local.sub_mgmt_exists ? "" : try(local.sub_mgmt.name, "subnet-mgmt")
  sub_mgmt_prefix   = local.sub_mgmt_exists ? "" : try(local.sub_mgmt.prefix, "10.0.0.16/28")
  sub_mgmt_deployed = try(local.sub_mgmt_exists ? data.azurerm_subnet.subnet-mgmt[0] : azurerm_subnet.subnet-mgmt[0], null)

  // Management NSG
  sub_mgmt_nsg             = try(local.sub_mgmt.nsg, {})
  sub_mgmt_nsg_exists      = try(local.sub_mgmt_nsg.is_existing, false)
  sub_mgmt_nsg_arm_id      = local.sub_mgmt_nsg_exists ? try(local.sub_mgmt_nsg.arm_id, "") : ""
  sub_mgmt_nsg_name        = local.sub_mgmt_nsg_exists ? "" : try(local.sub_mgmt_nsg.name, "nsg-mgmt")
  sub_mgmt_nsg_allowed_ips = local.sub_mgmt_nsg_exists ? [] : try(local.sub_mgmt_nsg.allowed_ips, ["0.0.0.0/0"])
  sub_mgmt_nsg_deployed    = try(local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg-mgmt[0] : azurerm_network_security_group.nsg-mgmt[0], null)

  // Resource group and location
  rg_name = try("${var.infrastructure.resource_group.name}-${local.postfix}", format("sapdeployer-rg-%s", local.postfix))
  region  = try(var.infrastructure.region, "westus2")

  // Deployer(s) information from input
  deployer_input = var.deployers

  // Deployer(s) information with default override
  enable_deployers = length(local.deployer_input) > 0 ? true : false
  deployers = [
    for idx, deployer in local.deployer_input : {
      "name"                 = "deployer",
      "destroy_after_deploy" = true,
      "size"                 = try(deployer.size, "Standard_D2s_v3"),
      "disk_type"            = try(deployer.disk_type, "StandardSSD_LRS")
      "os" = {
        "source_image_id" = try(deployer.os.source_image_id, "")
        "publisher"       = try(deployer.os.source_image_id, "") == "" ? "Canonical" : ""
        "offer"           = try(deployer.os.source_image_id, "") == "" ? "UbuntuServer" : ""
        "sku"             = try(deployer.os.source_image_id, "") == "" ? "18.04-LTS" : ""
        "version"         = try(deployer.os.source_image_id, "") == "" ? "latest" : ""
      },
      "authentication" = {
        "type"     = "key",
        "username" = try(deployer.authentication.username, "azureadm")
      },
      "components" = [
        "terraform",
        "ansible"
      ],
      "private_ip_address" = try(deployer.private_ip_address, cidrhost(local.sub_mgmt_deployed.address_prefixes[0], idx + 4))
    }
  ]

}
