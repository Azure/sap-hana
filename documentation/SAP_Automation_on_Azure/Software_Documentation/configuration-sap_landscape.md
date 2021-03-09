<!-- TODO: 
Remove files and maintain here in documentation
deploy/terraform/run/sap_landscape/saplandscape_full.json
deploy/terraform/run/sap_landscape/saplandscape.json
-->
### <img src="../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Configuration - SAP Landscape <!-- omit in toc -->

<br/>

## Table of Contents <!-- omit in toc -->
<br/>

- [Parameter file construction](#parameter-file-construction)
- [Examples](#examples)
  - [Minimal (Default) input parameter JSON](#minimal-default-input-parameter-json)
  - [Complete input parameter JSON](#complete-input-parameter-json)

# Parameter file construction

The parameters to the automation are passed in a JSON structure with a set of root nodes defining the properties of the system.

Node                                   |  Description |
| :------------------------------------------|  :---------- |
| infrastructure|This node defines the resource group and the networking information. |
| authentication|This node defines the authentication details for the system. |
| options |If specified - This node defines special settings for the environment |

<br/>

A comprehensive representation of the json is shown below.

JSON structure

```json
{                                                                                 <-- JSON opening tag
  "infrastructure": {
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "resource_group": {
      "arm_id"                        : "",                                       <-- Optional
      "name"                          : ""                                        <-- Optional
    },
    "vnets": {
      "sap": {
        "arm_id"                      : "",                                       <-- Optional
        "address_space"               : "10.1.0.0/16",                            <-- Required Parameter unless arm_id is provided
        "subnet_iscsi": {
          "name"                      : "",                                       <-- Optional
          "prefix"                    : "10.1.0.0/24"                             <-- Optional
        }
      }
    },
    "iscsi": {
      "iscsi_count"                   : 3,                                        <-- Optional
      "use_DHCP"                      : false                                     <-- Optional
    }
  },
  "key_vault": {
    "kv_user_id"                      : "",                                       <-- Optional
    "kv_prvt_id"                      : "",                                       <-- Optional
    "kv_spn_id"                       : "",                                       <-- Optional
    "kv_sid_sshkey_prvt"              : "",                                       <-- Optional
    "kv_sid_sshkey_pub"               : "",                                       <-- Optional
    "kv_iscsi_username"               : "",                                       <-- Optional
    "kv_iscsi_sshkey_prvt"            : "",                                       <-- Optional
    "kv_iscsi_sshkey_pub"             : "",                                       <-- Optional
    "kv_iscsi_pwd"                    : ""                                        <-- Optional
  },
  "authentication": {
    "username"                        : "azureadm"                                <-- Optional
    "password"                        : "T0pSecret"                               <-- Optional 
    "path_to_public_key"              : "sshkey.pub",                             <-- Optional
    "path_to_private_key"             : "sshkey"                                  <-- Optional
  }

  "options": {},                                                                   <-- Optional
  "tfstate_resource_id"               : "",                                       <-- Required Parameter
  "deployer_tfstate_key"              : "",                                       <-- Required Parameter
}                                                                                 <-- JSON Closing tag
```

Node                                   | attribute                     | Type          | Default  | Description |
| :-------------------------------------------- | :---------------------------- | ------------- | :------- | :---------- |
| infrastructure.                             | `environment`                 | **required**  | -------- | The Environment is a 5 Character designator used for identifying the workload zone. An example of partitioning would be, PROD / NP (Production and Non-Production). <br/>Environments may also be tied to a unique SPN or Subscription. |
| infrastructure.                             | `region`                      | **required**  |          | This specifies the Azure Region in which to deploy. |
| infrastructure.resource_group.              | `arm_id`                      | optional      |          | If specified the Azure Resource ID of Resource Group to use for the deployment |
| | <br/> | 
| infrastructure.resource_group.              | `name`                        | optional      |          | If specified the name of the resource group to be created |
| | <br/> | 
| infrastructure.vnets.sap.                     |`arm_id`                     | optional      |          | If provided the VNet specified by the resource ID will be used |
| | **or** | 
| infrastructure.vnets.sap.                     | `name`                      | **required**  | -        | The name of the Virtual Network to be created| 
| infrastructure.vnets.sap.                     | `address_space`              | **required**  | -        | The address space of the VNet to be used. Required if the arm_id field is empty. |
| | <br/> | 
| infrastructure.vnets.sap.subnet_iscsi.                     |`name`          | optional      |          | If specified, the name of the iscsi subnet |
| infrastructure.vnets.sap.subnet_iscsi.                     | `prefix`        | optional      | -        | If specified, provisions a subnet within the VNET address space. <br/>The CIDR should be size appropriate for the expected usage.<br/>Recommendation /28 CIDR. Supports up to 12 servers. |
| infrastructure.iscsi.                     | `iscsi_count`                    | optional      |          | The number of iSCSI devices to create |
| infrastructure.vnets.sap.                     | `use_DHCP`                   | optional      |   false | If set to true the Virtual Machines will get their IP addresses from the Azure subnet|
| | <br/> | 
| key_vault.                     | `kv_user_id`                                | optional      |          |If provided, the Key Vault resource ID of the user Key Vault to be used.  |
| key_vault.                     | `kv_prvt_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault to be used. |
| key_vault.                     | `kv_spn_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault containing the SPN details. |
| key_vault.                     | `kv_sid_sshkey_prvt`                        | optional      |          | <!-- TODO: Yunzi --> |
| key_vault.                     | `kv_sid_sshkey_pub`                         | optional      |          | <!-- TODO: Yunzi --> |
| key_vault.                     | `kv_iscsi_username`                         | optional      |          | <!-- TODO: Yunzi --> |
| key_vault.                     | `kv_iscsi_sshkey_prvt`                      | optional      |          | <!-- TODO: Yunzi --> |
| key_vault.                     | `kv_iscsi_sshkey_pub`                       | optional      |          | <!-- TODO: Yunzi --> |
| key_vault.                     | `kv_iscsi_pwd`                              | optional      |          | <!-- TODO: Yunzi --> |
| | <br/> | 
| authentication.                     | `username`                           | optional      |          | If specified the default username for the environment |
| authentication.                     | `password`                           | optional      |          | If specified the password for the environment. <br/>If not specified, Terraform will create a password and store it in keyvault |
| authentication.                     | `path_to_public_key`                           | optional      |          | If specified the path to the SSH public key file. If not specified, Terraform will create  and store it in keyvault |
| authentication.                     | `path_to_private_key`                          | optional      |          | If specified the path to the SSH private key file. If not specified, Terraform will create  and store it in keyvault |
| | <br/> | 
| `tfstate_resource_id`                         |`Remote State`                 | **required**  | -        | This is the Azure Resource ID for the Storage Account in which the Statefiles are stored. Typically this is deployed by the SAP Library execution unit. |
| `deployer_tfstate_key`                        | `Remote State`                  | **required**  | -        | This is the deployer state file name, used for finding the correct state file.  <br/>**Case-sensitive**  |
| `deployer_tfstate_key`                        | `Remote State`                  | **required**  | -        | This is the deployer state file name, used for finding the correct state file.  <br/>**Case-sensitive**  |

<br/><br/><br/><br/>

---

<br/><br/>

# Examples
<br/>

## Minimal (Default) input parameter JSON

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnets": {
      "sap": {
        "address_space"               : "10.1.0.0/16"
      }
    }
  },
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : ""

}
```

<br/><br/><br/>

## Complete input parameter JSON

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "resource_group": {
      "arm_id"                        : "",
      "name"                          : ""
    },
    "vnets": {
      "sap": {
        "arm_id"                      : "SAP0",
        "arm_id"                      : "",
        "address_space"               : "10.1.0.0/16",
        "subnet_iscsi": {
          "name"                      : "",
          "prefix"                    : "10.1.0.0/24"
        }
      }
    },
    "iscsi": {
      "iscsi_count"                   : 3,
      "use_DHCP"                      : false
    }
  },
  "key_vault": {
    "kv_user_id"                      : "",
    "kv_prvt_id"                      : "",
    "kv_spn_id"                      : "",
    "kv_sid_sshkey_prvt"              : "",
    "kv_sid_sshkey_pub"               : "",
    "kv_iscsi_username"               : "",
    "kv_iscsi_sshkey_prvt"            : "",
    "kv_iscsi_sshkey_pub"             : "",
    "kv_iscsi_pwd"                    : ""
  },
"authentication": {
    "username"                        : "azureadm",
    "password"                        : "",
    "path_to_public_key"              : "sshkey.pub",
    "path_to_private_key"             : "sshkey"
  },
  "options": {},
  "tfstate_resource_id"               : "",
  "deployer_tfstate_key"              : ""
}
```




