variable "name" {
  type        = string
  description = "The short name of any Azure resource"
  default     = "unknown"
}

variable "location" {
  type        = string
  description = "The Azure region name"
  default     = "eastus"
}

# mainly a set of testing defaults for now
locals {
  short_name = lower(var.name)
  env = "PRD"
  loc = upper("${var.region_mapping["${var.location}"]}")
  net = "VNT"
  cnm = "DEV0"
  trk = "S4"
  sid = "Z00"
}

# The following is taken from the Microsoft internal specification document:
#   Naming Conventions for SAP Automation v0.3
variable "region_mapping" {
    type        = map(string)
    description = "Region Mapping: Full = Single CHAR, 4-CHAR"
    # 28 Regions
    default     = {
                    westus              = "weus"
                    westus2             = "wus2"
                    centralus           = "ceus"
                    eastus              = "eaus"
                    eastus2             = "eus2"
                    northcentralus      = "ncus"
                    southcentralus      = "scus"
                    westcentralus       = "wcus"
                    northeurope         = "noeu"
                    westeurope          = "weeu"
                    eastasia            = "eaas"
                    southeastasia       = "seas"
                    brazilsouth         = "brso"
                    japaneast           = "jpea"
                    japanwest           = "jpwe"
                    centralindia        = "cein"
                    southindia          = "soin"
                    westindia           = "wein"
                    uksouth2            = "uks2"
                    uknorth             = "ukno"
                    canadacentral       = "cace"
                    canadaeast          = "caea"
                    australiaeast       = "auea"
                    australiasoutheast  = "ause"
                    uksouth             = "ukso"
                    ukwest              = "ukwe"
                    koreacentral        = "koce"
                    koreasouth          = "koso"
    }
}
