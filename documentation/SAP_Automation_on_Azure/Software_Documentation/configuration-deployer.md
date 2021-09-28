
# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## Configuration <!-- omit in toc --> ##

This document describes how the deployment infrastructure is configured.
### Table of Contents <!-- omit in toc --> ###

- [Parameter file construction](##parameter-file-construction)
- [Examples](##examples)
  - [Minimal (Default) input parameter JSON](##minimal-default-input-parameter-json)
  - [Complete input parameter JSON](##complete-input-parameter-json)

## Parameter file construction ##

The configuration of the deployement infrastructure is achieved using a json formatted parameter file. The key section is the **infrastructure** section which is used to define the Azure region, the Virtual Network information (either a new Virtual Network or an existing). The **key_vault** section is used to specify the Azure Resource Identifiers for existing key vaults if the customer wants to use existing vaults.

### JSON structure ###

```
{                                                                                 <-- JSON opening tag
  "infrastructure": {
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "codename"                        : "",                                       <-- Optional
    "vnets": {
      "management": {
        "arm_id"                      : "",                                       <-- Optional Identifier
        "name"                        : "DEP00",                                  <-- Required Parameter
        "address_space"               : "10.0.0.0/25",                            <-- Required Parameter if arm_id is not specified
        "subnet_mgmt": {
          "arm_id"                    : "",                                       <-- Optional Identifier
          "name"                      : "deployment_subnet",                      <-- Optional Identifier
          "prefix"                    : "10.0.0.16/28"                            <-- Required Parameter
        }
        "subnet_fw": {
          "arm_id"                    : "",                                       <-- Optional Identifier
          "prefix"                    : "10.0.0.32/26"                            <-- Required Parameter
        }
      }
    },
   "resource_group": {
      "name"                          : ""                                        <-- Optional Identifier
      "arm_id"                        : ""                                        <-- Optional Identifier
    }

  },
  "key_vault": {
    "kv_user_id"                      : "",                                       <-- Optional
    "kv_prvt_id"                      : "",                                       <-- Optional
    "kv_spn_id"                       : "",                                       <-- Optional
    "kv_sshkey_prvt"                  : "",                                       <-- Optional
    "kv_sshkey_pub"                   : "",                                       <-- Optional
    "kv_username"                     : "",                                       <-- Optional
    "kv_pwd"                          : ""                                        <-- Optional
  },
  "authentication": {
    "path_to_public_key"              : "sshkey.pub",                             <-- Optional
    "path_to_private_key"             : "sshkey"                                  <-- Optional
  },

  "options": {
    "deployer_enable_public_ip"       : false                                     <-- Optional, Default: false
  },
  "firewall_deployment"               : true                                      <-- Optional, Default: false
}                                                                                 <-- JSON Closing tag
```

The complete set of configuratiuon options is listed in the table below.

| Node                                   | Value                     | Type          | Default  | Description |
| :-------------------------------------------- | :---------------------------- | ------------- | :------- | :---------- |
| infrastructure.                             | `environment`                 | **required**  | -------- | The Environment is a 5 Character designator used for identifying the workload zone. An example of partitioning would be, PROD / NP (Production and Non-Production). Environments may also be tied to a unique SPN or Subscription. |
| infrastructure.                             | `region`                      | **required**  |          | This specifies the Azure Region in which to deploy. |
| infrastructure.resource_group.              | `arm_id`                      | optional      |          | If specified the Azure Resource ID of Resource Group to use for the deployment |
| infrastructure.resource_group.              | `name`                        | optional      |          | If specified the name of the resource group to be created |
| |  |
| infrastructure.vnets.management               | `arm_id`                      | **required**      | -        | If provided, The Azure Resource Identifier of the VNet to use
| | **or** |
| infrastructure.vnets.management               | `name`                      | **required**  | -        | The logical identifier of the VNet| infrastructure.vnets.management               | `name`                        | **required**  | -        | This assigns a 7 Character designator for the Deployer VNET. Recommended value: DEP00 |
| <p>                                           | `address_space`               | **required**  | -        | CIDR of the VNET Address Space. We recommend a /27 CIDR (32 IP's).<br/>This allows space for 2x /28 CIDR (16 IP's). <br/> If you want to include the Azure Firewall use a /25 CIDR as Azure Firewall requires a /26 range |
||<p>| 
| infrastructure.vnets.management.subnet_mgmt               | `arm_id`                      | **required**      | -        | If provided, The Azure Resource Identifier of the subnet to use
| | **or** | 
| infrastructure.vnets.management.subnet_mgmt               | `name`                      | **required**  | -        | The name of the subnet| infrastructure.vnets.management               | `name`                        | **required**  | -        | This assigns a 7 Character designator for the Deployer VNET. Recommended value: deployment-subnet |
|infrastructure.vnets.management.subnet_mgmt   | `prefix`                      | **required**  | -        | CIDR of the Deployer Subnet. We recommend a /28 CIDR (16 IP's). |
| | <br/> | 
| infrastructure.vnets.management.subnet_fw               | `arm_id`                      | **required**      | -        | If provided, The Azure Resource Identifier of the subnet to use for the Azure Firewall
| | **or** | 
|infrastructure.vnets.management.subnet_fw   | `prefix`                      | **required**  | -        | CIDR of the Deployer Subnet. We recommend a /26 CIDR. |
| | <br/> | 
| key_vault.                     | `kv_user_id`                                | optional      |          |If provided, the Key Vault resource ID of the user Key Vault to be used.  |
| key_vault.                     | `kv_prvt_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault to be used. |
| key_vault.                     | `kv_spn_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault containing the SPN details. |
| key_vault.                                    | `kv_sshkey_prvt`              | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| key_vault.                                    | `kv_sshkey_pub`               | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| key_vault.                                    | `kv_username`                 | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| key_vault.                                    | `kv_pwd`                      | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
||<p>| 
| authentication                                        | `path_to_public_key`          | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| authentication                                           | `path_to_private_key`         | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
||<p>| 
| options                                           | `deployer_enable_public_ip`   | optional      | false    | Controls whether the deployer VM will have a public IP address or not.- Not required in a standard deployment.|
|<p>| 
| firewall_deployment                                           | `true/false`   | optional      | false    | Controls whether the deployment will include an Azure Firewall|

## Examples ##

### Minimal (Default) input parameter JSON

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnets": {
      "management": {
        "name"                        : "DEP00",
        "address_space"               : "10.0.0.0/27",
        "subnet_mgmt": {
          "prefix"                    : "10.0.0.16/28"
        }
      }
    }
  }
}
```

### Complete input parameter JSON ###

```json
  {
    "infrastructure": {
      "environment"                     : "NP",
      "region"                          : "eastus2",
      "vnets": {
        "management": {
          "name"                        : "DEP00",
          "address_space"               : "10.0.0.0/25",
          "subnet_mgmt": {
            "prefix"                    : "10.0.0.16/28"
          },
          "subnet_fw": {
            "prefix"                    : "10.0.0.32/26"
          }
        }
      }
    },
    "key_vault": {
      "kv_user_id"                      : "",
      "kv_prvt_id"                      : "",
      "kv_spn_id"                       : "",
      "kv_sshkey_prvt"                  : "",
      "kv_sshkey_pub"                   : "",
      "kv_username"                     : "",
      "kv_pwd"                          : ""
    },
  "authentication": {
      "username"                        : "azureadm",
      "password"                        : "",
      "path_to_public_key"              : "sshkey.pub",
      "path_to_private_key"             : "sshkey"
    },
  "options": {
      "deployer_enable_public_ip"       : false
    },
  "firewall_deployment"                 : true
  }
```
