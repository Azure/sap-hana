
locals {

  temp_infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = coalesce(var.location, try(var.infrastructure.region, ""))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))
    tags        = try(merge(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
  }


  resource_group = {
    name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
    arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
  }
  resource_group_defined = (length(local.resource_group.name) + length(local.resource_group.arm_id)) > 0

  ppg = {
    arm_ids = distinct(concat(var.proximityplacementgroup_arm_ids, try(var.infrastructure.ppg.arm_ids, [])))
    names   = distinct(concat(var.proximityplacementgroup_names, try(var.infrastructure.ppg.names, [])))
  }
  ppg_defined = (length(local.ppg.names) + length(local.ppg.arm_ids)) > 0


  deploy_anchor_vm = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0

  anchor_vms = local.deploy_anchor_vm ? ({
    deploy                 = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0
    use_DHCP               = var.anchor_vm_use_DHCP || try(var.infrastructure.anchor_vms.use_DHCP, false)
    accelerated_networking = var.anchor_vm_accelerated_networking || try(var.infrastructure.anchor_vms.accelerated_networking, false)
    sku                    = try(coalesce(var.anchor_vm_sku, try(var.infrastructure.anchor_vms.sku, "Standard_D2s_v3")), "Standard_D2s_v3")
    os = {
      os_type         = try(coalesce(var.anchor_vm_image.os_type, try(var.infrastructure.anchor_vms.os.os_type, "")), "LINUX")
      source_image_id = try(coalesce(var.anchor_vm_image.source_image_id, try(var.infrastructure.anchor_vms.os.source_image_id, "")), "")
      publisher       = try(coalesce(var.anchor_vm_image.publisher, try(var.infrastructure.anchor_vms.os.publisher, "")), "")
      offer           = try(coalesce(var.anchor_vm_image.offer, try(var.infrastructure.anchor_vms.os.offer, "")), "")
      sku             = try(coalesce(var.anchor_vm_image.sku, try(var.infrastructure.anchor_vms.os.sku, "")), "")
      version         = try(coalesce(var.anchor_vm_image.version, try(var.infrastructure.anchor_vms.version, "")), "")
    }

    authentication = {
      type     = try(coalesce(var.anchor_vm_authentication_type, try(var.infrastructure.anchor_vms.authentication.type, "key")), "key")
      username = try(coalesce(var.anchor_vm_authentication_username, try(var.authentication.username, "azureadm")), "azureadm")
    }
    nic_ips = distinct(concat(var.anchor_vm_nic_ips, try(var.infrastructure.anchor_vms.nic_ips, [])))
    }
    ) : (
    null
  )


  authentication_temp = {
  }

  options_temp = {
    enable_secure_transfer = true
    resource_offset        = max(var.resource_offset, try(var.options.resource_offset, 0))
    nsg_asg_with_vnet      = var.nsg_asg_with_vnet || try(var.options.nsg_asg_with_vnet, false)
    legacy_nic_order       = var.legacy_nic_order || try(var.options.legacy_nic_order, false)
  }

  key_vault_temp = {
  }

  db_authentication = {
    type     = try(coalesce(var.database_vm_authentication_type, try(var.databases[0].authentication.type, "")), "")
    username = try(coalesce(var.automation_username, try(var.databases[0].authentication.username, "")), "")
  }
  db_authentication_defined = (length(local.db_authentication.type) + length(local.db_authentication.username)) > 3
  avset_arm_ids             = distinct(concat(var.database_vm_avset_arm_ids, try(var.databases[0].avset_arm_ids, [])))
  db_avset_arm_ids_defined  = length(local.avset_arm_ids) > 0
  frontend_ip               = try(coalesce(var.database_loadbalancer_ip, try(var.databases[0].loadbalancer.frontend_ip, "")), "")
  db_tags                   = try(coalesce(var.database_tags, try(var.databases[0].tags, {})), {})

  databases_temp = {
    high_availability = var.database_high_availability || try(var.databases[0].high_availability, false)
    use_DHCP          = var.database_vm_use_DHCP || try(var.databases[0].use_DHCP, false)

    platform = try(coalesce(var.database_platform, try(var.databases[0].platform, "HANA")), "")
    size     = try(coalesce(var.database_size, try(var.databases[0].size, "")), "")

    use_ANF   = var.database_HANA_use_ANF_scaleout_scenario || try(var.databases[0].use_ANF, false)
    dual_nics = var.database_dual_nics || try(var.databases[0].dual_nics, false)
    no_ppg    = var.database_no_ppg || try(var.databases[0].no_ppg, false)
    no_avset  = var.database_no_avset || try(var.databases[0].no_avset, false)

  }

  dbnodes = try(compact(var.database_vm_nodes, var.databases[0].dbnodes), {})

  db_os = {
    os_type         = try(coalesce(var.database_vm_image.os_type, try(var.databases[0].os.os_type, "")), "LINUX")
    source_image_id = try(coalesce(var.database_vm_image.source_image_id, try(var.databases[0].os.source_image_id, "")), "")
    publisher       = try(coalesce(var.database_vm_image.publisher, try(var.databases[0].os.publisher, "")), "")
    offer           = try(coalesce(var.database_vm_image.offer, try(var.databases[0].os.offer, "")), "")
    sku             = try(coalesce(var.database_vm_image.sku, try(var.databases[0].os.sku, "")), "")
    version         = try(coalesce(var.database_vm_image.version, try(var.databases[0].os.version, "")), "")
  }
  db_os_specified = (length(local.db_os.source_image_id) + length(local.db_os.publisher)) > 0

  db_sid_specified = (length(var.database_sid) + length(try(var.databases[0].sid, ""))) > 0

  instance = {
    sid             = try(coalesce(var.database_sid, try(var.databases[0].sid, "")), upper(var.databases[0].platform) == "HANA" ? "hdb" : lower(substr(var.databases[0].platform, 0, 3)))
    instance_number = upper(local.databases_temp.platform) == "HANA" ? coalesce(var.database_instance_number, try(var.databases[0].instance_number, "01")) : ""
  }

  app_authentication = {
    type     = try(coalesce(var.app_tier_authentication_type, try(var.application.authentication.type, "")), "")
    username = try(coalesce(var.automation_username, try(var.application.authentication.username, "")), "")
  }
  app_authentication_defined = (length(local.app_authentication.type) + length(local.app_authentication.username)) > 3

  application_temp = {
    sid = try(coalesce(var.sid, try(var.application.sid, "")), "")

    enable_deployment = var.enable_app_tier_deployment && try(var.application.enable_deployment, true)
    use_DHCP          = var.app_tier_use_DHCP || try(var.application.use_DHCP, false)
    dual_nics         = var.app_tier_dual_nics || try(var.application.dual_nics, false)
    vm_sizing         = try(coalesce(var.app_tier_vm_sizing, try(var.application.vm_sizing, "")), "Production")

    application_server_count = max(var.application_server_count, try(var.application.application_server_count, 0))
    app_sku                  = try(coalesce(var.application_server_sku, var.application.app_sku), "")
    app_no_ppg               = var.application_server_no_ppg || try(var.application.app_no_ppg, false)
    app_no_avset             = var.application_server_no_avset || try(var.application.app_no_avset, false)

    scs_server_count      = max(var.scs_server_count, try(var.application.scs_server_count, 1))
    scs_high_availability = var.scs_high_availability || try(var.application.scs_high_availability, false)
    scs_instance_number   = try(coalesce(var.scs_instance_number, var.application.scs_instance_number), "01")
    ers_instance_number   = try(coalesce(var.ers_instance_number, var.application.ers_instance_number), "02")

    scs_sku      = try(coalesce(var.scs_server_sku, var.application.scs_sku), "")
    scs_no_ppg   = var.scs_server_no_ppg || try(var.application.scs_no_ppg, false)
    scs_no_avset = var.scs_server_no_avset || try(var.application.scs_no_avset, false)

    webdispatcher_count = max(var.webdispatcher_server_count, try(var.application.webdispatcher_count, 0))
    web_sku             = try(coalesce(var.webdispatcher_server_sku, var.application.web_sku), "")
    web_no_ppg          = var.webdispatcher_server_no_ppg || try(var.application.web_no_ppg, false)
    web_no_avset        = var.webdispatcher_server_no_avset || try(var.application.web_no_avset, false)

  }

  app_zones_temp = distinct(concat(var.application_server_zones, try(var.application.app_zones, [])))
  scs_zones_temp = distinct(concat(var.scs_server_zones, try(var.application.scs_zones, [])))
  web_zones_temp = distinct(concat(var.webdispatcher_server_zones, try(var.application.web_zones, [])))

  app_tags = try(coalesce(var.application_server_tags, try(var.application.app_tags, {})), {})
  scs_tags = try(coalesce(var.scs_server_tags, try(var.application.scs_tags, {})), {})
  web_tags = try(coalesce(var.webdispatcher_server_tags, try(var.application.web_tags, {})), {})

  app_os = {
    os_type         = try(coalesce(var.application_server_image.os_type, try(var.application.app_os.os_type, try(var.application.os.os_type, ""))), "LINUX")
    source_image_id = try(coalesce(var.application_server_image.source_image_id, try(var.application.app_os.source_image_id, try(var.application.os.source_image_id, ""))), "")
    publisher       = try(coalesce(var.application_server_image.publisher, try(var.application.app_os.publisher, try(var.application.os.publisher, ""))), "")
    offer           = try(coalesce(var.application_server_image.offer, try(var.application.app_os.offer, try(var.application.os.offer, ""))), "")
    sku             = try(coalesce(var.application_server_image.sku, try(var.application.app_os.sku, try(var.application.os.sku, ""))), "")
    version         = try(coalesce(var.application_server_image.version, try(var.application.app_os.version, try(var.application.os.version, ""))), "")
  }
  app_os_specified = (length(local.app_os.source_image_id) + length(local.app_os.publisher)) > 0

  scs_os = {
    os_type         = try(coalesce(var.scs_server_image.os_type, try(var.application.scs_os.os_type, "")), "LINUX")
    source_image_id = try(coalesce(var.scs_server_image.source_image_id, try(var.application.scs_os.source_image_id, "")), "")
    publisher       = try(coalesce(var.scs_server_image.publisher, try(var.application.scs_os.publisher, "")), "")
    offer           = try(coalesce(var.scs_server_image.offer, try(var.application.scs_os.offer, "")), "")
    sku             = try(coalesce(var.scs_server_image.sku, try(var.application.scs_os.sku, "")), "")
    version         = try(coalesce(var.scs_server_image.version, try(var.application.scs_os.version, "")), "")
  }
  scs_os_specified = (length(local.scs_os.source_image_id) + length(local.scs_os.publisher)) > 0

  web_os = {
    os_type         = try(coalesce(var.webdispatcher_server_image.os_type, try(var.application.web_os.os_type, "")), "LINUX")
    source_image_id = try(coalesce(var.webdispatcher_server_image.source_image_id, try(var.application.web_os.source_image_id, "")), "")
    publisher       = try(coalesce(var.webdispatcher_server_image.publisher, try(var.application.web_os.publisher, "")), "")
    offer           = try(coalesce(var.webdispatcher_server_image.offer, try(var.application.web_os.offer, "")), "")
    sku             = try(coalesce(var.webdispatcher_server_image.sku, try(var.application.web_os.sku, "")), "")
    version         = try(coalesce(var.webdispatcher_server_image.version, try(var.application.web_os.version, "")), "")
  }
  web_os_specified = (length(local.web_os.source_image_id) + length(local.web_os.publisher)) > 0

  vnets = {
  }

  sap = {
    name          = try(coalesce(var.network_name, try(var.infrastructure.vnets.sap.name, "")), "")
    arm_id        = try(coalesce(var.network_arm_id, try(var.infrastructure.vnets.sap.arm_id, "")), "")
    address_space = try(coalesce(var.network_address_space, try(var.infrastructure.vnets.sap.address_space, "")), "")
  }

  subnet_admin_defined     = (length(var.admin_subnet_address_prefix) + length(try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")) + length(var.admin_subnet_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))) > 0
  subnet_admin_nsg_defined = (length(var.admin_subnet_nsg_name) + length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")) + length(var.admin_subnet_nsg_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, ""))) > 0

  subnet_db_defined     = (length(var.db_subnet_address_prefix) + length(try(var.infrastructure.vnets.sap.subnet_db.prefix, "")) + length(var.db_subnet_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))) > 0
  subnet_db_nsg_defined = (length(var.db_subnet_nsg_name) + length(try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")) + length(var.db_subnet_nsg_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, ""))) > 0

  subnet_app_defined     = (length(var.app_subnet_address_prefix) + length(try(var.infrastructure.vnets.sap.subnet_app.prefix, "")) + length(var.app_subnet_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))) > 0
  subnet_app_nsg_defined = (length(var.app_subnet_nsg_name) + length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) + length(var.app_subnet_nsg_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, ""))) > 0

  subnet_web_defined     = (length(var.web_subnet_address_prefix) + length(try(var.infrastructure.vnets.sap.subnet_web.prefix, "")) + length(var.web_subnet_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, ""))) > 0
  subnet_web_nsg_defined = (length(var.web_subnet_nsg_name) + length(try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")) + length(var.web_subnet_nsg_arm_id) + length(try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, ""))) > 0


  app_nic_ips       = distinct(concat(var.application_server_app_nic_ips, try(var.application.app_nic_ips, [])))
  app_admin_nic_ips = distinct(concat(var.application_server_admin_nic_ips, try(var.application.app_admin_nic_ips, [])))
  scs_nic_ips       = distinct(concat(var.scs_server_app_nic_ips, try(var.application.scs_nic_ips, [])))
  scs_admin_nic_ips = distinct(concat(var.scs_server_admin_nic_ips, try(var.application.scs_admin_nic_ips, [])))
  scs_lb_ips        = distinct(concat(var.scs_server_loadbalancer_ips, try(var.application.scs_lb_ips, [])))
  web_nic_ips       = distinct(concat(var.webdispatcher_server_app_nic_ips, try(var.application.web_nic_ips, [])))
  web_admin_nic_ips = distinct(concat(var.webdispatcher_server_admin_nic_ips, try(var.application.web_admin_nic_ips, [])))
  web_lb_ips        = distinct(concat(var.webdispatcher_server_loadbalancer_ips, try(var.application.web_lb_ips, [])))

  subnet_admin = merge((
    { name = try(coalesce(var.admin_subnet_name, try(var.infrastructure.vnets.sap.subnet_admin.name, "")), "") }), (
    { arm_id = try(coalesce(var.admin_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_admin.arm_id, "")), "") }), (
    { prefix = try(coalesce(var.admin_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")), "") }), (
    local.subnet_admin_nsg_defined ? ({ nsg = {
      name   = try(coalesce(var.admin_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")), "")
      arm_id = try(coalesce(var.admin_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, "")), "")
      }
    }) : null
    )
  )

  subnet_db = merge((
    { name = try(coalesce(var.db_subnet_name, try(var.infrastructure.vnets.sap.subnet_db.name, "")), "") }), (
    { arm_id = try(coalesce(var.db_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_db.arm_id, "")), "") }), (
    { prefix = try(coalesce(var.db_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_db.prefix, "")), "") }), (
    local.subnet_db_nsg_defined ? ({ nsg = {
      name   = try(coalesce(var.db_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")), "")
      arm_id = try(coalesce(var.db_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, "")), "")
      }
    }) : null
    )
  )
  subnet_app = merge((
    { name = try(coalesce(var.app_subnet_name, try(var.infrastructure.vnets.sap.subnet_app.name, "")), "") }), (
    { arm_id = try(coalesce(var.app_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_app.arm_id, "")), "") }), (
    { prefix = try(coalesce(var.app_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_app.prefix, "")), "") }), (
    local.subnet_app_nsg_defined ? ({ nsg = {
      name   = try(coalesce(var.app_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")), "")
      arm_id = try(coalesce(var.app_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, "")), "")
      }
    }) : null
    )
  )
  subnet_web = merge((
    { name = try(coalesce(var.web_subnet_name, try(var.infrastructure.vnets.sap.subnet_web.name, "")), "") }), (
    { arm_id = try(coalesce(var.web_subnet_arm_id, try(var.infrastructure.vnets.sap.subnet_web.arm_id, "")), "") }), (
    { prefix = try(coalesce(var.web_subnet_address_prefix, try(var.infrastructure.vnets.sap.subnet_web.prefix, "")), "") }), (
    local.subnet_web_nsg_defined ? ({ nsg = {
      name   = try(coalesce(var.web_subnet_nsg_name, try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")), "")
      arm_id = try(coalesce(var.web_subnet_nsg_arm_id, try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, "")), "")
      }
    }) : null
    )
  )

  all_subnets = merge(local.sap, (
    local.subnet_admin_defined ? { subnet_admin = local.subnet_admin } : null), (
    local.subnet_db_defined ? { subnet_db = local.subnet_db } : null), (
    local.subnet_app_defined ? { subnet_app = local.subnet_app } : null), (
    local.subnet_web_defined ? { subnet_web = local.subnet_web } : null
    )
  )

  temp_vnet = merge(local.vnets, { sap = local.all_subnets })

  db_zones_temp = distinct(concat(var.database_vm_zones, try(var.databases[0].zones, [])))

  user_kv_specified = (length(var.user_keyvault_id) + length(try(var.key_vault.kv_user_id, ""))) > 0
  user_kv           = local.user_kv_specified ? try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "") : ""
  prvt_kv_specified = (length(var.automation_keyvault_id) + length(try(var.key_vault.kv_prvt, ""))) > 0
  prvt_kv           = local.prvt_kv_specified ? try(coalesce(var.automation_keyvault_id, try(var.key_vault.kv_prvt_id, "")), "") : ""
  spn_kv_specified  = (length(var.spn_keyvault_id) + length(try(var.key_vault.kv_spn_id, ""))) > 0
  spn_kv            = local.spn_kv_specified ? try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "") : ""

  username_specified            = (length(var.automation_username) + length(try(var.authentication.username, ""))) > 0
  username                      = try(coalesce(var.automation_username, try(var.authentication.username, "")), "")
  password_specified            = (length(var.automation_password) + length(try(var.authentication.password, ""))) > 0
  password                      = try(coalesce(var.automation_password, try(var.authentication.password, "")), "")
  path_to_public_key_specified  = (length(var.automation_path_to_public_key) + length(try(var.authentication.path_to_public_key, ""))) > 0
  path_to_public_key            = try(coalesce(var.automation_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
  path_to_private_key_specified = (length(var.automation_path_to_private_key) + length(try(var.authentication.path_to_private_key, ""))) > 0
  path_to_private_key           = try(coalesce(var.automation_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")

  disk_encryption_set_defined = (length(var.vm_disk_encryption_set_id) + length(try(var.options.disk_encryption_set_id, ""))) > 0
  disk_encryption_set_id      = try(coalesce(var.vm_disk_encryption_set_id, try(var.options.disk_encryption_set_id, null)), null)

  infrastructure = merge(local.temp_infrastructure, (
    local.resource_group_defined ? { resource_group = local.resource_group } : null), (
    local.ppg_defined ? { ppg = local.ppg } : null), (
    local.deploy_anchor_vm ? { anchor_vms = local.anchor_vms } : null),
    { vnets = local.temp_vnet }
  )

  application = merge(local.application_temp, (
    local.app_authentication_defined ? { authentication = local.app_authentication } : null), (
    local.app_os_specified ? { app_os = local.app_os } : null), (
    local.scs_os_specified ? { scs_os = local.scs_os } : (local.app_os_specified ? { scs_os = local.app_os } : null)), (
    local.web_os_specified ? { web_os = local.web_os } : (local.app_os_specified ? { web_os = local.app_os } : null)), (
    length(local.app_zones_temp) > 0 ? { app_zones = local.app_zones_temp } : null), (
    length(local.scs_zones_temp) > 0 ? { scs_zones = local.scs_zones_temp } : null), (
    length(local.web_zones_temp) > 0 ? { web_zones = local.web_zones_temp } : null), (
    length(local.app_nic_ips) > 0 ? { app_nic_ips = local.app_nic_ips } : null), (
    length(local.app_admin_nic_ips) > 0 ? { app_admin_nic_ips = local.app_admin_nic_ips } : null), (
    length(local.scs_nic_ips) > 0 ? { scs_nic_ips = local.scs_nic_ips } : null), (
    length(local.scs_admin_nic_ips) > 0 ? { scs_admin_nic_ips = local.scs_admin_nic_ips } : null), (
    length(local.scs_lb_ips) > 0 ? { scs_lb_ips = local.scs_lb_ips } : null), (
    length(local.web_nic_ips) > 0 ? { web_nic_ips = local.web_nic_ips } : null), (
    length(local.web_admin_nic_ips) > 0 ? { web_admin_nic_ips = local.web_admin_nic_ips } : null), (
    length(local.web_lb_ips) > 0 ? { web_lb_ips = local.web_lb_ips } : null), (
    length(local.app_tags) > 0 ? { app_tags = local.app_tags } : null), (
    length(local.scs_tags) > 0 ? { scs_tags = local.scs_tags } : null), (
    length(local.web_tags) > 0 ? { web_tags = local.web_tags } : null
    )
  )

  databases = [merge(local.databases_temp, (
    local.db_os_specified ? { os = local.db_os } : null), (
    local.db_authentication_defined ? { authentication = local.db_authentication } : null), (
    local.db_avset_arm_ids_defined ? { avset_arm_ids = local.avset_arm_ids } : null), (
    length(local.dbnodes) > 0 ? { dbnodes = local.dbnodes } : null), (
    length(local.db_zones_temp) > 0 ? { zones = local.db_zones_temp } : null), (
    length(local.frontend_ip) > 0 ? { loadbalancer = { frontend_ip = local.frontend_ip } } : { loadbalancer = {} }), (
    length(local.db_tags) > 0 ? { tags = local.db_tags } : null), (
    local.db_sid_specified ? { instance = local.instance } : null)
    )
  ]

  authentication = merge(local.authentication_temp, (
    local.username_specified ? { username = local.username } : null), (
    local.password_specified ? { password = local.password } : null), (
    local.path_to_public_key_specified ? { path_to_public_key = local.path_to_public_key } : null), (
    local.path_to_private_key_specified ? { path_to_private_key = local.path_to_private_key } : null
    )
  )

  key_vault = merge(local.key_vault_temp, (
    local.user_kv_specified ? { kv_user_id = local.user_kv } : null), (
    local.prvt_kv_specified ? { kv_prvt_id = local.prvt_kv } : null), (
    local.spn_kv_specified ? { kv_spn_id = local.spn_kv } : null
    )
  )

  options = merge(local.options_temp, (local.disk_encryption_set_defined ? { disk_encryption_set_id = local.disk_encryption_set_id } : null))

}
