# Infrastructure block

environment="DEV"
location="westeurope"
#resource_group_name=""
#resource_group_arm_id=""
#proximityplacementgroup_names=[]
#proximityplacementgroup_arm_ids=[]
#Anchor VM
#anchor_vm_sku="Standard_D4s_v4"
#anchor_vm_authentication_type="key"
#anchor_vm_accelerated_networking=true
#anchor_vm_image={
#os_type=""
#source_image_id=""
#publisher="SUSE"
#offer="sles-sap-12-sp5"
#sku="gen1"
#version="latest"
#}
#anchor_vm_nic_ips=["","",""]
#deploy_anchor_vm=true
#anchor_vm_use_DHCP=true

#Networking 
#network_arm_id=""
network_name="SAP01"
#network_address_space="10.1.0.0/16"

#admin_subnet_name=""
#admin_subnet_prefix="10.1.1.0/24"
#admin_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_admin"
#admin_subnet_nsg_name=""
#admin_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_adminSubnet-nsg"

#db_subnet_name=""
#db_subnet_prefix="10.1.2.0/24"
#db_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_db"
#db_subnet_nsg_name="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_dbSubnet-nsg"
#db_subnet_nsg_arm_id=""

#app_subnet_name=""
#app_subnet_prefix="10.1.3.0/24"
#app_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_app"
#app_subnet_nsg_name=""
#app_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_appSubnet-nsg"

#web_subnet_name=""
#web_subnet_prefix="10.1.4.0/24"
#web_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/DEV-WEEU-SAP01-vnet/subnets/DEV-WEEU-SAP01-subnet_web"
#web_subnet_nsg_name=""
#web_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/DEV-WEEU-SAP01_webSubnet-nsg"

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
database_size="Default"

#database_vm_zones=["1"]
#database_vm_use_DHCP=true

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
