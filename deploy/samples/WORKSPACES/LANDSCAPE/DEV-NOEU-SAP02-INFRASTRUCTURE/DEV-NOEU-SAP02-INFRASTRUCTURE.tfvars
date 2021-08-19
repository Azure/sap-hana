/*

This block describes the variable for the infrastructure block in the json file

*/

environment="DEV"
location="northeurope"
#codename=


#resourcegroup_name=
#resourcegroup_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE"

/*

This block describes the variables for the VNet block in the json file

*/

network_name="SAP01"
#network_arm_id=""
network_address_space=["10.111.0.0/16"]


/* admin subnet information */

#admin_subnet_name=""
#admin_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_admin"
admin_subnet_address_prefix=["10.111.0.0/19"]

#admin_subnet_nsg_name=""
#admin_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_adminSubnet-nsg"

/* db subnet information */

#db_subnet_name=""
#db_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_db"
db_subnet_address_prefix=["10.111.96.0/19"]

#db_subnet_nsg_name=""
#db_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_dbSubnet-nsg"

/* app subnet information */

#app_subnet_name=""
#app_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_app"
app_subnet_address_prefix=["10.111.32.0/19"]

#app_subnet_nsg_name=""
#app_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_appSubnet-nsg"

/* web subnet information */

#web_subnet_name=""
#web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_web"
web_subnet_address_prefix=["10.111.128.0/19"]

#web_subnet_nsg_name=""
#web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_webSubnet-nsg"

/* iscsi subnet information */

#iscsi_subnet_name=""
#iscsi_subnet_arm_id=""
#iscsi_subnet_address_prefix=""

#iscsi_subnet_nsg_name=""
#iscsi_subnet_nsg_arm_id=""

#iscsi_count=0
#iscsi_size=""
#iscsi_useDHCP=false

# iscsi_image= {
#     source_image_id = ""
#     publisher       = "SUSE"
#     offer           = "sles-sap-12-sp5"
#     sku             = "gen1"
#     version         = "latest"
#   }

#iscsi_authentication_type="key"

#iscsi_authentication_username="azureadm"
#iscsi_nic_ips=[]
/*
This block describes the variables for the key_vault section block in the json file
*/


#user_keyvault_id=""
#automation_keyvault_id=""
#spn_keyvault_id=""

/*
This block describes the variables for the authentication section block in the json file
*/


automation_username="azureadm"
#automation_password=""
#automation_path_to_public_key=""
#automation_path_to_private_key=""

#diagnostics_storage_account_arm_id=""
#witness_storage_account_arm_id=""

enable_purge_control_for_keyvaults=false

#dns_label="sap.contoso.net"
#dns_resource_group_name=""
