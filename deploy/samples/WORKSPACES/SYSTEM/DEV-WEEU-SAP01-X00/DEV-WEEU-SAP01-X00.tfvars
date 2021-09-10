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
# - landscape_tfstate_key is the state file name for the workload deployment
# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered

tfstate_resource_id=null
deployer_tfstate_key=null
landscape_tfstate_key=null

#########################################################################################
#                                                                                       #
#  Infrastructure definitioms                                                          #
#                                                                                       #
#########################################################################################

# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment="DEV"

# The location valus is a mandatory field, it is used to control where the resources are deployed
location="westeurope"

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
network_name="SAP01"

# ADMIN subnet
# If defined these parameters control the subnet name and the subnet prefix
# admin_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#admin_subnet_name=""

# admin_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#admin_subnet_address_prefix="10.1.1.0/24"
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
#db_subnet_address_prefix="10.1.2.0/24"

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

# app_subnet_address_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_address_prefix="10.1.3.0/24"

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

# web_subnet_address_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_address_prefix="10.1.4.0/24"

# web_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_web"

# web_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#web_subnet_nsg_name=""

# web_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_webSubnet-nsg"

#########################################################################################
#                                                                                       #
#  Database tier                                                                        #                                                                                       #
#                                                                                       #
#########################################################################################

# database_platform defines the database backend, supported values are
# - HANA
# - DB2
# - ORACLE
# - ASE
# - SQLSERVER
# - NONE (in this case no database tier is deployed)
database_platform="HANA"

# database_high_availability is a boolean flag controlling if the database tier is deployed highly available (more than 1 node)
#database_high_availability=false

# For M series VMs use the SKU name for instance "M32ts"
# If using a custom disk sizing populate with the node name for Database you have used in the file db_disk_sizes_filename
database_size="S4Demo"

#If you want to customise the disk sizes for database VMs use the following parameter to specify the custom sizing file.
#db_disk_sizes_filename="custom-sizing.json"

# database_vm_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
database_vm_use_DHCP=true

# The vm_image defines the Virtual machine image to use, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified

# Sample Images for different database backends

# Oracle
#database_vm_image={
#  source_image_id=""
#  publisher="Oracle"
#  offer= "Oracle-Linux",
#  sku= "81-gen2",
#  version="latest"
#}

#SUSE 12 SP5
database_vm_image={
  os_type=""
  source_image_id=""
  publisher="SUSE"
  offer="sles-sap-12-sp5"
  sku="gen1"
  version="latest"
}

#RedHat
# database_vm_image={
#   os_type="linux"
#   source_image_id=""
#   publisher="RedHat"
#   offer="RHEL-SAP-HA"
#   sku="82sapha-gen2"
#   version="8.2.2021040902"
# }

# database_vm_zones is an optional list defining the availability zones to deploy the database servers
#database_vm_zones=["1"]

# database_nodes provides a way to specify more than one database node, i.e. a scaleout scenario

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

# Optional, Defines the default authentication model for the Database VMs (key/password)
#database_vm_authentication_type="key"

# Optional, Defines the list of availability sets to deployt the Database VMs in
#database_vm_avset_arm_ids=[/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-X00/providers/Microsoft.Compute/availabilitySets/DEV-WEEU-X00_db_avset"

# Optional, Defines the that the database virtual machines will not be placed in a proximity placement group
#database_no_ppg=false

# Optional, Defines the that the database virtual machines will not be placed in an availability set
#database_no_avset=false

#########################################################################################
#                                                                                       #
#  Application tier                                                                        #                                                                                       #
#                                                                                       #
#########################################################################################
# sid is a mandatory field that defines the SAP Application SID
sid="X00"

app_tier_vm_sizing="Production"


# app_tier_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
app_tier_use_DHCP=true
# Optional, Defines the default authentication model for the Applicatiuon tier VMs (key/password)
#app_tier_authentication_type="key"

# enable_app_tier_deployment is a boolean flag controlling if the application tier should be deployed
#enable_app_tier_deployment=true

# app_tier_dual_nics is a boolean flag controlling if the application tier servers should have two network cards
#app_tier_dual_nics=false

#If you want to customise the disk sizes for application tier use the following parameter.
#app_disk_sizes_filename="custom-sizing.json"

# use_loadbalancers_for_standalone_deployments is a boolean flag that can be used to control if standalone deployments (non HA) will have load balancers
#use_loadbalancers_for_standalone_deployments=false

# Application Servers

# application_server_count defines how many application servers to deploy
application_server_count=3

# application_server_zones is an optional list defining the availability zones to which deploy the application servers
#application_server_zones=["1","2","3"]

# application_server_sku, if defined provides the SKU to use for the application servers
#application_server_sku="Standard_D4s_v3"

# application_server_no_ppg defines the that the application server virtual machines will not be placed in a proximity placement group
#application_server_no_ppg=false

# application_server_no_avset defines the that the application server virtual machines will not be placed in an availability set
#application_server_no_avset=false

# application_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the application subnet
#application_server_app_nic_ips=[]

# application_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the admin subnet
#application_server_app_admin_nic_ips=[]

# application_server_tags, if defined provides the tags to be associated to the application servers
#application_server_tags={},

# The vm_image defines the Virtual machine image to use for the application servers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
application_server_image= {
  os_type=""
  source_image_id=""
  publisher="SUSE"
  offer="sles-sap-12-sp5"
  sku="gen1"
}

