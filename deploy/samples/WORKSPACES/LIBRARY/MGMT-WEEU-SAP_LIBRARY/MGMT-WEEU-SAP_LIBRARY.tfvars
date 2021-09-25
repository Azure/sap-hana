# The automation supports both creating resources (greenfield) or using existing resources (brownfield)
# For the greenfield scenario the automation defines default names for resources, if there is a XXXXname variable then the name is customizable 
# for the brownfield scenario the Azure resource identifiers for the resources must be specified

#########################################################################################
#                                                                                       #
#  Terraform deploy parameters                                                          #
#                                                                                       #
#########################################################################################

# - deployer_tfstate_key is the state file name for the deployer
# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered

deployer_tfstate_key=null

#########################################################################################
#                                                                                       #
#  Infrastructure definitioms                                                          #
#                                                                                       #
#########################################################################################

# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment="MGMT"

# The location valus is a mandatory field, it is used to control where the resources are deployed
location="westeurope"

# RESOURCEGROUP
# The two resource group name and arm_id can be used to control the naming and the creation of the resource group
# The resource_group_name value is optional, it can be used to override the name of the resource group that will be provisioned
# The resource_group_name arm_id is optional, it can be used to provide an existing resource group for the deployment
#resource_group_name=""
#resource_group_arm_id=""

#resourcegroup_name=""
#resourcegroup_arm_id=""

# The resourcegroup_tags value is optional, it can be used to provide tags to be associated with the resource group
#resourcegroup_tags = {
#    "tag" = "value"
#}


# The deployer_environment value is a mandatory field, it is used for identifying the deployer
deployer_environment="MGMT"

# The deployer_location value is a mandatory field, it is used for identifying the deployer
deployer_location="westeurope"

# The deployer_vnet value is a mandatory field, it is used for identifying the deployer
deployer_vnet="DEP00"

# The use_deployer value is a boolean value indicating if the deployer is used as the deployment engine
#use_deployer=true

#######################################################################################
# Keyvault information
#######################################################################################



# user_keyvault_id is the Azure resource identifier for the keyvault containing the system credentials
#user_keyvault_id=""

# automation_keyvault_id is the Azure resource identifier for the keyvault containing the automation credentials
#automation_keyvault_id=""

# spn_keyvault_id is the Azure resource identifier for the keyvault containing the deployment credentials
#spn_keyvault_id=""

#######################################################################################
# SAP Binaries storage account
# This account will contain the downloaded SAP Media files
#######################################################################################

# library_sapmedia_arm_id is the Azure resource identifier for an existing storage account
#library_sapmedia_arm_id=""

# library_sapmedia_account_tier is an optional parameter specifying the storage account tier
#library_sapmedia_account_tier="Standard"

# library_sapmedia_account_replication_type is an optional parameter specifying the storage account type
#library_sapmedia_account_replication_type="LRS"

# library_sapmedia_account_kind is an optional parameter specifying the storage account version
#library_sapmedia_account_kind="StorageV2"

# library_sapmedia_file_share_enable_deployment is boolean flag controlling the storage account deployment
#library_sapmedia_file_share_enable_deployment=true

# library_sapmedia_file_share_is_existing is boolean flag controlling if the File share already exists
#library_sapmedia_file_share_is_existing=false

# library_sapmedia_file_share_name is the name of the File share
#library_sapmedia_file_share_name="sapbits"

# library_sapmedia_blob_container_enable_deployment is boolean flag controlling the blob container deployment
#library_sapmedia_blob_container_enable_deployment=true

# library_sapmedia_blob_container_is_existing is boolean flag controlling if the blob container already exists
#library_sapmedia_blob_container_is_existing=false

# library_sapmedia_blob_container_name is the name of the blob container
#library_sapmedia_blob_container_name="sapbits"

#######################################################################################
# Terrafrom state storage account
# This account will contain the Terraform state files
#######################################################################################

# library_terraform_state_arm_id is the Azure resource identifier for an existing storage account
#library_terraform_state_arm_id=""

# library_terraform_state_account_tier is an optional parameter specifying the storage account tier
#library_terraform_state_account_tier="Standard"

# library_terraform_state_account_replication_type is an optional parameter specifying the storage account type
#library_terraform_state_account_replication_type="LRS"

# library_terraform_state_account_kind is an optional parameter specifying the storage account version
#library_terraform_state_account_kind="StorageV2"

# library_terraform_state_blob_container_is_existing is boolean flag controlling if the terraform blob container already exists
#library_terraform_state_blob_container_is_existing=false

# library_terraform_state_blob_container_name is the name of the terraform blob container
#library_terraform_state_blob_container_name="tfstate"

# library_ansible_blob_container_is_existing is boolean flag controlling if the ansible blob container already exists
#library_ansible_blob_container_is_existing=false

# library_ansible_blob_container_name is the name of the ansible blob container
#library_ansible_blob_container_name="ansible"

# dns_label if specified is the DNS name of the private DNS zone
dns_label="sap.contoso.net"

# use_private_endpoint is a boolean flag controlling if the keyvaults and storage accounts have private endpoints
#use_private_endpoint=false


