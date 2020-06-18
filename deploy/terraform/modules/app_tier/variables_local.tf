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

locals {
  enable_deployment = lookup(var.application, "enable_deployment", false)

  scs_instance_number = lookup(var.application, "scs_instance_number", "01")
  ers_instance_number = lookup(var.application, "ers_instance_number", "02")

  # Subnet IP Offsets
  # Note: First 4 IP addresses in a subnet are reserved by Azure
  ip_offsets = {
    scs_lb = 4 + 1
    scs_vm = 4 + 6
    app_vm = 4 + 10
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
  app_sku_map = merge(
    {
      app = "Standard_D4s_v3,false"
      scs = "Standard_D4s_v3,false"
    },
    lookup(var.application, "vm_config", {})
  )

  app_vm_size                    = element(split(",", lookup(local.app_sku_map, "app", false)), 0)
  app_nic_accelerated_networking = element(split(",", lookup(local.app_sku_map, "app", false)), 1)

  scs_vm_size                    = element(split(",", lookup(local.app_sku_map, "scs", false)), 0)
  scs_nic_accelerated_networking = element(split(",", lookup(local.app_sku_map, "scs", false)), 1)


  # Ports used for specific ASCS and ERS
  lb-ports = {
    "scs" = [
      3200 + tonumber(local.scs_instance_number),           # e.g. 3201
      3600 + tonumber(local.scs_instance_number),           # e.g. 3601
      3900 + tonumber(local.scs_instance_number),           # e.g. 3901
      8100 + tonumber(local.scs_instance_number),           # e.g. 8101
      50013 + (tonumber(local.scs_instance_number) * 100),  # e.g. 50113
      50014 + (tonumber(local.scs_instance_number) * 100),  # e.g. 50114
      50016 + (tonumber(local.scs_instance_number) * 100),  # e.g. 50116
    ]

    "ers" = [
      3200 + tonumber(local.ers_instance_number),          # e.g. 3202
      3300 + tonumber(local.ers_instance_number),          # e.g. 3302
      50013 + (tonumber(local.ers_instance_number) * 100), # e.g. 50213
      50014 + (tonumber(local.ers_instance_number) * 100), # e.g. 50214
      50016 + (tonumber(local.ers_instance_number) * 100), # e.g. 50216
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

  # Define options for Data Disks
  data-disk = {
    size_gb           = 512
    disk_type         = "Premium_LRS"
    caching           = "None"
    write_accelerator = false
  }
}
