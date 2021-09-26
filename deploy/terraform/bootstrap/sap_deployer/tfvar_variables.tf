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

variable "management_network_name" {
  default = ""
}

variable "management_network_arm_id" {
  default = ""
}

variable "management_network_address_space" {
  default = ""
}

variable "management_subnet_name" {
  default = ""
}

variable "management_subnet_arm_id" {
  default = ""
}

variable "management_subnet_address_prefix" {
  default = ""
}

variable "management_firewall_subnet_arm_id" {
  default = ""
}

variable "management_firewall_subnet_address_prefix" {
  default = ""
}

variable "management_subnet_nsg_name" {
  default = ""
}

variable "management_subnet_nsg_arm_id" {
  default = ""
}

variable "management_subnet_nsg_allowed_ips" {
  default = []
}

/*

This block describes the variables for the deployer section block in the json file

*/

variable "deployer_size" {
  default = ""
}

variable "deployer_disk_type" {
  default = "Premium_LRS"
}

variable "deployer_use_DHCP" {
  default = false
}

/*
This block describes the variables for the deployer OS section block in the json file
*/

variable "deployer_image" {
  default = {
    "source_image_id" = ""
    "publisher"       = "Canonical"
    "offer"           = "0001-com-ubuntu-server-focal"
    "sku"             = "20_04-lts"
    "version"         = "latest"
  }
}

variable "deployer_private_ip_address" {
  default = ""
}

/*
This block describes the variables for the authentication section block in the json file
*/

variable "deployer_authentication_type" {
  default = "key"
}

variable "deployer_authentication_username" {
  default = "azureadm"
}

variable "deployer_authentication_password" {
  default = ""
}

variable "deployer_authentication_path_to_public_key" {
  default = ""
}

variable "deployer_authentication_path_to_private_key" {
  default = ""
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

variable "deployer_private_key_secret_name" {
  default = ""
}

variable "deployer_public_key_secret_name" {
  default = ""
}

variable "deployer_username_secret_name" {
  default = ""
}

variable "deployer_password_secret_name" {
  default = ""
}


/*
This block describes the variables for the options section block in the json file
*/

variable "deployer_enable_public_ip" {
  default = false
}

variable "firewall_deployment" {
  description = "Boolean flag indicating if an Azure Firewall should be deployed"
  default     = false
}

variable "firewall_rule_subnets" {
  description = "List of subnets that are part of the firewall rule"
  default     = null
}

variable "firewall_allowed_ipaddresses" {
  description = "List of allowed IP addresses to be part of the firewall rule"
  default     = null
}

variable "deployer_assign_subscription_permissions" {
  default = false
}

variable "use_private_endpoint" {
  default = false
}