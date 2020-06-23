variable "resource-group" {
  description = "Details of the resource group"
}

variable "vnet-sap" {
  description = "Details of the SAP VNet"
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostic storage device"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

# Imports Disk sizing sizing information
locals {
  sizes = jsondecode(file("${path.root}/../app_sizes.json"))
}

locals {
  enable_deployment = lookup(var.application, "enable_deployment", false)

  vm_sizing = lookup(var.application, "vm_sizing", "Default")

  scs_instance_number = lookup(var.application, "scs_instance_number", "01")
  ers_instance_number = lookup(var.application, "ers_instance_number", "02")

  # Subnet IP Offsets
  # Note: First 4 IP addresses in a subnet are reserved by Azure
  ip_offsets = {
    scs_lb = 4 + 1
    web_lb = 4 + 3
    scs_vm = 4 + 6
    app_vm = 4 + 10
    web_vm = 4 + 20
  }

  # OS image for all Application Tier VMs
  os = merge({
    version = "latest"
  }, lookup(var.application, "os", {
    publisher = "suse"
    offer     = "sles-sap-12-sp5"
    sku       = "gen1"
  }))

  # Default VM config should be merged with any the user passes in
  app_sizing = lookup(local.sizes.app, local.vm_sizing, {
    "compute": {
      "vm_size": "Standard_D4s_v3",
      "accelerated_networking": false
    },
    "storage": [{
      "name": "data",
      "disk_type": "Premium_LRS",
      "size_gb": 512,
      "caching": "None",
      "write_accelerator": false
    }]
  })

  scs_sizing = lookup(local.sizes.scs, local.vm_sizing, {
    "compute": {
      "vm_size": "Standard_D4s_v3",
      "accelerated_networking": false
    },
    "storage": [{
      "name": "data",
      "disk_type": "Premium_LRS",
      "size_gb": 512,
      "caching": "None",
      "write_accelerator": false
    }]
  })

  web_sizing = lookup(local.sizes.web, local.vm_sizing, {
    "compute": {
      "vm_size": "Standard_D4s_v3",
      "accelerated_networking": false
    },
    "storage": [{
      "name": "data",
      "disk_type": "Premium_LRS",
      "size_gb": 512,
      "caching": "None",
      "write_accelerator": false
    }]
  })

  # Ports used for specific ASCS, ERS and Web dispatcher
  lb-ports = {
    "scs" = [
      3200 + tonumber(local.scs_instance_number),          # e.g. 3201
      3600 + tonumber(local.scs_instance_number),          # e.g. 3601
      3900 + tonumber(local.scs_instance_number),          # e.g. 3901
      8100 + tonumber(local.scs_instance_number),          # e.g. 8101
      50013 + (tonumber(local.scs_instance_number) * 100), # e.g. 50113
      50014 + (tonumber(local.scs_instance_number) * 100), # e.g. 50114
      50016 + (tonumber(local.scs_instance_number) * 100), # e.g. 50116
    ]

    "ers" = [
      3200 + tonumber(local.ers_instance_number),          # e.g. 3202
      3300 + tonumber(local.ers_instance_number),          # e.g. 3302
      50013 + (tonumber(local.ers_instance_number) * 100), # e.g. 50213
      50014 + (tonumber(local.ers_instance_number) * 100), # e.g. 50214
      50016 + (tonumber(local.ers_instance_number) * 100), # e.g. 50216
    ]

    "web" = [
      80,
      3200
    ]
  }

  # Ports used for ASCS, ERS and Web dispatcher NSG rules
  nsg-ports = {
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

  # Ports used for the health probes.
  # Where Instance Number is nn:
  # SCS (index 0) - 620nn
  # ERS (index 1) - 621nn
  hp-ports = [
    62000 + tonumber(local.scs_instance_number),
    62100 + tonumber(local.ers_instance_number)
  ]

  # Create list of disks per VM
  app-data-disks = flatten([
    for vm_count in range(var.application.application_server_count) : [
      for disk_spec in local.app_sizing.storage : {
        vm_index          = vm_count
        name              = "${upper(var.application.sid)}_app${format("%02d", vm_count)}-${disk_spec.name}"
        disk_type         = lookup(disk_spec, "disk_type", "Premium_LRS")
        size_gb           = lookup(disk_spec, "size_gb", 512)
        caching           = lookup(disk_spec, "caching", false)
        write_accelerator = lookup(disk_spec, "write_accelerator", false)
      }
    ]
  ])

  scs-data-disks = flatten([
    for vm_count in (var.application.scs_high_availability ? range(2) : range(1)) : [
      for disk_spec in local.scs_sizing.storage : {
        vm_index          = vm_count
        name              = "${upper(var.application.sid)}_scs${format("%02d", vm_count)}-${disk_spec.name}"
        disk_type         = lookup(disk_spec, "disk_type", "Premium_LRS")
        size_gb           = lookup(disk_spec, "size_gb", 512)
        caching           = lookup(disk_spec, "caching", false)
        write_accelerator = lookup(disk_spec, "write_accelerator", false)
      }
    ]
  ])

  web-data-disks = flatten([
    for vm_count in range(var.application.webdispatcher_count) : [
      for disk_spec in local.web_sizing.storage : {
        vm_index          = vm_count
        name              = "${upper(var.application.sid)}_web${format("%02d", vm_count)}-${disk_spec.name}"
        disk_type         = lookup(disk_spec, "disk_type", "Premium_LRS")
        size_gb           = lookup(disk_spec, "size_gb", 512)
        caching           = lookup(disk_spec, "caching", false)
        write_accelerator = lookup(disk_spec, "write_accelerator", false)
      }
    ]
  ])
}
