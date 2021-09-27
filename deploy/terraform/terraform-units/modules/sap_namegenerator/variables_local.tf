
variable "environment" {
  description = "Environment type (Prod, Test, Sand, QA)"
}

variable "library_environment" {
  description = "SAP Library environment type (Prod, Test, Sand, QA)"
  default     = ""
}

variable "deployer_environment" {
  description = "Deployer environment type (Prod, Test, Sand, QA)"
  default     = ""
}

variable "landscape_environment" {
  description = "Landscape environment type (Prod, Test, Sand, QA)"
  default     = ""
}

variable "location" {
  description = "Azure region"
}

variable "codename" {
  description = "Code name of application (optional)"
  default     = ""
}

variable "management_vnet_name" {
  description = "Name of Management vnet"
  default     = ""
}

variable "sap_vnet_name" {
  description = "Name of SAP vnet"
  default     = ""
}

variable "sap_sid" {
  description = "SAP SID"
  default     = ""
}

variable "db_sid" {
  description = "Database SID"
  default     = ""
}

variable "random_id" {
  type        = string
  description = "Random hex string"
}

variable "db_ostype" {
  description = "Database operating system"
  default     = "LINUX"
}

variable "app_ostype" {
  description = "Application Server operating system"
  default     = "LINUX"
}

variable "db_platform" {
  description = "AnyDB platform type (Oracle, DB2, SQLServer, ASE)"
  default     = "LINUX"
}

variable "anchor_ostype" {
  description = "Anchor Server operating system"
  default     = "LINUX"
}

variable "app_server_count" {
  type    = number
  default = 1
}

variable "scs_server_count" {
  type    = number
  default = 1
}

variable "web_server_count" {
  type    = number
  default = 1
}


variable "db_server_count" {
  type    = number
  default = 1
}

variable "iscsi_server_count" {
  type    = number
  default = 1
}

variable "deployer_vm_count" {
  type    = number
  default = 1
}

variable "resource_offset" {
  type    = number
  default = 0
}

//Todo: Add to documentation
variable "sapautomation_name_limits" {
  description = "Name length for automation resources"
  default = {
    environment_variable_length = 5
    sap_vnet_length             = 7
    random_id_length            = 3
    sdu_name_length             = 80
  }
}

