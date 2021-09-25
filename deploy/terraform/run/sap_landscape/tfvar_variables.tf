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


/* ANF subnet information */

variable "anf_subnet_name" {
  default = ""
}

variable "anf_subnet_arm_id" {
  default = ""
}

variable "anf_subnet_address_prefix" {
  default = ""
}

variable "anf_subnet_nsg_name" {
  default = ""
}

variable "anf_subnet_nsg_arm_id" {
  default = ""
}

/* iscsi subnet information */

variable "iscsi_subnet_name" {
  default = ""
}

variable "iscsi_subnet_arm_id" {
  default = ""
}

variable "iscsi_subnet_address_prefix" {
  default = ""
}

variable "iscsi_subnet_nsg_name" {
  default = ""
}

variable "iscsi_subnet_nsg_arm_id" {
  default = ""
}

variable "iscsi_count" {
  default = 0
}

variable "iscsi_size" {
  default = ""
}

variable "iscsi_useDHCP" {
  default = false
}

variable "iscsi_image" {
  default = {
    "source_image_id" = ""
    "publisher"       = "SUSE"
    "offer"           = "sles-sap-12-sp5"
    "sku"             = "gen1"
    "version"         = "latest"
  }
}

variable "iscsi_authentication_type" {
  default = "key"
}

variable "iscsi_authentication_username" {
  default = "azureadm"
}


variable "iscsi_nic_ips" {
  default = []
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
  default = "azureadm"
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

variable "diagnostics_storage_account_arm_id" {
  default = ""
}


variable "witness_storage_account_arm_id" {
  default = ""
}

variable "create_fencing_spn" {
  default = false
}

variable "enable_purge_control_for_keyvaults" {
  default = true
}

variable "use_private_endpoint" {
  default = false
}