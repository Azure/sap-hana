
variable environment {
  description = "Environment type (Prod, Test, Sand, QA)"
}

variable location {
  description = "Azure region"
}

variable codename {
  description = "Code name of application (optional)"
  default     = ""
}

variable management_vnet_name {
  description = "Name of Management vnet"
  default     = ""
}

variable sap_vnet_name {
  description = "Name of SAP vnet"
  default     = ""
}

variable sap_sid {
  description = "SAP SID"
  default     = ""
}

variable db_sid {
  description = "Database SID"
  default     = ""
}

variable random_id {
  type        = string
  description = "Random hex string"
}

variable db_ostype {
  description = "Database operating system"
  default     = "LINUX"
}

variable app_ostype {
  description = "Application Server operating system"
  default     = "LINUX"
}

variable db_platform {
  description = "AnyDB platform type (Oracle, DB2, SQLServer, ASE)"
  default     = "LINUX"
}

variable app_server_count {
  type    = number
  default = 1
}

variable scs_server_count {
  type    = number
  default = 1
}

variable web_server_count {
  type    = number
  default = 1
}


variable db_server_count {
  type    = number
  default = 1
}

variable iscsi_server_count {
  type    = number
  default = 1
}

variable deployer_vm_count {
  type    = number
  default = 1
}

//Todo: Add to documentation
variable sapautomation_name_limits {
  description = "Name length for automation resources"
  default = {
    environment_variable_length = 5
    sap_vnet_length             = 7
    random_id_length            = 3
    sdu_name_length             = 80
  }
}

//Todo: Add to documentation
variable azlimits {
  description = "Name length for resources"
  default = {
    asr         = 50
    aaa         = 50
    acr         = 49
    afw         = 50
    rg          = 80
    kv          = 24
    st          = 24
    vnet        = 38
    nsg         = 80
    snet        = 80
    nic         = 80
    vml         = 64
    vmw         = 15
    vm          = 80
    functionapp = 60
    lb          = 80
    lbrule      = 80
    evh         = 50
    la          = 63
    pip         = 80
    peer        = 80
    gen         = 24
  }
}

variable region_mapping {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"
  # 42 Regions 
  default = {
    "australiacentral"   = "auce"
    "australiacentral2"  = "auc2"
    "australiaeast"      = "auea"
    "australiasoutheast" = "ause"
    "brazilsouth"        = "brso"
    "brazilsoutheast"    = "brse"
    "brazilus"           = "brus"
    "canadacentral"      = "cace"
    "canadaeast"         = "caea"
    "centralindia"       = "cein"
    "centralus"          = "ceus"
    "eastasia"           = "eaas"
    "eastus"             = "eaus"
    "eastus2"            = "eau2"
    "francecentral"      = "frce"
    "francesouth"        = "frso"
    "germanynorth"       = "geno"
    "germanywestcentral" = "gewc"
    "japaneast"          = "jaea"
    "japanwest"          = "jawe"
    "koreacentral"       = "koce"
    "koreasouth"         = "koso"
    "northcentralus"     = "ncus"
    "northeurope"        = "noeu"
    "norwayeast"         = "noea"
    "norwaywest"         = "nowe"
    "southafricanorth"   = "sano"
    "southafricawest"    = "sawe"
    "southcentralus"     = "scus"
    "southeastasia"      = "soea"
    "southindia"         = "soin"
    "switzerlandnorth"   = "swno"
    "switzerlandwest"    = "swwe"
    "uaecentral"         = "uace"
    "uaenorth"           = "uano"
    "uksouth"            = "ukso"
    "ukwest"             = "ukwe"
    "westcentralus"      = "wcus"
    "westeurope"         = "weeu"
    "westindia"          = "wein"
    "westus"             = "weus"
    "westus2"            = "wus2"
  }
}

//Todo: Add to documentation
variable resource_suffixes {
  type        = map(string)
  description = "Extension of resource name"

  default = {
    "admin-nic"           = "-admin-nic"
    "admin-subnet"        = "_admin-subnet"
    "admin-subnet-nsg"    = "_adminSubnet-nsg"
    "app-alb"             = "_app-alb"
    "app-avset"           = "_app-avset"
    "app-subnet"          = "_app-subnet"
    "app-subnet-nsg"      = "_appSubnet-nsg"
    "db-alb"              = "_db-alb"
    "db-alb-feip"         = "_db-alb-feip"
    "db-alb-bepool"       = "_db-alb-bepool"
    "db-alb-hp"           = "_db-alb-hp"
    "db-avset"            = "_db-avset"
    "db-nic"              = "-db-nic"
    "db-subnet"           = "_db-subnet"
    "db-subnet-nsg"       = "_dbSubnet-nsg"
    "deployer-rg"         = "-INFRASTRUCTURE"
    "deployer-state"      = "_DEPLOYER.terraform.tfstate"
    "deployer-subnet"     = "_deployment-subnet"
    "deployer-subnet-nsg" = "_deployment-nsg"
    "iscsi-subnet"        = "_iscsi-subnet"
    "iscsi-subnet-nsg"    = "_iscsiSubnet-nsg"
    "library-rg"          = "-SAP_LIBRARY"
    "library-state"       = "_SAP-LIBRARY.terraform.tfstate"
    "kv"                  = ""
    "msi"                 = "-msi"
    "nic"                 = "-nic"
    "osdisk"              = "-OsDisk"
    "pip"                 = "-pip"
    "ppg"                 = "-ppg"
    "scs-alb"             = "_scs-alb"
    "scs-alb-bepool"      = "_scs-alb-bepool"
    "scs-alb-feip"        = "_scs-alb-feip"
    "scs-alb-hp"          = "_scs-alb-hp"
    "scs-ers-feip"        = "_scs-ers-feip"
    "scs-ers-hp"          = "_scs-ers-hp"
    "sdu-rg"              = ""
    "scs-avset"           = "_scs-avset"
    "vm"                  = ""
    "vnet"                = "-vnet"
    "vnet-rg"             = "-INFRASTRUCTURE"
    "web-alb"             = "_web-alb"
    "web-alb-feip"        = "_web-alb-feip"
    "web-alb-bepool"      = "_web-alb-bepool"
    "web-avset"           = "_web-avset"
    "web-subnet"          = "_web-subnet"
    "web-subnet-nsg"      = "_webSubnet-nsg"
  }
}

locals {
  location_short = upper(try(var.region_mapping[var.location], "unkn"))

  env_verified      = upper(substr(var.environment, 0, var.sapautomation_name_limits.environment_variable_length))
  vnet_verified     = upper(substr(var.sap_vnet_name, 0, var.sapautomation_name_limits.sap_vnet_length))
  dep_vnet_verified = upper(substr(var.management_vnet_name, 0, var.sapautomation_name_limits.sap_vnet_length))

  random_id_verified    = upper(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))
  random_id_vm_verified = lower(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))

}