//Todo: Add to documentation
variable "azlimits" {
  description = "Name length for resources"
  default = {
    asr         = 50
    aaa         = 50
    acr         = 49
    afw         = 50
    rg          = 80
    kv          = 24
    stgaccnt    = 24
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

variable "region_mapping" {
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
    "eastus2"            = "eus2"
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
variable "resource_suffixes" {
  type        = map(string)
  description = "Extension of resource name"

  default = {
    "admin_nic"                    = "-admin-nic"
    "admin_subnet"                 = "admin-subnet"
    "admin_subnet_nsg"             = "adminSubnet-nsg"
    "ansible"                      = "ansible"
    "anf_subnet"                   = "anf-subnet"
    "anf_subnet_nsg"               = "anfSubnet-nsg"
    "app_alb"                      = "app-alb"
    "app_asg"                      = "app-asg"
    "app_avset"                    = "app-avset"
    "app_subnet"                   = "app-subnet"
    "app_subnet_nsg"               = "appSubnet-nsg"
    "db_alb"                       = "db-alb"
    "db_alb_bepool"                = "dbAlb-bePool"
    "db_alb_feip"                  = "dbAlb-feip"
    "db_alb_hp"                    = "dbAlb-hp"
    "db_alb_rule"                  = "dbAlb-rule_"
    "db_asg"                       = "db-asg"
    "db_avset"                     = "db-avset"
    "db_nic"                       = "-db-nic"
    "db_subnet"                    = "db-subnet"
    "db_subnet_nsg"                = "dbSubnet-nsg"
    "deployer_rg"                  = "-INFRASTRUCTURE"
    "deployer_state"               = "_DEPLOYER.terraform.tfstate"
    "deployer_subnet"              = "_deployment-subnet"
    "deployer_subnet_nsg"          = "_deployment-nsg"
    "dns_link"                     = "dns-link"
    "fencing_agent_spn"            = "fencing-agent"
    "fencing_agent_id"             = "-fencing-spn-id"
    "fencing_agent_pwd"            = "-fencing-spn-pwd"
    "fencing_agent_tenant"         = "-fencing-spn-tenant"
    "fencing_agent_sub"            = "-fencing-spn-subscription"
    "firewall_rule_db"             = "firewall-rule-db"
    "firewall_rule_app"            = "firewall-rule-app"
    "fw_route"                     = "firewall-route"
    "iscsi_subnet"                 = "iscsi-subnet"
    "iscsi_subnet_nsg"             = "iscsiSubnet-nsg"
    "library_rg"                   = "-SAP_LIBRARY"
    "library_state"                = "_SAP-LIBRARY.terraform.tfstate"
    "keyvault_private_link"        = "-keyvault-privatelink"
    "keyvault_private_svc"         = "-keyvault-privateservice"
    "kv"                           = ""
    "msi"                          = "-msi"
    "netapp_account"               = "netapp_account"
    "netapp_pool"                  = "netapp_pool"
    "nic"                          = "-nic"
    "osdisk"                       = "-OsDisk"
    "pip"                          = "-pip"
    "ppg"                          = "-ppg"
    "routetable"                   = "route-table"
    "sapbits"                      = "sapbits"
    "sapmnt"                       = "sapmnt"
    "storage_private_link_diag"    = "-diag-storage-privatelink"
    "storage_private_svc_diag"     = "-diag-storage-privateservice"
    "storage_private_link_sap"     = "-sap-storage-privatelink"
    "storage_private_svc_sap"      = "-sap-storage-privateservice"
    "storage_private_link_tf"      = "-tf-storage-privatelink"
    "storage_private_svc_tf"       = "-tf-storage-privateservice"
    "storage_private_link_witness" = "-witness-storage-privatelink"
    "storage_private_svc_witness"  = "-witness-storage-privateservice"
    "storage_nic"                  = "-storage-nic"
    "storage_subnet"               = "_storage-subnet"
    "storage_subnet_nsg"           = "_storageSubnet-nsg"
    "scs_alb"                      = "scs-alb"
    "scs_alb_bepool"               = "scsAlb-bePool"
    "scs_alb_feip"                 = "scsAlb-feip"
    "scs_alb_hp"                   = "scsAlb-hp"
    "scs_alb_rule"                 = "scsAlb-rule_"
    "scs_avset"                    = "scs-avset"
    "scs_clst_feip"                = "scsClst-feip"
    "scs_clst_rule"                = "scsClst-rule"
    "scs_clst_hp"                  = "scsClst-hp"
    "scs_ers_feip"                 = "scsErs-feip"
    "scs_ers_hp"                   = "scsErs-hp"
    "scs_ers_rule"                 = "scsErs-rule"
    "scs_fs_feip"                  = "scsFs-feip"
    "scs_fs_hp"                    = "scsFs-hp"
    "scs_fs_rule"                  = "scsFs-rule"
    "scs_scs_rule"                 = "scsScs-rule_"
    "sdu_rg"                       = ""
    "tfstate"                      = "tfstate"
    "transport_volume"             = "transport"
    "vm"                           = ""
    "vnet"                         = "-vnet"
    "vnet_rg"                      = "-INFRASTRUCTURE"
    "web_alb"                      = "web-alb"
    "web_alb_bepool"               = "webAlb-bePool"
    "web_alb_feip"                 = "webAlb-feip"
    "web_alb_hp"                   = "webAlb-hp"
    "web_alb_inrule"               = "webAlb-inRule"
    "web_asg"                      = "web-asg"
    "web_avset"                    = "web-avset"
    "web_subnet"                   = "web-subnet"
    "web_subnet_nsg"               = "webSubnet-nsg"
    "witness"                      = "-witness"
    "witness_accesskey"            = "-witness-accesskey"
    "witness_name"                 = "-witness-name"
  }
}

variable "app_zones" {
  type        = list(string)
  description = "List of availability zones for application tier"
  default     = []
}

variable "scs_zones" {
  type        = list(string)
  description = "List of availability zones for scs tier"
  default     = []
}

variable "web_zones" {
  type        = list(string)
  description = "List of availability zones for web tier"
  default     = []
}

variable "db_zones" {
  type        = list(string)
  description = "List of availability zones for db tier"
  default     = []
}

variable "custom_prefix" {
  type        = string
  description = "Custom prefix"
  default     = ""
}

variable "deployer_location" {
  description = "Deployer Azure region"
  default     = ""
}

locals {

  location_short = upper(try(var.region_mapping[var.location], "unkn"))

  deployer_location_short = length(var.deployer_location) > 0 ? upper(try(var.region_mapping[var.deployer_location], "unkn")) : local.location_short

  // If no deployer environment provided use environment
  deployer_environment_temp = length(var.deployer_environment) > 0 ? var.deployer_environment : var.environment

  // If no landscape environment provided use environment
  landscape_environment_temp = length(var.landscape_environment) > 0 ? var.landscape_environment : var.environment

  // If no library environment provided use environment
  library_environment_temp = length(var.library_environment) > 0 ? var.library_environment : var.environment

  deployer_env_verified  = upper(substr(local.deployer_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))
  env_verified           = upper(substr(var.environment, 0, var.sapautomation_name_limits.environment_variable_length))
  landscape_env_verified = upper(substr(local.landscape_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))
  library_env_verified   = upper(substr(local.library_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))

  sap_vnet_verified = upper(trim(substr(replace(var.sap_vnet_name, "/[^A-Za-z0-9]/", ""), 0, var.sapautomation_name_limits.sap_vnet_length), "-_"))
  dep_vnet_verified = upper(trim(substr(replace(var.management_vnet_name, "/[^A-Za-z0-9]/", ""), 0, var.sapautomation_name_limits.sap_vnet_length), "-_"))

  random_id_verified    = upper(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))
  random_id_vm_verified = lower(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))

  zones            = distinct(concat(var.db_zones, var.app_zones, var.scs_zones, var.web_zones))
  zonal_deployment = try(length(local.zones), 0) > 0 ? true : false

  //The separator to use between the prefix and resource name
  separator = "_"

}
