variable "resource-group" {
  description = "Details of the resource group"
}

variable "vnet-sap" {
  description = "Details of the SAP VNet"
}

variable "app-tier" {
  description = "Details of the SAP Application Tier"
  default = [{
    scs-instance-number = "01"
    ers-instance-number = "02"
  }]
}

variable "storage-bootdiag" {
  description = "Details of the boot diagnostic storage device"
}

locals {
  # Filter the list of databases to only HANA platform entries
  hana-databases = [
    for database in var.databases : database
    if database.platform == "HANA"
  ]

  sid = local.hana-databases[0].instance.sid

  # Ports used for specific ASCS and ERS
  lb-ports = {
    "scs" = [
      3200 + tonumber(var.app-tier[0].scs-instance-number),           # e.g. 3201
      3600 + tonumber(var.app-tier[0].scs-instance-number),           # e.g. 3601
      3900 + tonumber(var.app-tier[0].scs-instance-number),           # e.g. 3901
      8100 + tonumber(var.app-tier[0].scs-instance-number),           # e.g. 8101
      50013 + (tonumber(var.app-tier[0].scs-instance-number) * 100),  # e.g. 50113
      50014 + (tonumber(var.app-tier[0].scs-instance-number) * 100),  # e.g. 50114
      50016 + (tonumber(var.app-tier[0].scs-instance-number) * 100),  # e.g. 50116
    ]

    "ers" = [
      3200 + tonumber(var.app-tier[0].ers-instance-number),          # e.g. 3202
      3300 + tonumber(var.app-tier[0].ers-instance-number),          # e.g. 3302
      50013 + (tonumber(var.app-tier[0].ers-instance-number) * 100), # e.g. 50213
      50014 + (tonumber(var.app-tier[0].ers-instance-number) * 100), # e.g. 50214
      50016 + (tonumber(var.app-tier[0].ers-instance-number) * 100), # e.g. 50216
    ]
  }

  # Ports used for the health probes.
  # Where Instance Number is nn:
  # SCS (index 0) - 620nn
  # ERS (index 1) - 621nn
  hp-ports = [
    62000 + tonumber(var.app-tier[0].scs-instance-number),
    62100 + tonumber(var.app-tier[0].ers-instance-number)
  ]
}
