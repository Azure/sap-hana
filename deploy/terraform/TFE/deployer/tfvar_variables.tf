# This block describes the variable for the infrastructure block in the json file
#
variable "environment" {
                                                            default         = ""
                                                            type            = string
                                                            description     = "This is the environment name of the deployer"
}
variable "codename" {
                                                            default         = ""
                                                            type            = string
}
variable "location" {
                                                            default         = ""
                                                            type            = string
}
variable "resourcegroup_name"                           {   default         = ""                    }
variable "resourcegroup_arm_id"                         {   default         = ""                    }


# This block describes the variables for the VNet block in the json file
#
variable "management_network_name"                      {   default         = ""                    }
variable "management_network_arm_id"                    {   default         = ""                    }
variable "management_network_address_space"             {   default         = ""                    }
variable "management_subnet_name"                       {   default         = ""                    }
variable "management_subnet_arm_id"                     {   default         = ""                    }
variable "management_subnet_address_prefix"             {   default         = ""                    }
variable "management_firewall_subnet_arm_id"            {   default         = ""                    }
variable "management_firewall_subnet_address_prefix"    {   default         = ""                    }
variable "deployer_sub_mgmt_nsg_name"                   {   default         = ""                    }
variable "management_subnet_nsg_arm_id"                 {   default         = ""                    }
variable "management_subnet_nsg_allowed_ips"            {   default         = []                    }


# This block describes the variables for the deployes section block in the json file
#
variable "vm_size"                                      {   default         = "Standard_D4ds_v4"    }
variable "vm_disk_type"                                 {   default         = "Premium_LRS"         }
variable "use_DHCP"                                     {   default         = null                  }


# This block describes the variables for the deployer OS section block in the json file
#
variable "private_ip_address"                           {   default         = ""                    }
variable "vm_image" {
                                                            default = {
                                                              "source_image_id" = ""
                                                              "publisher"       = "Canonical"
                                                              "offer"           = "0001-com-ubuntu-server-focal"
                                                              "sku"             = "20_04-lts"
                                                              "version"         = "latest"
                                                            }
}


# This block describes the variables for the authentication section block in the json file
#
variable "vm_authentication_type"                       {   default         = "key"                 }
variable "vm_authentication_username"                   {   default         = "azureadm"            }
variable "vm_authentication_password"                   {   default         = ""                    }
variable "vm_authentication_path_to_public_key"         {   default         = ""                    }
variable "vm_authentication_path_to_private_key"        {   default         = ""                    }


# This block describes the variables for the key_vault section block in the json file
#
variable "user_keyvault_id"                             {   default         = ""                    }
variable "automation_keyvault_id"                       {   default         = ""                    }
variable "deployer_private_key_secret_name"             {   default         = ""                    }
variable "deployer_public_key_secret_name"              {   default         = ""                    }
variable "deployer_username_secret_name"                {   default         = ""                    }
variable "deployer_password_secret_name"                {   default         = ""                    }


# This block describes the variables for the options section block in the json file
#
variable "enable_deployer_public_ip"                    {   default         = null                  }
variable "deployer_assign_subscription_permissions"     {   default         = null                  }
variable "firewall_deployment" {                           
                                                            default         = null
                                                            description     = "Boolean flag indicating if an Azure Firewall should be deployed"
}
variable "firewall_rule_subnets" {
                                                            default         = null
                                                            description     = "List of subnets that are part of the firewall rule"
}
variable "firewall_allowed_ipaddresses" {
                                                            default         = null
                                                            description     = "List of allowed IP addresses to be part of the firewall rule"
}