# SCS Servers

# scs_server_count defines how many SCS servers to deploy
scs_server_count=1

# scs_server_sku, if defined provides the SKU to use for the SCS servers
#scs_server_sku="Standard_D4s_v3"

# scs_server_no_ppg defines the that the SCS virtual machines will not be placed in a proximity placement group
#scs_server_no_ppg=false

# scs_server_no_avset defines the that the SCS virtual machines will not be placed in an availability set
#scs_server_no_avset=false

# scs_high_availability is a boolean flag controlling if SCS should be highly available
scs_high_availability=false

# scs_instance_number
scs_instance_number="01"

# ers_instance_number
ers_instance_number="02"

# scs_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the application subnet
#scs_server_app_nic_ips=[]

# scs_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the application subnet
#scs_server_app_admin_nic_ips=[]

# scs_server_loadbalancer_ips, if provided provides the static IP addresses for the load balancer
# for the network interface cars connected to the application subnet
#scs_server_loadbalancer_ips=[]


# scs_server_tags, if defined provides the tags to be associated to the application servers
#scs_server_tags={},

# scs_server_zones is an optional list defining the availability zones to which deploy the SCS servers
#scs_server_zones=["1","2","3"]

# The vm_image defines the Virtual machine image to use for the application servers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
#scs_server_image= {
# os_type=""
# source_image_id=""
# publisher="SUSE"
# offer="sles-sap-12-sp5"
# sku="gen1"
#}

# Web Dispatchers

# webdispatcher_server_count defines how many web dispatchers to deploy
webdispatcher_server_count=0

# webdispatcher_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the application subnet
#webdispatcher_server_app_nic_ips=[]

# webdispatcher_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cars connected to the application subnet
#webdispatcher_server_app_admin_nic_ips=[]

# webdispatcher_server_loadbalancer_ips, if provided provides the static IP addresses for the load balancer
# for the network interface cars connected to the application subnet
#webdispatcher_server_loadbalancer_ips=[]

# webdispatcher_server_sku, if defined provides the SKU to use for the web dispatchers
#webdispatcher_server_sku="Standard_D4s_v3"

# webdispatcher_server_no_ppg defines the that the Web dispatcher virtual machines will not be placed in a proximity placement group
#webdispatcher_server_no_ppg=false

#webdispatcher_server_no_avset defines the that the Web dispatcher virtual machines will not be placed in an availability set
#webdispatcher_server_no_avset=false

# webdispatcher_server_tags, if defined provides the tags to be associated to the web dispatchers
#webdispatcher_server_tags={},

# webdispatcher_server_zones is an optional list defining the availability zones to which deploy the web dispatchers
#webdispatcher_server_zones=["1","2","3"]

# The vm_image defines the Virtual machine image to use for the web dispatchers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
#webdispatcher_server_image= {
# os_type=""
# source_image_id=""
# publisher="SUSE"
# offer="sles-sap-12-sp5"
# sku="gen1"
#}

#########################################################################################
#                                                                                       #
#  Credentials                                                                          #
#                                                                                       #
#########################################################################################

# The automation_username defines the user account used by the automation
#automation_username="azureadm"

# The automation_password is an optional parameter that can be used to provide a password for the automation user
# If empty Terraform will create a password and persist it in keyvault
#automation_password=""

# The automation_path_to_public_key is an optional parameter that can be used to provide a path to an existing ssh public key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_public_key=""

# The automation_path_to_private_key is an optional parameter that can be used to provide a path to an existing ssh private key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_private_key=""

# resource_offset can be used to provide an offset for resource naming
# server#, disk# 
#resource_offset=1

# vm_disk_encryption_set_id if defined defines the custom encryption key 
#vm_disk_encryption_set_id=""

# nsg_asg_with_vnet if set controls where the Application Security Groups are created
#nsg_asg_with_vnet=false



#########################################################################################
#                                                                                       #
# Anchor VM                                                                             #
#                                                                                       #
# The Anchor VM can be used as the first Virtual Machine deployed by the deployment,    #
# this Virtual Machine will anchor the proximity placement group and all the            #
# subsequent virtual machines will be deployed in the same group.                       #
# It is recommended to use the same SKU for the Anchor VM as for the database VM        #
#                                                                                       #
#########################################################################################

# the deploy_anchor_vm flag controls if an anchor VM should be deployed
#deploy_anchor_vm=false

# anchor_vm_sku if used is mandatory and defines the virtual machine SKU
#anchor_vm_sku="Standard_D4s_v4"

# Defines the default authentication model for the Anchor VM (key/password)
#anchor_vm_authentication_type="key"

# Defines if the anchor VM should use accelerated networking
#anchor_vm_accelerated_networking=true

# The anchor_vm_image defines the Virtual machine image to use, 
# if source_image_id is specified the deployment will use the custom image provided
# in this case os_type must also be specified

#anchor_vm_image={
#os_type=""
#source_image_id=""
#publisher="SUSE"
#offer="sles-sap-12-sp5"
#sku="gen1"
#version="latest"
#}

# anchor_vm_nic_ips if defined will provide the IP addresses for the the Anchor VMs
#anchor_vm_nic_ips=["","",""]
# anchor_vm_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
#anchor_vm_use_DHCP=true
