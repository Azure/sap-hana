
locals {

  subnet_mgmt_defined     = (length(var.management_subnet_address_prefix) + length(try(var.infrastructure.vnets.management.subnet_mgmt.prefix, "")) + length(var.management_subnet_arm_id) + length(try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, ""))) > 0
  subnet_mgmt_nsg_defined = (length(var.management_subnet_nsg_name) + length(try(var.infrastructure.vnets.management.subnet_mgmt.nsg.name, "")) + length(var.management_subnet_nsg_arm_id) + length(try(var.infrastructure.vnets.management.subnet_mgmt.nsg.arm_id, ""))) + length(var.management_subnet_nsg_allowed_ips) + length(try(var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips, [])) > 0

  infrastructure_temp = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = coalesce(var.location, try(var.infrastructure.region, ""))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))
  }

  deployers = [
    {
      size      = try(coalesce(var.vm_size, try(var.deployers[0].size, "")), "")
      disk_type = try(coalesce(var.vm_disk_type, try(var.deployers[0].disk_type, "")), "")
      use_DHCP  = try(coalesce(var.use_DHCP, try(var.deployers[0].use_DHCP, false)), "")
      authentication = {
        type = try(coalesce(var.vm_authentication_type, try(var.deployers[0].authentication.type, "")), "")
      }
      os = {
        source_image_id = try(coalesce(var.vm_image.source_image_id, try(var.deployers[0].os.source_image_id, "")), "")
        publisher       = try(coalesce(var.vm_image.publisher, try(var.deployers[0].os.publisher, "")), "")
        offer           = try(coalesce(var.vm_image.offer, try(var.deployers[0].os.offer, "")), "")
        sku             = try(coalesce(var.vm_image.sku, try(var.deployers[0].os.sku, "")), "")
        version         = try(coalesce(var.vm_image.version, try(var.deployers[0].version, "")), "latest")
      }
      private_ip_address = try(coalesce(var.private_ip_address, var.deployers[0].private_ip_address), "")
    }
  ]
  authentication = {
    username            = try(coalesce(var.vm_authentication_username, try(var.authentication.username, "")), "")
    password            = try(coalesce(var.vm_authentication_password, try(var.authentication.password, "")), "")
    path_to_public_key  = try(coalesce(var.vm_authentication_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
    path_to_private_key = try(coalesce(var.vm_authentication_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")

  }
  key_vault = {
    kv_user_id     = try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "")
    kv_prvt_id     = try(coalesce(var.automation_keyvault_id, try(var.key_vault.kv_prvt_id, "")), "")
    kv_sshkey_prvt = try(coalesce(var.deployer_private_key_secret_name, try(var.key_vault.kv_sshkey_prvt, "")), "")
    kv_sshkey_pub  = try(coalesce(var.deployer_public_key_secret_name, try(var.key_vault.kv_sshkey_pub, "")), "")
    kv_username    = try(coalesce(var.deployer_username_secret_name, try(var.key_vault.kv_username, "")), "")
    kv_pwd         = try(coalesce(var.deployer_password_secret_name, try(var.key_vault.kv_pwd, "")), "")

  }

  resource_group = {
    name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
    arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
  }
  resource_group_defined = (length(local.resource_group.name) + length(local.resource_group.arm_id)) > 0



  options = {
    enable_deployer_public_ip = try(coalesce(var.enable_deployer_public_ip, try(var.options.enable_deployer_public_ip, false)), "")
  }

  firewall_deployment          = try(var.firewall_deployment, false)
  firewall_rule_subnets        = try(var.firewall_rule_subnets, [])
  firewall_allowed_ipaddresses = try(var.firewall_allowed_ipaddresses, [])

  assign_subscription_permissions = try(var.assign_subscription_permissions, true)


  subnet_mgmt = merge((
    { "name" = try(coalesce(var.management_subnet_name, try(var.infrastructure.vnets.management.subnet_mgmt.name, "")), "") }), (
    { "arm_id" = try(coalesce(var.management_subnet_arm_id, try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, "")), "") }), (
    { "prefix" = try(coalesce(var.management_subnet_address_prefix, try(var.infrastructure.vnets.management.subnet_mgmt.prefix, "")), "") }), (
    { "nsg" = var.infrastructure.vnets.management.subnet_mgmt.nsg }
    # local.subnet_mgmt_nsg_defined ? ({ "nsg" = {
    #   "name"        = try(coalesce(var.management_subnet_nsg_name, try(var.infrastructure.vnets.management.subnet_mgmt.nsg.name, "")), "")
    #   "arm_id"      = try(coalesce(var.management_subnet_nsg_arm_id, try(var.infrastructure.vnets.management.subnet_mgmt.nsg.arm_id, "")), "")
    #   "allowed_ips" = try(concat(var.management_subnet_nsg_allowed_ips, try(var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips, "")), [])

    #   }
    # }) : null
    )
  )

  vnets = {
  }
  management = {
    name          = try(coalesce(var.management_network_name, try(var.infrastructure.vnets.management.name, "")), "")
    arm_id        = try(coalesce(var.management_network_arm_id, try(var.infrastructure.vnets.management.arm_id, "")), "")
    address_space = try(coalesce(var.management_network_address_space, try(var.infrastructure.vnets.management.address_space, "")), "")
  }

  subnet_fw = {
    arm_id = try(coalesce(var.management_firewall_subnet_arm_id, try(var.infrastructure.vnets.management.subnet_fw.arm_id, "")), "")
    prefix = try(coalesce(var.management_firewall_subnet_address_prefix, try(var.infrastructure.vnets.management.subnet_fw.prefix, "")), "")
  }

  all_subnets = merge(local.management, (
    local.subnet_mgmt_defined ? { "subnet_mgmt" = local.subnet_mgmt } : null), (
    local.firewall_deployment ? { "subnet_fw" = local.subnet_fw } : null
    )

  )

  temp_vnet = merge(local.vnets, { "management" = local.all_subnets })

  infrastructure = merge(local.infrastructure_temp, (
    { "vnets" = local.temp_vnet }), (
    local.resource_group_defined ? { "resource_group" = local.resource_group } : null)

  )


}
