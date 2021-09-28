/*

This block describes the variable for the infrastructure block in the json file

*/

variable "environment" {
  type        = string
  description = "This is the environment name of the deployer"
  default     = ""
}

variable "codename" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = ""
}

variable "resourcegroup_name" {
  default = ""
}

variable "resourcegroup_arm_id" {
  default = ""
}

variable "resourcegroup_tags" {
  default = {}
}

variable "proximityplacementgroup_names" {
  default = []
}

variable "proximityplacementgroup_arm_ids" {
  default = []
}




/*

This block describes the variables for the VNet block in the json file

*/

variable "network_name" {
  default = ""
}

variable "network_arm_id" {
  default = ""
}

variable "network_address_space" {
  default = ""
}

/* admin subnet information */

variable "admin_subnet_name" {
  default = ""
}

variable "admin_subnet_arm_id" {
  default = ""
}

variable "admin_subnet_address_prefix" {
  default = ""
}

variable "admin_subnet_nsg_name" {
  default = ""
}

variable "admin_subnet_nsg_arm_id" {
  default = ""
}

/* db subnet information */

variable "db_subnet_name" {
  default = ""
}

variable "db_subnet_arm_id" {
  default = ""
}

variable "db_subnet_address_prefix" {
  default = ""
}

variable "db_subnet_nsg_name" {
  default = ""
}

variable "db_subnet_nsg_arm_id" {
  default = ""
}

/* app subnet information */

variable "app_subnet_name" {
  default = ""
}

variable "app_subnet_arm_id" {
  default = ""
}

variable "app_subnet_address_prefix" {
  default = ""
}

variable "app_subnet_nsg_name" {
  default = ""
}

variable "app_subnet_nsg_arm_id" {
  default = ""
}

/* web subnet information */

variable "web_subnet_name" {
  default = ""
}

variable "web_subnet_arm_id" {
  default = ""
}

variable "web_subnet_address_prefix" {
  default = ""
}

variable "web_subnet_nsg_name" {
  default = ""
}

variable "web_subnet_nsg_arm_id" {
  default = ""
}

variable "deploy_anchor_vm" {
  default = false
}

variable "anchor_vm_sku" {
  default = ""
}

variable "anchor_vm_use_DHCP" {
  default = false
}

variable "anchor_vm_image" {
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = "SUSE"
    "offer"           = "sles-sap-12-sp5"
    "sku"             = "gen1"
    "version"         = ""
  }
}

variable "anchor_vm_authentication_type" {
  default = "key"
}

variable "anchor_vm_authentication_username" {
  default = "azureadm"
}


variable "anchor_vm_nic_ips" {
  default = []
}

variable "anchor_vm_accelerated_networking" {
  default = true
}
/*
This block describes the variables for the key_vault section block in the json file
*/


variable "user_keyvault_id" {
  default = ""
}

variable "automation_keyvault_id" {
  default = ""
}

variable "spn_keyvault_id" {
  default = ""
}

/*
This block describes the variables for the authentication section block in the json file
*/


variable "automation_username" {
  default = ""
}

variable "automation_password" {
  default = ""
}

variable "automation_path_to_public_key" {
  default = ""
}

variable "automation_path_to_private_key" {
  default = ""
}

/*

Database

*/

variable "database_vm_authentication_type" {
  default = "key"
}

variable "database_vm_avset_arm_ids" {
  default = []
}

variable "database_vm_image" {
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

variable "database_high_availability" {
  default = false
}

variable "database_vm_use_DHCP" {
  default = false
}

variable "database_platform" {
  default = ""
}

variable "database_size" {
  default = ""
}

variable "database_sid" {
  default = "HDB"
}

variable "database_instance_number" {
  default = "01"
}


variable "database_vm_zones" {
  default = []
}

variable "database_no_avset" {
  default = false
}

variable "database_dual_nics" {
  default = false
}

variable "database_no_ppg" {
  default = false
}

variable "database_loadbalancer_ip" {
  default = ""
}

variable "database_tags" {
  default = {}
}

variable "database_vm_nodes" {
  default = [{
    "name"            = ""
    "db_nic_ips"      = ["", ""]
    "admin_nic_ips"   = ["", ""]
    "storage_nic_ips" = ["", ""]
  }]
}

variable "database_HANA_use_ANF_scaleout_scenario" {
  default = false
}

/*

Application tier

*/

variable "enable_app_tier_deployment" {
  default = true
}

variable "app_tier_authentication_type" {
  default = "key"
}

variable "sid" {
  default = ""
}

variable "app_tier_use_DHCP" {
  default = false
}

variable "app_tier_dual_nics" {
  default = false
}

variable "app_tier_vm_sizing" {
  default = ""
}

variable "application_server_count" {
  default = 0
}

variable "application_server_app_nic_ips" {
  default = []
}

variable "application_server_admin_nic_ips" {
  default = []
}

variable "application_server_sku" {
  default = ""
}

variable "application_server_tags" {
  default = {}
}

variable "application_server_zones" {
  default = []
}

variable "application_server_no_avset" {
  default = false
}

variable "application_server_no_ppg" {
  default = false
}

variable "application_server_image" {
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

variable "webdispatcher_server_count" {
  default = 0
}

variable "webdispatcher_server_app_nic_ips" {
  default = []
}

variable "webdispatcher_server_admin_nic_ips" {
  default = []
}

variable "webdispatcher_server_loadbalancer_ips" {
  default = []
}

variable "webdispatcher_server_sku" {
  default = ""
}

variable "webdispatcher_server_tags" {
  default = {}
}

variable "webdispatcher_server_zones" {
  default = []
}

variable "webdispatcher_server_no_avset" {
  default = false
}

variable "webdispatcher_server_no_ppg" {
  default = false
}

variable "webdispatcher_server_image" {
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}


variable "scs_server_count" {
  default = 0
}

variable "scs_server_app_nic_ips" {
  default = []
}

variable "scs_server_admin_nic_ips" {
  default = []
}

variable "scs_server_loadbalancer_ips" {
  default = []
}

variable "scs_server_sku" {
  default = ""
}

variable "scs_server_tags" {
  default = {}
}

variable "scs_server_zones" {
  default = []
}

variable "scs_server_no_avset" {
  default = false
}

variable "scs_server_no_ppg" {
  default = false
}

variable "scs_server_image" {
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

variable "scs_high_availability" {
  default = false
}

variable "scs_instance_number" {
  default = "01"
}

variable "ers_instance_number" {
  default = "02"
}

/* 
Misc settings


*/
variable "resource_offset" {
  default = 0
}

variable "vm_disk_encryption_set_id" {
  default = ""
}

variable "nsg_asg_with_vnet" {
  default = false
}

variable "legacy_nic_order" {
  default = false
}

variable "enable_purge_control_for_keyvaults" {
  default = true
}

#ANF Settings

variable "anf_sapmnt_volume_size" {
  default = 512
}

variable "anf_transport_volume_size" {
  default = 512
}

variable "use_ANF" {
  default = false
}


variable "use_loadbalancers_for_standalone_deployments" {
  default = true
}

variable "hana_dual_nics" {
  default = true
}


