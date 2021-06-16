/*

This block describes the variable for the infrastructure block in the json file

*/

environment="DEV"
location="westeurope"
#codename=


#resourcegroup_name=
#resourcegroup_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE"

/*

This block describes the variables for the VNet block in the json file

*/

sap_network_name="SAP01"
#sap_network_arm_id=""
sap_network_address_space="10.110.0.0/24"


/* admin subnet information */

#sap_admin_subnet_name=""
#sap_admin_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_admin"
sap_admin_subnet_address_prefix="10.110.0.0/27"

#sap_admin_subnet_nsg_name=""
#sap_admin_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_adminSubnet-nsg"

/* db subnet information */

#sap_db_subnet_name=""
#sap_db_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_db"
sap_db_subnet_address_prefix="10.110.0.64/27"

#sap_db_subnet_nsg_name=""
#sap_db_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_dbSubnet-nsg"

/* app subnet information */

#sap_app_subnet_name=""
#sap_app_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_app"
sap_app_subnet_address_prefix="10.110.0.32/27"

#sap_app_subnet_nsg_name=""
#sap_app_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_appSubnet-nsg"

/* web subnet information */

#sap_web_subnet_name=""
#sap_web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/PROD_WUS2_SAP04-vnet/subnets/PROD-WUS2-SAP04-subnet_web"
sap_web_subnet_address_prefix="10.110.0.96/27"

#sap_web_subnet_nsg_name=""
#sap_web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/PROD-WUS2-SAP04-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/PROD-WUS2-SAP04_webSubnet-nsg"

/* iscsi subnet information */

#sap_iscsi_subnet_name=""
#sap_iscsi_subnet_arm_id=""
#sap_iscsi_subnet_address_prefix=""

#sap_iscsi_subnet_nsg_name=""
#sap_iscsi_subnet_nsg_arm_id=""

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
