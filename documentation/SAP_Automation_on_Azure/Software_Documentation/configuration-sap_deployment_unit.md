<!-- TODO: 
Remove files and maintain here in documentation
deploy/terraform/run/sap_system/sapsystem_full.json
deploy/terraform/run/sap_system/sapsystem.json
-->
### <img src="../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Configuration - SAP Deployment Unit <!-- omit in toc -->

<br/>

## Table of Contents <!-- omit in toc -->
<br/>

- [Parameter file construction](#parameter-file-construction)
- [Examples](#examples)
  - [Minimal (Default) input parameter JSON](#minimal-default-input-parameter-json)
  - [Complete input parameter JSON](#complete-input-parameter-json)


<br/><br/><br/><br/>

---
<br/>

# Parameter file construction

JSON structure

```
{                                                                                 <-- JSON opening tag
  "tfstate_resource_id"               : "",                                       <-- Required Parameter
  "deployer_tfstate_key"              : "",                                       <-- Required Parameter
  "landscape_tfstate_key"             : "",                                       <-- Required Parameter
  "infrastructure": {                                                             <-- Required Block
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "resource_group": {                                                           <-- Optional Block
      "is_existing"                   : "false",                                  <-- Optional
      "arm_id"                        : ""                                        <-- Optional
    },
    "anchor_vms": {                                                               <-- Optional Block
      "sku"                           : "Standard_D4s_v4",                        <-- Optional
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
        "is_existing"                 : "false",
        "arm_id"                      : "",
        "name"                        : "",
        "address_space"               : "10.1.0.0/16",                            <-- deprecate; Do not use
        "subnet_db": {
          "prefix"                    : "10.1.1.0/28"                             <-- Required Parameter
        },
        "subnet_web": {
          "prefix"                    : "10.1.1.16/28"                            <-- Required Parameter
        },
        "subnet_app": {
          "prefix"                    : "10.1.1.32/27"                            <-- Required Parameter
        },
        "subnet_admin": {
          "prefix"                    : "10.1.1.64/27"                            <-- Required Parameter
        }
      }
    }
  },
  "databases": [
    {
      "platform"                      : "HANA",                                   <-- Required Parameter
      "high_availability"             : false,                                    <-- Required Parameter
      "db_version"                    : "2.00.050",
      "size"                          : "Demo",                                   <-- Required Parameter
      "os": {
        "publisher"                   : "SUSE",                                   <-- Required Parameter
        "offer"                       : "sles-sap-12-sp5",                        <-- Required Parameter
        "sku"                         : "gen1"                                    <-- Required Parameter
      },
      "zones"                         : ["1"],
      "credentials": {
        "db_systemdb_password"        : "<db_systemdb_password>",
        "os_sidadm_password"          : "<os_sidadm_password>",
        "os_sapadm_password"          : "<os_sapadm_password>",
        "xsa_admin_password"          : "<xsa_admin_password>",
        "cockpit_admin_password"      : "<cockpit_admin_password>",
        "ha_cluster_password"         : "<ha_cluster_password>"
      },
      "avset_arm_ids"                 : [
                                          "/subscriptions/xxxx/resourceGroups/yyyy/providers/Microsoft.Compute/availabilitySets/PROTO-SID_db_avset"
                                        ],
      "use_DHCP"                      : false,
      "dbnodes": [
        {
          "name"                      : "hdb1",
          "role"                      : "worker"
        },
        {
          "name"                      : "hdb2",
          "role"                      : "worker"
        },
        {
          "name"                      : "hdb3",
          "role"                      : "standby"
        }
      ]
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
    "app_zones"                       : ["1", "2"],
    "scs_zones"                       : ["1"],
    "web_zones"                       : ["1"],
    "use_DHCP"                        : false,
    "authentication": {
      "type"                          : "key",
      "username"                      : "azureadm"
    }
  },
  "sshkey": {
    "path_to_public_key"              : "sshkey.pub",
    "path_to_private_key"             : "sshkey"
  },
  "options": {
    "enable_secure_transfer"          : true,
    "enable_prometheus"               : true
    "resource_offset"                 : 0,
    "disk_encryption_set_id"          : "",
    "use_local_keyvault_for_secrets"  : false
  },
  "key_vault": {
    "kv_user_id": "",
    "kv_prvt_id": "",
    "kv_sid_sshkey_prvt" : "",
    "kv_sid_sshkey_pub" : "",
    "kv_spn_id": ""
  }
}                                                                                 <-- JSON Closing tag
```


Object Path                                   | Parameter                     | Type          | Default  | Description |
| :------------------------------------------ | ------------------------------| :------------ | :------- | :---------- |
| `tfstate_resource_id`                       |                               | **required**  |          | This is the Azure Resource ID for the Storage Account in which the Statefiles are stored. Typically this is deployed by the SAP Library execution unit. |
| `deployer_tfstate_key`                      | `Remote State`                | **required**  |          | This is the deployer state file name, used for finding the correct state file.  <br/>**Case-sensitive**  |
| `landscape_tfstate_key`                     | `Remote State`                | **required**  |          | This is the landscape state file name, used for finding the correct state file.  <br/>**Case-sensitive**   |
| infrastructure.                             | `environment`                 | **required**  | -------- | The Environment is a 5 Character designator used for partitioning. An example of partitioning would be, PROD / NP (Production and Non-Production). Environments may also be tied to a unique SPN or Subscription. |
| infrastructure.                             | `region`                      | **required**  |          | This specifies the Azure Region in which to deploy. |
| infrastructure.resource_group.              | `arm_id`                      | optional      |          | If specified the Azure Resource ID of Resource Group to use for the deployment |
| | <br/> | 
| infrastructure.anchor_vms.                  | `sku`                         | optional      |          | This is populated if a anchor vm is needed to anchor the proximity placement groups to a specific zone.  |
| infrastructure.anchor_vms.authentication.   | `type`                        | optional              |          | Authentication type for the anchor VM, key or password |
| infrastructure.anchor_vms.authentication.   | `username`                    | optional      |          | Username for the Anchor VM |
| infrastructure.anchor_vms.                  | `accelerated_networking`      | optional      | false    | Boolean flag indicationg if the Anchor VM should use accelerated networking. |
| infrastructure.anchor_vms.os.               | `publisher`                   | optional      |          | This is the marketplace image publisher |
| infrastructure.anchor_vms.os.               | `offer`                       | optional      |          | This is the marketplace image offer |
| infrastructure.anchor_vms.os.               | `sku`                         | optional      |          | This is the marketplace image sku |
| infrastructure.anchor_vms.                  | `nic_ips`                     | optional      |          | This is the list of IP addresses that the anchor VMs should use. The list needs as many entries as the total Availability Zone count for all the Virtual Machines in the deployment, not needed if use_DCHP is true |
| infrastructure.anchor_vms.                  | `use_DHCP`                    | optional      | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_admin       |`arm_id`                       | **required**  |          | If provided, the Azure resource ID for the admin subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_admin       |`name`                         | **required**  |          | If provided, the name for the admin subnet to be created
| infrastructure.vnets.sap.subnet_admin       |`prefix`                       | **required**  |          | If provided, the admin subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_app         |`arm_id`                       | **required**  |          | If provided, the Azure resource ID for the application subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_app         |`name`                         | **required**  |          | If provided, the name for the application subnet to be created
| infrastructure.vnets.sap.subnet_app         |`prefix`                       | **required**  |          | If provided, the application subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_db          |`arm_id`                       | **required**  |          | If provided, the Azure resource ID for the database subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_db          |`name`                         | **required**  |          | If provided, the name for the database subnet to be created
| infrastructure.vnets.sap.subnet_db          |`prefix`                       | **required**  |          | If provided, the database subnet address prefix of the subnet |
| | <br/> | 
| infrastructure.vnets.sap.subnet_web         |`arm_id`                       | optional      |          | If provided, the Azure resource ID for the web dispatcher subnet |
| | **or** | 
| infrastructure.vnets.sap.subnet_web         |`name`                         | optional      |          | If provided, the name for the web dispatcher subnet to be created
| infrastructure.vnets.sap.subnet_web         |`prefix`                       | optional      |          | If provided, the web dispatcher subnet address prefix of the subnet |
| | <br/> | 
| databases.[].`platform`                               | **required**  |          | <!-- TODO: --> |
| databases.[].`high_availability`                      |               |          | <!-- TODO: --> |
| databases.[].`db_version`                             | deprecate     |          | <!-- TODO: --> |
| databases.[].`size`                                   | **required**  |          | <!-- TODO: --> |
| databases.[].os.`publisher`                           |               |          | <!-- TODO: --> |
| databases.[].os.`offer`                               |               |          | <!-- TODO: --> |
| databases.[].os.`sku`                                 |               |          | <!-- TODO: --> |
| databases.[].`zones`                                  |               |          | <!-- TODO: --> |
| databases.[].credentials.`db_systemdb_password`       | deprecate     |          | <!-- TODO: --> |
| databases.[].credentials.`os_sidadm_password`         | deprecate     |          | <!-- TODO: --> |
| databases.[].credentials.`os_sapadm_password`         | deprecate     |          | <!-- TODO: --> |
| databases.[].credentials.`xsa_admin_password`         | deprecate     |          | <!-- TODO: --> |
| databases.[].credentials.`cockpit_admin_password`     | deprecate     |          | <!-- TODO: --> |
| databases.[].credentials.`ha_cluster_password`        | deprecate     |          | <!-- TODO: --> |
| databases.[].`avset_arm_ids.[]`                       |               |          | <!-- TODO: --> |
| databases.[].`use_DHCP`                               |               | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| databases.[].dbnodes.[].`name`                        |               |          | <!-- TODO: --> |
| databases.[].dbnodes.[].`role`                        |               |          | <!-- TODO: --> |
| application.`enable_deployment`                       |               |          | <!-- TODO: --> |
| application.`sid`                                     | **required**  |          | <!-- TODO: --> |
| application.`scs_instance_number`                     |               |          | <!-- TODO: --> |
| application.`ers_instance_number`                     |               |          | <!-- TODO: --> |
| application.`scs_high_availability`                   |               |          | <!-- TODO: --> |
| application.`application_server_count`                |               |          | <!-- TODO: --> |
| application.`webdispatcher_count`                     |               |          | <!-- TODO: --> |
| application.`app_zones`                               |               |          | <!-- TODO: --> |
| application.`scs_zones`                               |               |          | <!-- TODO: --> |
| application.`web_zones`                               |               |          | <!-- TODO: --> |
| application.`use_DHCP`                                |               | false    | If set to true the IP addresses for the VMs will be provided by the subnet |
| application.authentication.`type`                     |               |          | <!-- TODO: --> |
| application.authentication.`username`                 | optional      | azureadm | <!-- TODO: --> |
| sshkey.`path_to_public_key`                           | optional      |          | <!-- TODO: --> |
| sshkey.`path_to_private_key`                          | optional      |          | <!-- TODO: --> |
| options.`enable_secure_transfer`                      | deprecate     | true     | <!-- TODO: --> |
| options.`enable_prometheus`                           | deprecate     |          | deprecate <!-- TODO: --> |
| options.`resource_offset`                             |               | 0        | The offset used for resource naming when creating multiple resources, for example -disk0, disk1. If changing the resource_offset to 1 the disks will be renamed disk1, disk2 |
| options.`disk_encryption_set_id`                      |               |          | Disk encryption key to use for encrypting the managed disks |
| options.`use_local_keyvault_for_secrets`              |               | false    | By default the ssh keys and the VM credentials are stored in the sap landscape keyvault. If this value is set to true the secrets are stored in the key vaults created by the SDU deployment  |


<br/><br/><br/><br/>

---

<br/><br/>

# Examples
<br/>

## Minimal (Default) input parameter JSON

```
{
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : "",
  "landscape_tfstate_key"             : "",
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnets": {
      "sap": {
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
    "app_zones": [],
    "scs_zones": [],
    "web_zones": [],
    "authentication": {
      "type"                          : "key",
      "username"                      : "azureadm"
    }
  },
  "options": {
    "enable_secure_transfer"          : true,
    "enable_prometheus"               : true
  }
}
```

<br/><br/><br/>

## Complete input parameter JSON

```
{
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : "",
  "landscape_tfstate_key"             : "",
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "resource_group": {
      "is_existing"                   : "false",
      "arm_id"                        : ""
    },
    "anchor_vms": {
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
        "is_existing"                 : "false",
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
      "credentials": {
        "db_systemdb_password"        : "<db_systemdb_password>",
        "os_sidadm_password"          : "<os_sidadm_password>",
        "os_sapadm_password"          : "<os_sapadm_password>",
        "xsa_admin_password"          : "<xsa_admin_password>",
        "cockpit_admin_password"      : "<cockpit_admin_password>",
        "ha_cluster_password"         : "<ha_cluster_password>"
      },
      "avset_arm_ids"                 : [
                                          "/subscriptions/xxxx/resourceGroups/yyyy/providers/Microsoft.Compute/availabilitySets/PROTO-SID_db_avset"
                                        ],
      "use_DHCP"                      : false,
      "dbnodes": [
        {
          "name"                      : "hdb1",
          "role"                      : "worker"
        },
        {
          "name"                      : "hdb2",
          "role"                      : "worker"
        },
        {
          "name"                      : "hdb3",
          "role"                      : "standby"
        }
      ]
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
    "app_zones"                       : ["1", "2"],
    "scs_zones"                       : ["1"],
    "web_zones"                       : ["1"],
    "use_DHCP"                        : false,
    "authentication": {
      "type"                          : "key",
      "username"                      : "azureadm"
    }
  },
  "sshkey": {
    "path_to_public_key"              : "sshkey.pub",
    "path_to_private_key"             : "sshkey"
  },
  "options": {
    "enable_secure_transfer"          : true,
    "enable_prometheus"               : true
  }
}
```




