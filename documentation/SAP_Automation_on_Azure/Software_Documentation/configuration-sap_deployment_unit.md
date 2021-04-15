
# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Configuration - SAP Deployment Unit #


## Table of Contents <!-- omit in toc --> ##

- [Parameter file construction](#parameter-file-construction)
- [Examples](#examples)
  - [Minimal (Default) input parameter JSON](#minimal-default-input-parameter-json)
  - [Complete input parameter JSON](#complete-input-parameter-json)

---

# Parameter file construction #

The parameters to the automation are passed in a JSON structure with a set of root nodes defining the properties of the system.

Node                                   |  Description |
| :------------------------------------------|  :---------- |
| infrastructure|This node defines the resource group and the networking information. |
| application|This node defines attributes for the application tier, the number of Virtual machines, the image they use,.. |
| database|This node defines attributes for the database tier, the number of Virtual machines, the image they use,... |
| authentication|If specified - This node defines the authentication details for the system. The default setup uses the information from the workload zone key vault. |
| options |If specified - This node defines special settings for the environment |

A comprehensive representation of the json is shown below.

JSON structure

```
{
  "infrastructure": {                                                             <-- Required Block
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "resource_group": {                                                           <-- Optional Block
      "name"                          : "NP-EUS2-SAP01-PRD",                      <-- Optional
      "arm_id"                        : ""                                        <-- Optional
    },
    "anchor_vms": {                                                               <-- Optional Block
      "sku"                           : "Standard_D4s_v4",                        
      "authentication": {
        "type"                        : "key",
        "username"                    : "azureadm"
      },
      "accelerated_networking"        : true,
      "os": {
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen1"
      },
      "nic_ips"                       : ["", "", ""],
      "use_DHCP"                      : false
    },
    "vnets": {
      "sap": {
        "name"                        : "",                                       <-- Required Parameter
        "subnet_db": {                                                            <-- Optional block
          "arm_id"                    : ""                                        <-- Either arm_id or prefix is required if block is specified
          "prefix"                    : "10.1.1.0/28"                             <-- Either arm_id or prefix is required if block is specified
        },
        "subnet_web": {
          "arm_id"                    : ""                                        <-- Either arm_id or prefix is required if block is specified
          "prefix"                    : "10.1.1.16/28"                            <-- Either arm_id or prefix is required if block is specified
        },
        "subnet_app": {
          "arm_id"                    : ""                                        <-- Either arm_id or prefix is required if block is specified
          "prefix"                    : "10.1.1.32/28"                            <-- Either arm_id or prefix is required if block is specified
        },
        "subnet_admin": {
          "arm_id"                    : ""                                        <-- Either arm_id or prefix is required if block is specified
          "prefix"                    : "10.1.1.48/28"                            <-- Either arm_id or prefix is required if block is specified
        }
      }
    }
  },
  "databases": [
    {
      "platform"                      : "HANA",                                   <-- Required Parameter
      "high_availability"             : false,                                    <-- Required Parameter
      "db_version"                    : "2.00.050",
      "size"                          : "Default",                                <-- Required Parameter
      "os": {
        "os_type"                     : "",                                       
        "source_image_id"             : "",
        "publisher"                   : "SUSE",                                   <-- Required Parameter
        "offer"                       : "sles-sap-12-sp5",                        <-- Required Parameter
        "sku"                         : "gen2"                                    <-- Required Parameter
      },
      "zones"                         : ["1"],                                    <-- Optional Parameter
      "avset_arm_ids"                 : [""],                                     <-- Optional Parameter
      "use_DHCP"                      : false,                                    <-- Optional Parameter
      "loadbalancer" : {
        "frontend_ip"                 : ""                                        <-- Optional Parameter
      },  
      "dbnodes" : [                                                               <-- Required Parameter
          {    
            "name"                    : "",                                       <-- Optional parameter
            "db_nic_ips"              : ["",""],                                  <-- Optional parameter
            "admin_nic_ips"           : ["",""]                                   <-- Optional parameter
          }
                  ]             
    }
  ],
  "application": {                                                                <-- Required Block
    "enable_deployment"               : true,                                     <-- Required Parameter
    "sid"                             : "PRD",                                    <-- Required Parameter
    "use_DHCP"                        : false,                                    <-- Optional Parameter
    "application_server_count"        : 3,                                        <-- Required Parameter
    "app_zones"                       : ["1", "2"],                               <-- Optional Parameter
    "app_sku"                         : "Standard_E4ds_v4",
    "os" : {
        "os_type"                     : "",                                       
        "source_image_id"             : "",
        "publisher"                   : "SUSE",                                   <-- Required Parameter
        "offer"                       : "sles-sap-12-sp5",                        <-- Required Parameter
        "sku"                         : "gen2"                                    <-- Required Parameter
      },
    "app_nic_ips"                     : ["", ""],                                 <-- Optional parameter
    "app_admin_nic_ips"               : ["", ""],                                 <-- Optional parameter
    "scs_high_availability"           : false,                                    <-- Required Parameter
    "scs_instance_number"             : "00",                                     <-- Required Parameter
    "ers_instance_number"             : "10",                                     <-- Required Parameter
    "scs_zones"                       : ["1"],                                    <-- Optional Parameter
    "scs_sku"                         : "Standard_E4ds_v4",
    "scs_os" : {                                                                  <-- Optional block
        "os_type"                     : "",                                       
        "source_image_id"             : "",
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen2"
      },
    "scs_nic_ips"                     : [""],                                     <-- Optional parameter
    "scs_admin_nic_ips"               : [""],                                     <-- Optional parameter
    "scs_lb_ips"                      : [""],                                     <-- Optional parameter
    "webdispatcher_count"             : 1,                                        <-- Required Parameter
    "web_zones"                       : ["1"],                                    <-- Optional Parameter
    "web_sku"                         : "Standard_E4ds_v4"
    "web_os" : {                                                                  <-- Optional block
        "os_type"                     : "",                                       
        "source_image_id"             : "",
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen2"
      },
    "web_nic_ips"                     : [""],                                     <-- Optional parameter
    "web_admin_nic_ips"               : [""],                                     <-- Optional parameter
    "web_lb_ips"                      : [""],                                     <-- Optional parameter
    "authentication": {
      "type"                          : "key",
    }
  },
  "options": {                                                                    <-- Optional Block
    "resource_offset"                 : 0,
  },
  "key_vault": {                                                                  <-- Optional Block
    "kv_user_id": "",
    "kv_prvt_id": "",
    "kv_sid_sshkey_prvt" : "",
    "kv_sid_sshkey_pub" : "",
    "kv_spn_id": ""
  },
  "authentication": {                                                             <-- Optional Block
    "username"                        : "azureadm"
    "password"                        : "T0pSecret"
    "path_to_public_key"              : "sshkey.pub",
    "path_to_private_key"             : "sshkey"
  },
  "tfstate_resource_id"               : "",                                       <-- Required Parameter
  "deployer_tfstate_key"              : "",                                       <-- Required Parameter
  "landscape_tfstate_key"             : "",                                       <-- Required Parameter
  "db_disk_sizes_filename"            : "",                                       <-- Optional Parameter
  "app_disk_sizes_filename"           : "",                                       <-- Optional Parameter
}                                                                                 <-- JSON Closing tag
```



Node                                   | Attribute                     | Type          | Default  | Description |
| :------------------------------------------ | ------------------------------| :------------ | :------- | :---------- |
| infrastructure.                             | `environment`                 | **required**  | -------- | The Environment is a 5 Character designator used for identifying the workload zone. An example of partitioning would be, PROD / NP (Production and Non-Production). Environments may also be tied to a unique SPN or Subscription. |
| infrastructure.                             | `region`                      | **required**  |          | This specifies the Azure Region in which to deploy. |
| infrastructure.resource_group.              | `arm_id`                      | optional      |          | If specified the Azure Resource ID of Resource Group to use for the deployment |
| | <br/> | 
| infrastructure.resource_group.              | `name`                        | optional      |          | If specified the name of the resource group to be created |
| | <br/> | 
| infrastructure.anchor_vms.                  | `sku`                         | optional      |          | This is populated if a anchor vm is needed to anchor the proximity placement groups to a specific zone.  |
| infrastructure.anchor_vms.authentication.   | `type`                        | optional              |          | Authentication type for the anchor VM, key or password |
| infrastructure.anchor_vms.                  | `accelerated_networking`      | optional      | false    | Boolean flag indicationg if the Anchor VM should use accelerated networking. |
| infrastructure.anchor_vms.os.               | `publisher`                   | optional      |          | This is the marketplace image publisher |
| infrastructure.anchor_vms.os.               | `offer`                       | optional      |          | This is the marketplace image offer |
| infrastructure.anchor_vms.os.               | `sku`                         | optional      |          | This is the marketplace image sku |
| infrastructure.anchor_vms.                  | `nic_ips`                     | optional      |          | This is the list of IP addresses that the anchor VMs should use. The list needs as many entries as the total Availability Zone count for all the Virtual Machines in the deployment, not needed if use_DCHP is true |
| infrastructure.anchor_vms.                  | `use_DHCP`                    | optional      | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_admin       | `arm_id`                       | **required**  |          | If provided, the Azure resource ID for the admin subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_admin       | `name`                         | **required**  |          | If provided, the name for the admin subnet to be created
| infrastructure.vnets.sap.subnet_admin       | `prefix`                       | **required**  |          | If provided, the admin subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_app         | `arm_id`                       | **required**  |          | If provided, the Azure resource ID for the application subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_app         | `name`                         | **required**  |          | If provided, the name for the application subnet to be created
| infrastructure.vnets.sap.subnet_app         | `prefix`                       | **required**  |          | If provided, the application subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_db          | `arm_id`                       | **required**  |          | If provided, the Azure resource ID for the database subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_db          | `name`                         | **required**  |          | If provided, the name for the database subnet to be created
| infrastructure.vnets.sap.subnet_db          | `prefix`                       | **required**  |          | If provided, the database subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_web         | `arm_id`                       | optional      |          | If provided, the Azure resource ID for the web dispatcher subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_web         | `name`                         | optional      |          | If provided, the name for the web dispatcher subnet to be created
| infrastructure.vnets.sap.subnet_web         | `prefix`                       | optional      |          | If provided, the web dispatcher subnet address prefix of the subnet |
| | <br/> | 
| databases.[].                               | `platform`                     | **required**  |          | This field indicates the database type for the backend. Valid options are HANA, DB2, ORACLE; SQLSERVER, ASE or NONE. If NONE is specified then no database tier gest deployed. |
| databases.[].                               | `high_availability`            | optional      |          | If set to true then the automation will deploy twice the number of servers defined in the count of nodes list. |
| databases.[].                               | `size`                         | **required**  |          | This field maps to the sizing of disks. For HANA this should be the Virtual Machine SKu (M32, M128ms) etc. For AnyDB the sizing is based on the databases size in gigabytes, valid choices are 200, 500, 1024, 2048, 5120, 10240, 15360, 20480, 30720, 40960, 51200. It is also possible to provide custom sizing, see [Custom disk sizing](../Process_Documentation/Using_custom_disk_sizing.md) for more details |
| | <br/> |
| databases.[].os.                            | `os_type`                      |               |          | Required if custom image ID is provided |
| databases.[].os.                            | `source_image_id`              |               |          | The resource Id for the custom image to use.  |
| | or |
| databases.[].os.                            | `publisher`                    |               |          | The publisher of the image used to create the virtual machine.  |
| databases.[].os.                            | `offer`                        |               |          | The offer of the image used to create the virtual machine. |
| databases.[].os.                            | `sku`                          |               |          | The SKU of the image used to create the virtual machine. |
| databases.[].                               | `zones`                        |               |          | A list of the Availability Zones into which the Virtual Machines is deployed. |
| databases.[].                               | `avset_arm_ids.[]`             |               |          | If provided, the name of the availability set into which the Virtual Machine is deployed |
| databases.[].                               | `use_DHCP`                     |               | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| databases.[].dbnodes.[].                    | `name`                         |               |          | If specified, the name of the Virtual Machine |
| databases.[].dbnodes.[].                    | `db_nic_ips.[]`                |               |          | If specified, the IPs of the Virtual Machine (db nic) |
| databases.[].dbnodes.[].                    | `admin_nic_ips.[]`             |               |          | If specified, the IPs of the Virtual Machine (admin nic) |
| databases.[].loadbalancer.                  | `frontend_ip`                  |               |          | The IP of the load balancer |
| | <br/> |
| application.                                | `enable_deployment`            |               |          | Boolean flag indicating if the application tier will be deployed |
| application.                                | `sid`                          | **required**  |          | The SAP application SID |
| application.                                | `application_server_count`     |               |          | The number of application servers to be deployed |
| application.                                | `app_zones`                    |               |          | A list of the Availability Zones into which the Virtual Machines is deployed. |
| application.                                | `app_sku`                      |               |          | The Virtual machine SKU to use |
| application.                                | `dual_nics`                    |               |          | Boolean flag indicating if the application tier will be deployed with dual network cards |
| application.                                | `app_nic_ips[]`                |               |          | The list of IP addresses of the application VM (app subnet) |
| application.                                | `app_admin_nic_ips[]`          |               |          | The list of IP addresses of the application VM (admin subnet) |
| | <br/> |
| application.os.                             | `os_type`                      |               |          | Required if custom image ID is provided |
| application.os.                             | `source_image_id`              |               |          | The resource Id for the custom image to use.  |
| | or |
| application.os.                             | `publisher`                    |               |          | The publisher of the image used to create the virtual machine.  |
| application.os.                             | `offer`                        |               |          | The offer of the image used to create the virtual machine. |
| application.os.                             | `sku`                          |               |          | The SKU of the image used to create the virtual machine. |
| | <br/> |
| application.                                | `scs_server_count`             |               |          | The number of SCS servers to be deployed |
| application.                                | `scs_instance_number`          |               |          | The instance number of SCS|
| application.                                | `ers_instance_number`          |               |          | The instance number of ERS |
| application.                                | `scs_high_availability`        |               |          | Boolean flag indicating if SCS should be deployed highly available.  |
| application.                                | `scs_zones`                    |               |          | A list of the Availability Zones into which the Virtual Machines is deployed. |
| application.                                | `scs_sku`                      |               |          | The Virtual machine SKU to use |
| application.                                | `scs_nic_ips[]`                |               |          | The list of IP addresses of the scs VM (app subnet) |
| application.                                | `scs_admin_nic_ips[]`          |               |          | The list of IP addresses of the scs VM (admin subnet) |
| | <br/> |
| application.scs_os.                         | `os_type`                      |               |          | Required if custom image ID is provided |
| application.scs_os.                         | `source_image_id`              |               |          | The resource Id for the custom image to use.  |
| | or |
| application.scs_os.                         | `publisher`                    |               |          | The publisher of the image used to create the virtual machine.  |
| application.scs_os.                         | `offer`                        |               |          | The offer of the image used to create the virtual machine. |
| application.scs_os.                         | `sku`                          |               |          | The SKU of the image used to create the virtual machine. |
| | <br/> |
| application.                                | `webdispatcher_count`          |               |          | The number of web dispatchers to be deployed |
| application.                                | `web_zones`                    |               |          | A list of the Availability Zones into which the Virtual Machines is deployed. |
| application.                                | `web_sku`                      |               |          | The Virtual machine SKU to use |
| application.                                | `web_nic_ips[]`                |               |          | The list of IP addresses of the web dispatcher VM (app/web subnet) |
| application.                                | `web_admin_nic_ips[]`          |               |          | The list of IP addresses of the web dispatcher VM (admin subnet) |
| | <br/> |
| application.web_os.                         | `os_type`                      |               |          | Required if custom image ID is provided |
| application.web_os.                         | `source_image_id`              |               |          | The resource Id for the custom image to use.  |
| | or |
| application.web_os.                         | `publisher`                    |               |          | The publisher of the image used to create the virtual machine.  |
| application.web_os.                         | `offer`                        |               |          | The offer of the image used to create the virtual machine. |
| application.web_os.                         | `sku`                          |               |          | The SKU of the image used to create the virtual machine. |
| | <br/> |
| application.                                | `use_DHCP`                     |               | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| application.authentication.                 | `type`                         |               |          | The authentication type for the Virtual Machine, valid options are "Password", "Key" |
| | <br/> |
| authentication.                             | `username`                     | optional      |          | If specified the default username for the environment |
| authentication.                             | `password`                     | optional      |          | If specified the password for the environment. <br/>If not specified, Terraform will create a password and store it in keyvault |
| authentication.                             | `path_to_public_key`           | optional      |          | If specified the path to the SSH public key file. If not specified, Terraform will create  and store it in keyvault |
| authentication.                             | `path_to_private_key`          | optional      |          | If specified the path to the SSH private key file. If not specified, Terraform will create  and store it in keyvault |
| | <br/> |
| options.                                    | `resource_offset`              |               | 0        | The offset used for resource naming when creating multiple resources, for example -disk0, disk1. If changing the resource_offset to 1 the disks will be renamed disk1, disk2 |
| options.                                    | `disk_encryption_set_id`       |               |          | Disk encryption key to use for encrypting the managed disks |
| | <br/> |
| key_vault.                                  | `kv_user_id`                   | optional      |          | If provided, the Key Vault resource ID of the user Key Vault to be used.  |
| key_vault.                                  | `kv_prvt_id`                   | optional      |          | If provided, the Key Vault resource ID of the private Key Vault to be used. |
| key_vault.                                  | `kv_spn_id`                    | optional      |          | If provided, the Key Vault resource ID of the private Key Vault containing the SPN details. |
| | <br/> | 
| `tfstate_resource_id`                       |                                | **required**  |          | This is the Azure Resource ID for the Storage Account in which the Statefiles are stored. Typically this is deployed by the SAP Library execution unit. |
| `deployer_tfstate_key`                      | `Remote State`                 | **required**  |          | This is the deployer state file name, used for finding the correct state file.  <br/>**Case-sensitive**  |
| `landscape_tfstate_key`                     | `Remote State`                 | **required**  |          | This is the landscape state file name, used for finding the correct state file.  <br/>**Case-sensitive**   |
| `db_disk_sizes_filename`                    |                                | optional      |          | If specified the custom disk sizing json file name for the database  |
| `app_disk_sizes_filename`                   |                                | optional      |          | If specified the custom disk sizing json file name for the app tier  |

## Examples ##

## Minimal (Default) input parameter JSON ##

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnets": {
      "sap": {
        "name"                        : "SAP-01"           
      }
    }
  },
  "databases": [
    {
      "platform"                      : "HANA",
      "high_availability"             : false,
      "db_version"                    : "2.00.050",
      "size"                          : "Demo",
      "os": {
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen1"
      }
    }
  ],
  "application": {
    "enable_deployment"               : true,
    "sid"                             : "PRD",
    "scs_instance_number"             : "00",
    "ers_instance_number"             : "10",
    "scs_high_availability"           : false,
    "application_server_count"        : 3,
    "webdispatcher_count"             : 1,
  },
  "options": {
  },
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : "",
  "landscape_tfstate_key"             : ""
}
```

<br/><br/><br/>

## Complete input parameter JSON ##

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "resource_group": {
      "name"                          : "NP-EUS2-SAP-PRD",
      "arm_id"                        : ""
    },
    "anchor_vms": {
      "sku"                           : "Standard_D4s_v4",
      "authentication": {
        "type"                        : "key",
      },
      "accelerated_networking"        : true,
      "os": {
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen1"
      },
      "nic_ips"                       : ["", "", ""],
      "use_DHCP"                      : false
    },
    "vnets": {
      "sap": {
        "arm_id"                      : "",
        "name"                        : "",
        "address_space"               : "10.1.0.0/16",
        "subnet_db": {
          "prefix"                    : "10.1.1.0/28"
        },
        "subnet_web": {
          "prefix"                    : "10.1.1.16/28"
        },
        "subnet_app": {
          "prefix"                    : "10.1.1.32/27"
        },
        "subnet_admin": {
          "prefix"                    : "10.1.1.64/27"
        }
      }
    }
  },
  "databases": [
    {
      "platform"                      : "HANA",
      "high_availability"             : false,
      "db_version"                    : "2.00.050",
      "size"                          : "Demo",
      "os": {
        "publisher"                   : "SUSE",
        "offer"                       : "sles-sap-12-sp5",
        "sku"                         : "gen1"
      },
      "zones"                         : ["1"],
      "avset_arm_ids"                 : [
                                          ""
                                        ],
      "use_DHCP"                      : false,
      "loadbalancer" : {
        "frontend_ip"                 : "10.1.1.5"
      },  
      "dbnodes" : [
          {    
            "name"                    : "dbserver"
            "db_nic_ips"              : [10.1.1.1, 10.1.1.2]
            "admin_nic_ips"           : [10.1.1.65, 10.1.1.66]
          }
        ]
    }
  ],
  "application": {
    "enable_deployment"               : true,
    "sid"                             : "PRD",
    "application_server_count"        : 2,
    "app_sku"                         : "Standard_E4ds_v4",
    "dual_nics"                       : true,
    "app_zones"                       : ["1", "2"],
    "app_nic_ips"                     : ["10.1.1.33", "10.1.1.34"],
    "app_admin_nic_ips"               : ["10.1.1.67", "10.1.1.68"],
    "os"                              : {
                                          "os_type": "Linux",
                                          "offer": "sles-sap-12-sp5",
                                          "publisher": "SUSE",
                                          "sku": "gen2",
                                          "version": "latest"
                                        },
    "scs_high_availability"           : false,
    "scs_server_count"                : 1,
    "scs_instance_number"             : "00",
    "ers_instance_number"             : "10",
    "scs_sku"                         : "Standard_E4ds_v4",
    "scs_zones"                       : ["1"],
    "scs_nic_ips"                     : ["10.1.1.35", "10.1.1.36"],
    "scs_admin_nic_ips"               : ["10.1.1.69", "10.1.1.70"],
    "scs_lb_ips"                      : ["10.1.1.37"], 
    "scs_os"                          : {
                                          "os_type": "Linux",
                                          "offer": "sles-sap-12-sp5",
                                          "publisher": "SUSE",
                                          "sku": "gen2",
                                          "version": "latest"
                                        },
    "webdispatcher_count"             : 1,
    "web_sku"                         : "Standard_E4ds_v4",
    "web_zones"                       : ["1"],
    "web_nic_ips"                     : ["10.1.1.17"],
    "web_admin_nic_ips"               : ["10.1.1.72"],
    "web_lb_ips"                      : ["10.1.1.18"] ,
    "web_os"                          : {
                                          "os_type": "Linux",
                                          "offer": "sles-sap-12-sp5",
                                          "publisher": "SUSE",
                                          "sku": "gen2",
                                          "version": "latest"
                                        },
    "use_DHCP"                        : false,
    "authentication": {
      "type"                          : "password"
    }
  },
  "authentication": {
    "username"                        : "azureadm",
    "password"                        : "",
    "path_to_public_key"              : "sshkey.pub",
    "path_to_private_key"             : "sshkey"
  },
  "options": {
    "resource_offset"                 : 0,
    "disk_encryption_set_id"          : ""
  },
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : "",
  "landscape_tfstate_key"             : "",
  "app_disk_sizes_filename"           : "custom_size_app.json",
  "db_disk_sizes_filename"            : "custom_size_db.json"

}
```
