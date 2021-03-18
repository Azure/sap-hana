variable "anydb_vms" {
  description = "Deployed anydb VMs"
}

variable "hdb_vms" {
  description = "Deployed HDB VMs"
}

variable "resource_group" {
  description = "Details of the resource group"
}

variable "vnet_sap" {
  description = "Details of the SAP Vnet"
}

variable "storage_bootdiag_endpoint" {
  description = "Details of the boot diagnostic storage device"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

variable "admin_subnet" {
  description = "Information about SAP admin subnet"
}

variable "deployer_user" {
  description = "Details of the users"
  default     = []
}

variable "sid_kv_user_id" {
  description = "Details of the user keyvault for sap_system"
}

variable "sdu_public_key" {
  description = "Public key used for authentication"
}

variable "route_table_id" {
  description = "Route table (if any) id"
}

variable "firewall_id" {
  description = "Firewall (if any) id"
}

variable "sid_password" {
  description = "SDU password"
}

variable "sid_username" {
  description = "SDU username"
}

variable "sap_sid" {
  description = "The SID of the application"
}

locals {
  // Imports Disk sizing sizing information
  sizes = jsondecode(file(length(var.custom_disk_sizes_filename) > 0 ? var.custom_disk_sizes_filename : "${path.module}/../../../../../configs/app_sizes.json"))

  faults = jsondecode(file("${path.module}/../../../../../configs/max_fault_domain_count.json"))

  app_computer_names       = var.naming.virtualmachine_names.APP_COMPUTERNAME
  app_virtualmachine_names = var.naming.virtualmachine_names.APP_VMNAME
  scs_computer_names       = var.naming.virtualmachine_names.SCS_COMPUTERNAME
  scs_virtualmachine_names = var.naming.virtualmachine_names.SCS_VMNAME
  web_computer_names       = var.naming.virtualmachine_names.WEB_COMPUTERNAME
  web_virtualmachine_names = var.naming.virtualmachine_names.WEB_VMNAME

  resource_suffixes = var.naming.resource_suffixes

  region = try(var.infrastructure.region, "")

  //Allowing changing the base for indexing, default is zero-based indexing, if customers want the first disk to start with 1 they would change this
  offset = try(var.options.resource_offset, 0)

  //Allowing to keep the old nic order
  legacy_nic_order = try(var.options.legacy_nic_order, "false") == "true"

  faultdomain_count = try(tonumber(compact(
    [for pair in local.faults :
      upper(pair.Location) == upper(local.region) ? pair.MaximumFaultDomainCount : ""
  ])[0]), 2)

  sid     = upper(try(var.application.sid, ""))
  prefix  = try(var.infrastructure.resource_group.name, trimspace(var.naming.prefix.SDU))
  rg_name = try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))

  sid_auth_type        = try(var.application.authentication.type, upper(local.app_ostype) == "LINUX" ? "key" : "password")
  enable_auth_password = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key      = local.enable_deployment && local.sid_auth_type == "key"

  authentication = {
    "type"     = local.sid_auth_type
    "username" = var.sid_username
    "password" = var.sid_password
  }

  // SAP vnet
  vnet_sap                     = try(var.vnet_sap, {})
  vnet_sap_name                = try(local.vnet_sap.name, "")
  vnet_sap_resource_group_name = try(local.vnet_sap.resource_group_name, "")
  vnet_sap_address_space       = try(local.vnet_sap.address_space, [])

  // APP subnet
  var_sub_app    = try(var.infrastructure.vnets.sap.subnet_app, {})
  sub_app_arm_id = try(local.var_sub_app.arm_id, "")
  sub_app_exists = length(local.sub_app_arm_id) > 0 ? true : false
  sub_app_name = local.sub_app_exists ? (
    try(split("/", local.sub_app_arm_id)[10], "")) : (
    try(local.var_sub_app.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_subnet))
  )

  sub_app_prefix = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] : try(local.var_sub_app.prefix, "")

  // APP NSG
  var_sub_app_nsg    = try(local.var_sub_app.nsg, {})
  sub_app_nsg_arm_id = try(local.var_sub_app_nsg.arm_id, "")
  sub_app_nsg_exists = length(local.sub_app_nsg_arm_id) > 0 ? true : false
  sub_app_nsg_name = local.sub_app_nsg_exists ? (
    try(split("/", local.sub_app_nsg_arm_id)[8], "")) : (
    try(local.var_sub_app_nsg.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_subnet_nsg))
  )

  // WEB subnet
  #If subnet_web is not specified deploy into app subnet
  sub_web_defined = try(var.infrastructure.vnets.sap.subnet_web, null) == null ? false : true
  sub_web         = try(var.infrastructure.vnets.sap.subnet_web, {})
  sub_web_arm_id  = try(local.sub_web.arm_id, "")
  sub_web_exists  = length(local.sub_web_arm_id) > 0 ? true : false
  sub_web_name = local.sub_web_exists ? (
    try(split("/", local.sub_web_arm_id)[10], "")) : (
    try(local.sub_web.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_subnet))
  )

  sub_web_prefix = local.sub_web_exists ? data.azurerm_subnet.subnet_sap_web[0].address_prefixes[0] : try(local.sub_web.prefix, "")
  sub_web_deployed = try(local.sub_web_defined ? (
    local.sub_web_exists ? data.azurerm_subnet.subnet_sap_web[0] : azurerm_subnet.subnet_sap_web[0]) : (
    local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0] : azurerm_subnet.subnet_sap_app[0]), null
  )

  // WEB NSG
  sub_web_nsg        = try(local.sub_web.nsg, {})
  sub_web_nsg_arm_id = try(local.sub_web_nsg.arm_id, "")
  sub_web_nsg_exists = length(local.sub_web_nsg_arm_id) > 0 ? true : false
  sub_web_nsg_name = local.sub_web_nsg_exists ? (
    try(split("/", local.sub_web_nsg_arm_id)[8], "")) : (
    try(local.sub_web_nsg.name, format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_subnet_nsg))
  )

  sub_web_nsg_deployed = try(local.sub_web_defined ? (
    local.sub_web_nsg_exists ? data.azurerm_network_security_group.nsg_web[0] : azurerm_network_security_group.nsg_web[0]) : (
    local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg_app[0] : azurerm_network_security_group.nsg_app[0]), null
  )

  firewall_exists = length(var.firewall_id) > 0
  firewall_name   = local.firewall_exists ? try(split("/", var.firewall_id)[8], "") : ""
  firewall_rgname = local.firewall_exists ? try(split("/", var.firewall_id)[4], "") : ""

  firewall_service_tags = format("AzureCloud.%s", local.region)

  application_sid          = try(var.application.sid, "")
  enable_deployment        = try(var.application.enable_deployment, false)
  scs_instance_number      = try(var.application.scs_instance_number, "01")
  ers_instance_number      = try(var.application.ers_instance_number, "02")
  scs_high_availability    = try(var.application.scs_high_availability, false)
  application_server_count = try(var.application.application_server_count, 0)
  scs_server_count         = try(var.application.scs_server_count, 1) * (local.scs_high_availability ? 2 : 1)
  webdispatcher_count      = try(var.application.webdispatcher_count, 0)

  app_nic_ips       = try(var.application.app_nic_ips, [])
  app_admin_nic_ips = try(var.application.app_admin_nic_ips, [])
  scs_lb_ips        = try(var.application.scs_lb_ips, [])
  scs_nic_ips       = try(var.application.scs_nic_ips, [])
  scs_admin_nic_ips = try(var.application.scs_admin_nic_ips, [])
  web_lb_ips        = try(var.application.web_lb_ips, [])
  web_nic_ips       = try(var.application.web_nic_ips, [])
  web_admin_nic_ips = try(var.application.web_admin_nic_ips, [])

  app_size = try(var.application.app_sku, "")
  scs_size = try(var.application.scs_sku, local.app_size)
  web_size = try(var.application.web_sku, local.app_size)

  vm_sizing = length(local.app_size) > 0 ? "New" : "Default"

  use_DHCP = try(var.application.use_DHCP, false)

  // Dual network cards
  apptier_dual_nics = try(var.application.dual_nics, false)

  // OS image for all Application Tier VMs
  // If custom image is used, we do not overwrite os reference with default value
  app_custom_image = try(var.application.os.source_image_id, "") != "" ? true : false
  app_ostype       = try(var.application.os.os_type, "Linux")

  app_os = {
    "os_type"         = local.app_ostype
    "source_image_id" = local.app_custom_image ? var.application.os.source_image_id : ""
    "publisher"       = try(var.application.os.publisher, local.app_custom_image ? "" : "suse")
    "offer"           = try(var.application.os.offer, local.app_custom_image ? "" : "sles-sap-12-sp5")
    "sku"             = try(var.application.os.sku, local.app_custom_image ? "" : "gen1")
    "version"         = try(var.application.os.version, local.app_custom_image ? "" : "latest")
  }

  // OS image for all SCS VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  scs_custom_image = try(var.application.scs_os.source_image_id, "") == "" && !local.app_custom_image ? false : true
  scs_ostype       = try(var.application.scs_os.os_type, local.app_ostype)

  scs_os = {
    "os_type"         = local.scs_ostype
    "source_image_id" = local.scs_custom_image ? try(var.application.scs_os.source_image_id, var.application.os.source_image_id) : ""
    "publisher"       = try(var.application.scs_os.publisher, local.scs_custom_image ? "" : local.app_os.publisher)
    "offer"           = try(var.application.scs_os.offer, local.scs_custom_image ? "" : local.app_os.offer)
    "sku"             = try(var.application.scs_os.sku, local.scs_custom_image ? "" : local.app_os.sku)
    "version"         = try(var.application.scs_os.version, local.scs_custom_image ? "" : local.app_os.version)
  }

  // Tags
  app_tags = try(var.application.app_tags, {})
  scs_tags = try(var.application.scs_tags, {})
  web_tags = try(var.application.web_tags, {})

  application = merge(var.application,
    { authentication = local.authentication }
  )

  // OS image for all WebDispatcher VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  web_custom_image = try(var.application.web_os.source_image_id, "") == "" && !local.app_custom_image ? false : true
  web_ostype       = try(var.application.web_os.os_type, local.app_ostype)

  web_os = {
    "os_type"         = local.web_ostype
    "source_image_id" = try(var.application.web_os.source_image_id, local.web_custom_image ? local.app_os.source_image_id : null)
    "publisher"       = try(var.application.web_os.publisher, local.web_custom_image ? "" : local.app_os.publisher)
    "offer"           = try(var.application.web_os.offer, local.web_custom_image ? "" : local.app_os.offer)
    "sku"             = try(var.application.web_os.sku, local.web_custom_image ? "" : local.app_os.sku)
    "version"         = try(var.application.web_os.version, local.web_custom_image ? "" : local.app_os.version)
  }

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  ip_offsets = {
    scs_lb = 4 + 1
    web_lb = local.sub_web_defined ? (4 + 1) : -2
    scs_vm = 4 + 6
    app_vm = 4 + 10
    web_vm = local.sub_web_defined ? (4 + 2) : -3
  }
  admin_ip_offsets = {
    scs_vm = 4 + 16
    app_vm = 4 + 11
    web_vm = 4 + 21
  }

  // Default VM config should be merged with any the user passes in
  app_sizing = lookup(local.sizes.app, local.vm_sizing)

  scs_sizing = lookup(local.sizes.scs, local.vm_sizing)

  web_sizing = lookup(local.sizes.web, local.vm_sizing)

  // Ports used for specific ASCS, ERS and Web dispatcher
  lb_ports = {
    "scs" = [
      3200 + tonumber(local.scs_instance_number),          // e.g. 3201
      3600 + tonumber(local.scs_instance_number),          // e.g. 3601
      3900 + tonumber(local.scs_instance_number),          // e.g. 3901
      8100 + tonumber(local.scs_instance_number),          // e.g. 8101
      50013 + (tonumber(local.scs_instance_number) * 100), // e.g. 50113
      50014 + (tonumber(local.scs_instance_number) * 100), // e.g. 50114
      50016 + (tonumber(local.scs_instance_number) * 100), // e.g. 50116
    ]

    "ers" = [
      3200 + tonumber(local.ers_instance_number),          // e.g. 3202
      3300 + tonumber(local.ers_instance_number),          // e.g. 3302
      50013 + (tonumber(local.ers_instance_number) * 100), // e.g. 50213
      50014 + (tonumber(local.ers_instance_number) * 100), // e.g. 50214
      50016 + (tonumber(local.ers_instance_number) * 100), // e.g. 50216
    ]

    "web" = [
      80,
      3200
    ]
  }

  // Ports used for ASCS, ERS and Web dispatcher NSG rules
  nsg_ports = {
    "web" = [
      {
        "priority" = "101",
        "name"     = "SSH",
        "port"     = "22"
      },
      {
        "priority" = "102",
        "name"     = "HTTP",
        "port"     = "80"
      },
      {
        "priority" = "103",
        "name"     = "HTTPS",
        "port"     = "443"
      },
      {
        "priority" = "104",
        "name"     = "sapinst",
        "port"     = "4237"
      },
      {
        "priority" = "105",
        "name"     = "WebDispatcher",
        "port"     = "44300"
      }
    ]
  }

  // Ports used for the health probes.
  // Where Instance Number is nn:
  // SCS (index 0) - 620nn
  // ERS (index 1) - 621nn
  hp_ports = [
    62000 + tonumber(local.scs_instance_number),
    62100 + tonumber(local.ers_instance_number)
  ]

  app_data_disk_per_dbnode = (local.application_server_count > 0) ? flatten(
    [
      for storage_type in local.app_sizing.storage : [
        for disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + local.offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
    ]
  ) : []

  app_data_disks = flatten([
    for vm_counter in range(local.application_server_count) : [
      for idx, datadisk in local.app_data_disk_per_dbnode : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = idx
      }
    ]
  ])

  scs_data_disk_per_dbnode = (local.enable_deployment) ? flatten(
    [
      for storage_type in local.scs_sizing.storage : [
        for disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + local.offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
    ]
  ) : []

  scs_data_disks = flatten([
    for vm_counter in range(local.scs_server_count) : [
      for idx, datadisk in local.scs_data_disk_per_dbnode : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = idx
      }
    ]
  ])

  web_data_disk_per_dbnode = (local.webdispatcher_count > 0) ? flatten(
    [
      for storage_type in local.web_sizing.storage : [
        for disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + local.offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
        }
      ]
      if storage_type.name != "os"
    ]
  ) : []

  web_data_disks = flatten([
    for vm_counter in range(local.webdispatcher_count) : [
      for idx, datadisk in local.web_data_disk_per_dbnode : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = idx
      }
    ]
  ])


  full_appserver_names = flatten([for vm in local.app_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  )

  full_scsserver_names = flatten([for vm in local.scs_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  )

  full_webserver_names = flatten([for vm in local.web_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  )

  // Zones
  app_zones            = try(var.application.app_zones, [])
  app_zonal_deployment = length(local.app_zones) > 0 ? true : false
  app_zone_count       = length(local.app_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_app_avset = !local.app_zonal_deployment || local.application_server_count != local.app_zone_count

  scs_zones            = try(var.application.scs_zones, [])
  scs_zonal_deployment = length(local.scs_zones) > 0 ? true : false
  scs_zone_count       = length(local.scs_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_scs_avset = !local.scs_zonal_deployment || local.scs_server_count != local.scs_zone_count

  web_zones            = try(var.application.web_zones, [])
  web_zonal_deployment = length(local.web_zones) > 0 ? true : false
  web_zone_count       = length(local.web_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_web_avset = !local.web_zonal_deployment || local.webdispatcher_count != local.web_zone_count



}
