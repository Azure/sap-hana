# The automation supports both creating resources (greenfield) or using existing resources (brownfield)
# For the greenfield scenario the automation defines default names for resources, if there is a XXXXname variable then the name is customizable 
# for the brownfield scenario the Azure resource identifiers for the resources must be specified

#########################################################################################
#                                                                                       #
#  Terraform deploy parameters                                                          #
#                                                                                       #
#########################################################################################

# - tfstate_resource_id is the Azure resource identifier for the Storage account in the SAP Library
#   that will contain the Terraform state files
# - deployer_tfstate_key is the state file name for the deployer
# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered

tfstate_resource_id   = null
deployer_tfstate_key  = null

#########################################################################################
#                                                                                       #
#  Infrastructure definitioms                                                          #
#                                                                                       #
#########################################################################################

# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment = "DEV"

# The location valus is a mandatory field, it is used to control where the resources are deployed
location      = "northeurope"

# RESOURCEGROUP
# The two resource group name and arm_id can be used to control the naming and the creation of the resource group
# The resource_group_name value is optional, it can be used to override the name of the resource group that will be provisioned
# The resource_group_name arm_id is optional, it can be used to provide an existing resource group for the deployment
#resource_group_name=""
#resource_group_arm_id=""

#########################################################################################
#                                                                                       #
#  Networking                                                                           #
#                                                                                       #
#########################################################################################
# The deployment automation supports two ways of providing subnet information.
# 1. Subnets are defined as part of the workload zone  deployment
#    In this model multiple SAP System share the subnets
# 2. Subnets are deployed as part of the SAP system
#    In this model each SAP system has its own sets of subnets
#
# The automation supports both creating the subnets (greenfield) or using existing subnets (brownfield)
# For the greenfield scenario the subnet address prefix must be specified whereas
# for the brownfield scenario the Azure resource identifier for the subnet must be specified

# The network logical name is mandatory - it is used in the naming convention and should map to the workload virtual network logical name 
network_name="SAP02"

# network_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing Virtual Network
#network_arm_id=""

# network_address_space is a mandatory parameter when an existing Virtual network is not used
network_address_space="10.111.0.0/16"

# ADMIN subnet
# If defined these parameters control the subnet name and the subnet prefix
# admin_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#admin_subnet_name=""

# admin_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
admin_subnet_address_prefix="10.111.0.0/19"
# admin_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#admin_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_admin"

# admin_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#admin_subnet_nsg_name=""
# admin_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#admin_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_adminSubnet-nsg"

# DB subnet
# If defined these parameters control the subnet name and the subnet prefix
# db_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#db_subnet_name=""

# db_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
db_subnet_address_prefix="10.111.96.0/19"

# db_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#db_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_db"

# db_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#db_subnet_nsg_name=""

# db_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#db_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_dbSubnet-nsg"


# APP subnet
# If defined these parameters control the subnet name and the subnet prefix
# app_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#app_subnet_name=""

# app_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
app_subnet_address_prefix="10.111.32.0/19"

# app_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_app"

# app_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#app_subnet_nsg_name=""

# app_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#app_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_appSubnet-nsg"

# WEB subnet
# If defined these parameters control the subnet name and the subnet prefix
# web_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#web_subnet_name=""

# web_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
web_subnet_address_prefix="10.111.128.0/19"

# web_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_web"

# web_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#web_subnet_nsg_name=""

# web_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_webSubnet-nsg"

###########################################################################
#                                                                         #
#                                    ISCSI                                #
#                                                                         #
###########################################################################

/* iscsi subnet information */
# If defined these parameters control the subnet name and the subnet prefix
# iscsi_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#iscsi_subnet_name=""

# iscsi_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#iscsi_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_iscsi"

# iscsi_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#iscsi_subnet_address_prefix=""

# iscsi_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing nsg 
#iscsi_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_iscsiSubnet-nsg"

# iscsi_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#iscsi_subnet_nsg_name=""

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

#########################################################################################
#                                                                                       #
#  Azure Keyvault support                                                               #
#                                                                                       #
#########################################################################################

# The user keyvault is designed to host secrets for the administrative users
# user_keyvault_id is an optional parameter that if provided specifies the Azure resource identifier for an existing keyvault
#user_keyvault_id=""

# The automation keyvault is designed to host secrets for the automation solution
# automation_keyvault_id is an optional parameter that if provided specifies the Azure resource identifier for an existing keyvault
#automation_keyvault_id=""

# The SPN keyvault is designed to host the SPN credentials used by the automation
# spn_keyvault_id is an optional parameter that if provided specifies the Azure resource identifier for an existing keyvault
#spn_keyvault_id=""

# enable_purge_control_for_keyvaults is an optional parameter that czan be used to disable the purge protection fro Azure keyvaults
# USE THIS ONLY FOR TEST ENVIRONMENTS
enable_purge_control_for_keyvaults=false

#########################################################################################
#                                                                                       #
#  Credentials                                                                          #
#                                                                                       #
#########################################################################################

# The automation_username defines the user account used by the automation
automation_username="azureadm"

# The automation_password is an optional parameter that can be used to provide a password for the automation user
# If empty Terraform will create a password and persist it in keyvault
#automation_password=""

# The automation_path_to_public_key is an optional parameter that can be used to provide a path to an existing ssh public key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_public_key=""

# The automation_path_to_private_key is an optional parameter that can be used to provide a path to an existing ssh private key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_private_key=""

# diagnostics_storage_account_arm_id is an optional parameter that if provided specifies the Azure resource identifier for the storage account to use for storing diagnostic logs
#diagnostics_storage_account_arm_id=""

# witness_storage_account_arm_id is an optional parameter that if provided specifies the Azure resource identifier for the storage account to use as a clouyd witness
#witness_storage_account_arm_id=""


#########################################################################################
#                                                                                       #
#  Private DNS support                                                           #                                                                                       #
#                                                                                       #
#########################################################################################

# If defined provides the DNS label for the Virtual Network
#dns_label="sap.contoso.net"

# If defined provides the name of the resource group hosting the Private DNS zone
#dns_resource_group_name=""

#########################################################################################
#                                                                                       #
#  Azure NetApp files support                                                           #                                                                                       #
#                                                                                       #
#########################################################################################
# use_ANF is a boolean flag controlling if Azure NetApp files is used for storage

#use_ANF=false

/* anf subnet information */
# If defined these parameters control the subnet name and the subnet prefix
# anf_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#anf_subnet_name=""

# anf_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet
#anf_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_amf"

# ANF requires a dedicated subnet, the address space for the subnet is provided with  anf_subnet_address_prefix 
# anf_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#anf_subnet_address_prefix=10.110.64.0/27
