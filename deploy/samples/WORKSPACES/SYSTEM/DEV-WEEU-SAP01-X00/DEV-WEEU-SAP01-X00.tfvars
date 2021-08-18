# Deployment information
# - tfstate_resource_id is the Azure resource identifier for the Storage account in the SAP Library
#   that will contain the Terraform state files
# - deployer_tfstate_key is the state file name for the deployer
# - landscape_tfstate_key is the state file name for the workload deployment
# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered


tfstate_resource_id   = null
deployer_tfstate_key  = null
landscape_tfstate_key = null

# Infrastructure block
# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment = "DEV"

# The region valus is a mandatory field, it is used to control where the resources are deployed
region      = "westeurope"

# RESOURCEGROUP
# The two resource group name and arm_id can be used to control the naming and the creation of the resource group
# The resource_group_name value is optional, it can be used to override the name of the resource group that will be provisioned
# The resource_group_name arm_id is optional, it can be used to provide an existing resource group for the deployment
#resource_group_name=""
#resource_group_arm_id=""

# PPG
# The proximity placement group names and arm_ids are optional can be used to control the naming and the creation of the proximity placement groups
# The proximityplacementgroup_names list value is optional, it can be used to override the name of the proximity placement groups that will be provisioned
# The proximityplacementgroup_arm_ids list value is optional, it can be used to provide an existing proximity placement groups for the deployment
#proximityplacementgroup_names=[]
#proximityplacementgroup_arm_ids=[]

# NETWORKING
# The deployment automation supports two ways of providing subnet information.
# 1. Subnets are defined as part of the workload virtual network deployment
#    In this model multiple SAP System share the subnets
# 2. Subnets are deployed as part of the SAP system
#    In this model each system has its own sets of subnets
#
# The automation supports both creating the subnets (greenfield) or using existing subnets (brownfield)
# For the greenfield scenario the subnet address prefix must be specified whereas
# for the brownfield scenario the Azure resource identifier for the subnet must be specified

# The network logical name is mandatory - it is used in the naming convention and should map to the workload virtual network logical name 
network_name="SAP01"

# ADMIN subnet
# If defined these parameters control the subnet name and the subnet prefix
# admin_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#admin_subnet_name=""

# admin_subnet_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#admin_subnet_prefix="10.1.1.0/24"
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

# db_subnet_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#db_subnet_prefix="10.1.2.0/24"

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

# app_subnet_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_prefix="10.1.3.0/24"

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

# web_subnet_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_prefix="10.1.4.0/24"

# web_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_web"

# web_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#web_subnet_nsg_name=""

# web_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_webSubnet-nsg"

#Anchor VM
# The Anchor VM can be used as the first Virtual Machine deployed by the deployment, this Virtual Machine will anchor the proximity placement group and all the 
# subsequent virtual machines will be deployed in the same group. It is recommended to use the same SKU for the Anchor VM as for the database VM

# the deploy_anchor_vm flag controls if an anchor VM should be deployed
#deploy_anchor_vm=false


# anchor_vm_sku if used is mandatory and defines the virtual machine SKU
#anchor_vm_sku="Standard_D4s_v4"

# Defines the default authentication model (key/password)
#anchor_vm_authentication_type="key"

# Defines if the anchor VM should use accelerated networking
#anchor_vm_accelerated_networking=true

# The anchor_vm_image defines the Virtual machine image to use, if source_image_id is specified the deployment will use the custom image provided, in this case os_type must also be specified

#anchor_vm_image={
#os_type=""
#source_image_id=""
#publisher="SUSE"
#offer="sles-sap-12-sp5"
#sku="gen1"
#version="latest"
#}

# anchor_vm_nic_ips if defined will provide the IP addresses for the network interface cards 
#anchor_vm_nic_ips=["","",""]
# anchor_vm_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
#anchor_vm_use_DHCP=true


#Database VM

#database_vm_authentication_type="key"
#database_vm_avset_arm_ids=[/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-X00/providers/Microsoft.Compute/availabilitySets/DEV-WEEU-X00_db_avset"

#Oracle
#  source_image_id=""
#  publisher="Oracle"
#  offer= "Oracle-Linux",
#  sku= "81-gen2",
#  version="latest"

database_vm_image={
  os_type=""
  source_image_id=""
  publisher="SUSE"
  offer="sles-sap-12-sp5"
  sku="gen1"
  version="latest"
}

#database_vm_use_DHCP=false
#database_nodes=[
# {
# name=  "hdb1"
# admin_nic_ips= ["",""]
# db_nic_ips= ["",""]
# storage_nic_ips= ["",""]
# },
# {
# name="hdb2"
# admin_nic_ips= ["",""]
# db_nic_ips= ["",""]
# storage_nic_ips= ["",""]
# }
# ]

#database_high_availability=true

database_platform="HANA"
database_size="S4Demo"

#database_vm_zones=["1"]
database_vm_use_DHCP=true

#Application tier
enable_app_tier_deployment=true
#app_tier_authentication_type="key"
sid="X00"
app_tier_use_DHCP=true
#app_tier_dual_nics=false
#app_tier_vm_sizing="New"

# Application Server

application_server_count=3
#application_server_app_nic_ips=[]
#application_server_app_admin_nic_ips=[]
#application_server_sku="Standard_D4s_v3"
#application_server_tags={},
#application_server_zones=["1","2","3"]
#application_server_image= {
# os_type=""
# source_image_id=""
# publisher="SUSE"
# offer="sles-sap-12-sp5"
# sku="gen1"
#}

# SCS Server

scs_server_count=1
scs_high_availability=false
scs_instance_number="01"
ers_instance_number="02"
#scs_server_app_nic_ips=[]
#scs_server_app_admin_nic_ips=[]
#scs_server_loadbalancer_ips=[]

#scs_server_sku="Standard_D4s_v3"
#scs_server_tags={},
#scs_server_zones=["1","2","3"]
#scs_server_image= {
# os_type=""
# source_image_id=""
# publisher="SUSE"
# offer="sles-sap-12-sp5"
# sku="gen1"
#}

webdispatcher_server_count=0
#webdispatcher_server_app_nic_ips=[]
#webdispatcher_server_app_admin_nic_ips=[]
#webdispatcher_server_loadbalancer_ips=[]

#webdispatcher_server_sku="Standard_D4s_v3"
#webdispatcher_server_tags={},
#webdispatcher_server_zones=["1","2","3"]
#webdispatcher_server_image= {
# os_type=""
# source_image_id=""
# publisher="SUSE"
# offer="sles-sap-12-sp5"
# sku="gen1"
#}

#automation_username="azureadm"
#automation_password=""
#automation_path_to_public_key=""
#automation_path_to_private_key=""

#resource_offset=1
#vm_disk_encryption_set_id=""
#nsg_asg_with_vnet=false

#use_loadbalancers_for_standalone_deployments=false