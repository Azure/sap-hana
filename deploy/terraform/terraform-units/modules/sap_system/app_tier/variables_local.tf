variable "anydb_vm_ids" {
  description = "Deployed anydb VMs"
}

variable "hdb_vm_ids" {
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
variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "deployment" {
  description = "The type of deployment"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
}

variable "cloudinit_growpart_config" {
  description = "A cloud-init config that configures automatic growpart expansion of root partition"
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""

}

variable "use_loadbalancers_for_standalone_deployments" {
  description = "Defines if load balancers are used even for standalone deployments"
  default     = true
}

locals {
  // Imports Disk sizing sizing information

  default_filepath = format("%s%s", path.module, "/../../../../../configs/app_sizes.json")
  custom_sizing    = length(var.custom_disk_sizes_filename) > 0

  // Imports application tier sizing information
  file_name = local.custom_sizing ? (
    fileexists(var.custom_disk_sizes_filename) ? (
      var.custom_disk_sizes_filename) : (
      format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
    )) : (
    local.default_filepath

  )

  sizes = jsondecode(file(local.file_name))

  faults = jsondecode(file(format("%s%s", path.module, "/../../../../../configs/max_fault_domain_count.json")))

  app_computer_names       = var.naming.virtualmachine_names.APP_COMPUTERNAME
  app_virtualmachine_names = var.naming.virtualmachine_names.APP_VMNAME
  scs_computer_names       = var.naming.virtualmachine_names.SCS_COMPUTERNAME
  scs_virtualmachine_names = var.naming.virtualmachine_names.SCS_VMNAME
  web_computer_names       = var.naming.virtualmachine_names.WEB_COMPUTERNAME
  web_virtualmachine_names = var.naming.virtualmachine_names.WEB_VMNAME

  resource_suffixes = var.naming.resource_suffixes

  region = var.infrastructure.region

  //Allowing changing the base for indexing, default is zero-based indexing, if customers want the first disk to start with 1 they would change this
  offset = var.options.resource_offset

  //Flag to control if nsg is creates in virtual network resource group
  nsg_asg_with_vnet = var.options.nsg_asg_with_vnet

  faultdomain_count = try(tonumber(compact(
    [for pair in local.faults :
      upper(pair.Location) == upper(local.region) ? pair.MaximumFaultDomainCount : ""
  ])[0]), 2)

  sid    = upper(var.application.sid)
  prefix = try(var.infrastructure.resource_group.name, trimspace(var.naming.prefix.SDU))
  // Resource group
  rg_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    try(var.infrastructure.resource_group.name, format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))

  )

  sid_auth_type        = upper(local.app_ostype) == "LINUX" ? try(var.application.authentication.type, "key") : "password"
  enable_auth_password = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key      = local.enable_deployment && local.sid_auth_type == "key"

  authentication = {
    "type"     = local.sid_auth_type
    "username" = var.sid_username
    "password" = var.sid_password
  }

  // SAP vnet
  vnet_sap_name                    = var.vnet_sap.name
  vnet_sap_resource_group_name     = var.vnet_sap.resource_group_name
  vnet_sap_resource_group_location = var.vnet_sap.location

  // APP subnet
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

  sub_web_defined = length(try(var.infrastructure.vnets.sap.subnet_web, {})) > 0
  sub_web_arm_id  = try(var.infrastructure.vnets.sap.subnet_web.arm_id, try(var.landscape_tfstate.web_subnet_id, ""))
  sub_web_exists  = length(local.sub_web_arm_id) > 0
  sub_web_name = local.sub_web_exists ? (
    try(split("/", var.infrastructure.vnets.sap.subnet_web.arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_web.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_web.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_subnet)
    )
  )
  sub_web_prefix = local.sub_web_defined ? try(var.infrastructure.vnets.sap.subnet_web.prefix, "") : ""
  sub_web_deployed = try(local.sub_web_defined ? (
    local.sub_web_exists ? data.azurerm_subnet.subnet_sap_web[0] : azurerm_subnet.subnet_sap_web[0]) : (
    local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0] : azurerm_subnet.subnet_sap_app[0]), null
  )

  // APP NSG
  sub_app_nsg_arm_id = try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, try(var.landscape_tfstate.app_nsg_id, ""))
  sub_app_nsg_exists = length(local.sub_app_nsg_arm_id) > 0
  sub_app_nsg_name = local.sub_app_nsg_exists ? (
    try(split("/", local.sub_app_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_app.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.app_subnet_nsg)
    )
  )


  // WEB NSG
  sub_web_nsg_arm_id = try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, try(var.landscape_tfstate.web_nsg_id, ""))
  sub_web_nsg_exists = length(local.sub_web_nsg_arm_id) > 0

  sub_web_nsg_name = local.sub_web_nsg_exists ? (
    try(split("/", local.sub_web_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_web.nsg.name) : (
      format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_subnet_nsg)
    )
  )

  sub_web_nsg_deployed = try(local.sub_web_defined ? (
    local.sub_web_nsg_exists ? data.azurerm_network_security_group.nsg_web[0] : azurerm_network_security_group.nsg_web[0]) : (
    local.sub_app_nsg_exists ? data.azurerm_network_security_group.nsg_app[0] : azurerm_network_security_group.nsg_app[0]), null
  )

  firewall_exists = length(var.firewall_id) > 0
  firewall_name   = local.firewall_exists ? try(split("/", var.firewall_id)[8], "") : ""
  firewall_rgname = local.firewall_exists ? try(split("/", var.firewall_id)[4], "") : ""

  firewall_service_tags = format("AzureCloud.%s", local.region)

  application_sid          = var.application.sid
  enable_deployment        = var.application.enable_deployment
  scs_instance_number      = var.application.scs_instance_number
  ers_instance_number      = var.application.ers_instance_number
  scs_high_availability    = var.application.scs_high_availability
  application_server_count = var.application.application_server_count
  scs_server_count         = var.application.scs_server_count * (local.scs_high_availability ? 2 : 1)
  enable_scs_lb_deployment = local.scs_server_count > 0 && (var.use_loadbalancers_for_standalone_deployments || local.scs_server_count > 1)

  webdispatcher_count      = var.application.webdispatcher_count
  enable_web_lb_deployment = local.webdispatcher_count > 0 && (var.use_loadbalancers_for_standalone_deployments || local.webdispatcher_count > 1)

  app_nic_ips       = try(var.application.app_nic_ips, [])
  app_admin_nic_ips = try(var.application.app_admin_nic_ips, [])
  scs_lb_ips        = try(var.application.scs_lb_ips, [])
  scs_nic_ips       = try(var.application.scs_nic_ips, [])
  scs_admin_nic_ips = try(var.application.scs_admin_nic_ips, [])
  web_lb_ips        = try(var.application.web_lb_ips, [])
  web_nic_ips       = try(var.application.web_nic_ips, [])
  web_admin_nic_ips = try(var.application.web_admin_nic_ips, [])

  app_size = var.application.app_sku
  scs_size = length(var.application.scs_sku) > 0 ? var.application.scs_sku : local.app_size
  web_size = length(var.application.web_sku) > 0 ? var.application.web_sku : local.app_size

  vm_sizing = length(var.application.vm_sizing) > 0 ? var.application.vm_sizing : length(local.app_size) > 0 ? "Production" : "Default"


  // OS image for all Application Tier VMs
  // If custom image is used, we do not overwrite os reference with default value

  app_custom_image = length(try(var.application.app_os.source_image_id, "")) > 0
  app_ostype       = upper(try(var.application.app_os.offer, "")) == "WINDOWSSERVER" ? "WINDOWS" : try(var.application.app_os.os_type, "LINUX")

  app_os = {
    os_type         = local.app_ostype
    source_image_id = local.app_custom_image ? var.application.app_os.source_image_id : ""
    publisher       = local.app_custom_image ? "" : length(try(var.application.app_os.publisher, "")) > 0 ? var.application.app_os.publisher : "SUSE"
    offer           = local.app_custom_image ? "" : length(try(var.application.app_os.offer, "")) > 0 ? var.application.app_os.offer : "sles-sap-12-sp5"
    sku             = local.app_custom_image ? "" : length(try(var.application.app_os.sku, "")) > 0 ? var.application.app_os.sku : "gen1"
    version         = local.app_custom_image ? "" : length(try(var.application.app_os.version, "")) > 0 ? var.application.app_os.version : "latest"
  }

  // OS image for all SCS VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  scs_custom_image = length(try(var.application.scs_os.source_image_id, "")) > 0
  scs_ostype       = upper(try(var.application.scs_os.offer, "")) == "WINDOWSSERVER" ? "WINDOWS" : try(var.application.scs_os.os_type, local.app_ostype)

  scs_os = {
    os_type         = local.scs_ostype
    source_image_id = local.scs_custom_image ? var.application.scs_os.source_image_id : ""
    publisher       = local.scs_custom_image ? "" : length(try(var.application.scs_os.publisher, "")) > 0 ? var.application.scs_os.publisher : "SUSE"
    offer           = local.scs_custom_image ? "" : length(try(var.application.scs_os.offer, "")) > 0 ? var.application.scs_os.offer : "sles-sap-12-sp5"
    sku             = local.scs_custom_image ? "" : length(try(var.application.scs_os.sku, "")) > 0 ? var.application.scs_os.sku : "gen1"
    version         = local.scs_custom_image ? "" : length(try(var.application.scs_os.version, "")) > 0 ? var.application.scs_os.version : "latest"
  }

  // OS image for all WebDispatcher VMs
  // If custom image is used, we do not overwrite os reference with default value
  // If no publisher or no custom image is specified use the custom image from the app if specified
  web_custom_image = length(try(var.application.web_os.source_image_id, "")) > 0
  web_ostype       = upper(try(var.application.web_os.offer, "")) == "WINDOWSSERVER" ? "WINDOWS" : try(var.application.web_os.os_type, local.app_ostype)
  web_os = {
    os_type         = local.web_ostype
    source_image_id = local.web_custom_image ? var.application.web_os.source_image_id : ""
    publisher       = local.web_custom_image ? "" : length(try(var.application.web_os.publisher, "")) > 0 ? var.application.web_os.publisher : "SUSE"
    offer           = local.web_custom_image ? "" : length(try(var.application.web_os.offer, "")) > 0 ? var.application.web_os.offer : "sles-sap-12-sp5"
    sku             = local.web_custom_image ? "" : length(try(var.application.web_os.sku, "")) > 0 ? var.application.web_os.sku : "gen1"
    version         = local.web_custom_image ? "" : length(try(var.application.web_os.version, "")) > 0 ? var.application.web_os.version : "latest"
  }

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  linux_ip_offsets = {
    scs_lb = 4
    scs_vm = 6
    app_vm = 10
    web_lb = local.sub_web_defined ? (4 + 1) : 6
    web_vm = local.sub_web_defined ? (10) : 50
  }

  windows_ip_offsets = {
    scs_lb = 4
    scs_vm = 6 + 2 # Windows HA SCS may require 4 IPs
    app_vm = 10 + 2
    web_lb = local.sub_web_defined ? (4 + 1) : 6 + 2
    web_vm = local.sub_web_defined ? (10) : 50
  }

  win_ha_scs = local.scs_server_count > 0 && (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS")

  ip_offsets = local.scs_ostype == "WINDOWS" ? local.windows_ip_offsets : local.linux_ip_offsets

  admin_ip_offsets = {
    app_vm = 14
    scs_vm = 10
    web_vm = 50
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

  base_app_data_disk_per_dbnode = (local.application_server_count > 0) ? flatten(
    [
      for storage_type in local.app_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = try(storage_type.lun_start, 0) + idx
        }
      ]
      if storage_type.name != "os" && !try(storage_type.append, false)
    ]
  ) : []


  append_app_data_disk_per_dbnode = (local.application_server_count > 0) ? flatten(
    [
      for storage_type in local.app_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, storage_type.lun_start + disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
      ]
      if storage_type.name != "os" && try(storage_type.append, false)
    ]
  ) : []

  app_data_disk_per_dbnode = distinct(concat(local.base_app_data_disk_per_dbnode, local.append_app_data_disk_per_dbnode))

  app_data_disks = flatten([
    for idx, datadisk in local.app_data_disk_per_dbnode : [
      for vm_counter in range(local.application_server_count) : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = datadisk.lun
        type                      = datadisk.type
      }
    ]
  ])

  base_scs_data_disk_per_dbnode = (local.enable_deployment) ? flatten(
    [
      for storage_type in local.scs_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = try(storage_type.lun_start, 0) + idx
        }
      ]
      if storage_type.name != "os" && !try(storage_type.append, false)
    ]
  ) : []

  append_scs_data_disk_per_dbnode = (local.enable_deployment) ? flatten(
    [
      for storage_type in local.scs_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
      ]
      if storage_type.name != "os" && try(storage_type.append, false)
    ]
  ) : []

  scs_data_disk_per_dbnode = distinct(concat(local.base_scs_data_disk_per_dbnode, local.append_scs_data_disk_per_dbnode))

  scs_data_disks = flatten([
    for idx, datadisk in local.scs_data_disk_per_dbnode : [
      for vm_counter in range(local.scs_server_count) : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        type                      = datadisk.type
        lun                       = datadisk.lun

      }
    ]
  ])

  base_web_data_disk_per_dbnode = (local.webdispatcher_count > 0) ? flatten(
    [
      for storage_type in local.web_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = try(storage_type.lun_start, 0) + idx

        }
      ]
      if storage_type.name != "os" && !try(storage_type.append, false)
    ]
  ) : []

  append_web_data_disk_per_dbnode = (local.webdispatcher_count > 0) ? flatten(
    [
      for storage_type in local.web_sizing.storage : [
        for idx, disk_count in range(storage_type.count) : {
          suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type = storage_type.disk_type,
          disk_size_gb         = storage_type.size_gb,
          //The following two lines are for Ultradisks only
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
      ]
      if storage_type.name != "os" && try(storage_type.append, false)
    ]
  ) : []

  web_data_disk_per_dbnode = distinct(concat(local.base_web_data_disk_per_dbnode, local.append_web_data_disk_per_dbnode))
  web_data_disks = flatten([
    for idx, datadisk in local.web_data_disk_per_dbnode : [
      for vm_counter in range(local.webdispatcher_count) : {
        suffix                    = datadisk.suffix
        vm_index                  = vm_counter
        caching                   = datadisk.caching
        storage_account_type      = datadisk.storage_account_type
        disk_size_gb              = datadisk.disk_size_gb
        write_accelerator_enabled = datadisk.write_accelerator_enabled
        disk_iops_read_write      = datadisk.disk_iops_read_write
        disk_mbps_read_write      = datadisk.disk_mbps_read_write
        lun                       = datadisk.lun
        type                      = datadisk.type
      }
    ]
  ])

  full_appserver_names = distinct(flatten([for vm in local.app_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  ))

  full_scsserver_names = distinct(flatten([for vm in local.scs_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  ))

  full_webserver_names = distinct(flatten([for vm in local.web_virtualmachine_names :
    format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
  ))

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  app_disks_ansible = distinct(flatten([for vm in local.app_computer_names : [
    for idx, datadisk in local.app_data_disk_per_dbnode :
    format("{ host: '%s', LUN: %d, type: '%s' }", vm, idx, "sap")
  ]]))

  scs_disks_ansible = distinct(flatten([for vm in local.scs_computer_names : [
    for idx, datadisk in local.scs_data_disk_per_dbnode :
    format("{ host: '%s', LUN: %d, type: '%s' }", vm, idx, "sap")
  ]]))

  web_disks_ansible = distinct(flatten([for vm in local.web_computer_names : [
    for idx, datadisk in local.web_data_disk_per_dbnode :
    format("{ host: '%s', LUN: %d, type: '%s' }", vm, idx, "sap")
  ]]))


  // Zones
  app_zones            = try(var.application.app_zones, [])
  app_zonal_deployment = length(local.app_zones) > 0 ? true : false
  app_zone_count       = length(local.app_zones)
  //If we deploy more than one server in zone put them in an availability set unless specified otherwise
  use_app_avset = local.application_server_count > 0 && !var.application.app_no_avset ? !local.app_zonal_deployment || local.application_server_count != local.app_zone_count : false

  scs_zones            = try(var.application.scs_zones, [])
  scs_zonal_deployment = length(local.scs_zones) > 0 ? true : false
  scs_zone_count       = length(local.scs_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_scs_avset = local.scs_server_count > 0 && !var.application.scs_no_avset ? (!local.scs_zonal_deployment || local.scs_server_count != local.scs_zone_count) : false

  web_zones            = try(var.application.web_zones, [])
  web_zonal_deployment = length(local.web_zones) > 0 ? true : false
  web_zone_count       = length(local.web_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_web_avset = local.webdispatcher_count > 0 && !var.application.web_no_avset ? (!local.web_zonal_deployment || local.webdispatcher_count != local.web_zone_count) : false

  winha_ips = [
    {
      name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_clst_feip)
      subnet_id                     = local.enable_deployment ? (local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id) : ""
      private_ip_address            = var.application.use_DHCP ? (null) : (try(local.scs_lb_ips[0], cidrhost(local.sub_app_prefix, 2 + local.ip_offsets.scs_lb)))
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"

    },
    {
      name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_fs_feip)
      subnet_id                     = local.enable_deployment ? (local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id) : ""
      private_ip_address            = var.application.use_DHCP ? (null) : (try(local.scs_lb_ips[0], cidrhost(local.sub_app_prefix, 3 + local.ip_offsets.scs_lb)))
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
    }
  ]


  std_ips = [
    {
      name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_alb_feip)
      subnet_id                     = local.enable_deployment ? (local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id) : ""
      private_ip_address            = var.application.use_DHCP ? (null) : (try(local.scs_lb_ips[0], cidrhost(local.sub_app_prefix, 0 + local.ip_offsets.scs_lb)))
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
    },
    {
      name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.scs_ers_feip)
      subnet_id                     = local.enable_deployment ? (local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id) : ""
      private_ip_address            = var.application.use_DHCP ? (null) : (try(local.scs_lb_ips[1], cidrhost(local.sub_app_prefix, 1 + local.ip_offsets.scs_lb)))
      private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
    },
  ]

  fpips = (local.scs_high_availability && upper(local.scs_ostype) == "WINDOWS") ? concat(local.std_ips, local.winha_ips) : local.std_ips


  //PPG control flags
  app_no_ppg = var.application.app_no_ppg
  scs_no_ppg = var.application.scs_no_ppg
  web_no_ppg = var.application.web_no_ppg


}
