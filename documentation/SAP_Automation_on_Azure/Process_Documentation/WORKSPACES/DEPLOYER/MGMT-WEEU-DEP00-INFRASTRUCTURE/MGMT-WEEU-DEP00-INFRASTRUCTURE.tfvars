#
# Generic information
#
environment="MGMT"
#codename=""

location="westeurope"

#resourcegroup_name
#resourcegroup_arm_id

#
# Networking information
#

#management_network_name=""
#management_network_arm_id=""
management_network_address_space="10.10.20.0/25"

#management_subnet_name=""
#management_subnet_arm_id=""
management_subnet_address_prefix="10.10.20.64/28"

#management_subnet_nsg_arm_id=""
#management_subnet_nsg_allowed_ips=""

#management_firewall_subnet_arm_id= ""
management_firewall_subnet_address_prefix="10.10.20.0/26"

########################################################
#
#         Deployer VM information
#
########################################################
#vm_size="Standard_D4ds_v4"
#vm_disk_type"="Premium_LRS"
#use_DHCP=false
#private_ip_address=""

#
# This block describes the variables for the deployer OS section 
#

#vm_image={
#    "source_image_id"=""
#    "publisher"      ="Canonical"
#    "offer"          ="UbuntuServer"
#    "sku"            ="18.04-LTS"
#    "version"        ="latest"
#}


/*
This block describes the variables for the authentication section block in the json file
*/

#vm_authentication_type="key"
#vm_authentication_username="azureadm"
#vm_authentication_password=""
#vm_authentication_path_to_public_key=""
#vm_authentication_path_to_private_key=""

/*
This block describes the variables for the key_vault section block in the json file
*/


#user_keyvault_id=""
#automation_keyvault_id=""
#deployer_private_key_secret_name=""
#deployer_public_key_secret_name=""
#deployer_username_secret_name=""
#deployer_password_secret_name=""


/*
This block describes the variables for the options section block in the json file
*/

#deployer_enable_public_ip=false

firewall_deployment=true
#firewall_rule_subnets=[]
#firewall_rule_allowed_ipaddresses=[]

#assign_subscription_permissions=true
