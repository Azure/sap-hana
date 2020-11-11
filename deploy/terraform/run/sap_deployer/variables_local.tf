locals {
  environment = lower(try(var.infrastructure.environment, ""))
  location    = try(var.infrastructure.region, "")
  codename    = lower(try(var.infrastructure.codename, ""))

  // Management vnet
  vnet_mgmt        = try(var.infrastructure.vnets.management, {})
  vnet_mgmt_arm_id = try(local.vnet_mgmt.arm_id, "")
  vnet_mgmt_exists = length(local.vnet_mgmt_arm_id) > 0 ? true : false

  //There is no default as the name is mandatory unless arm_id is specified
  vnet_mgmt_name = local.vnet_mgmt_exists ? split("/", local.vnet_mgmt_arm_id)[8] : try(local.vnet_mgmt.name, "DEP00")

  // Default naming of vnet has multiple parts. Taking the second-last part as the name incase the name ends with -vnet
  vnet_mgmt_parts     = length(split("-", local.vnet_mgmt_name))
  vnet_mgmt_name_part = try(substr(upper(local.vnet_mgmt_name), -5, 5), "") == "-VNET" ? substr(split("-", local.vnet_mgmt_name)[(local.vnet_mgmt_parts - 2)], 0, 7) : local.vnet_mgmt_name

  deployer_vm_count = length(var.deployers)
}
