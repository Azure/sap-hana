<!-- TODO: 
Remove files and maintain here in documentation
deploy/terraform/bootstrap/sap_deployer/deployer_full.json
deploy/terraform/bootstrap/sap_deployer/deployer.json
deploy/terraform/run/sap_deployer/deployer_full.json
deploy/terraform/run/sap_deployer/deployer.json
-->
### <img src="../assets/images/UnicornSAPBlack256x256.png" width="64px"> SAP Deployment Automation Framework <!-- omit in toc -->
<br/><br/>

# Configuration - Deployer with Public IP <!-- omit in toc -->

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
  "infrastructure": {
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "codename"                        : "",                                       <-- Optional
    "vnets": {
      "management": {
        "arm_id"                      : "",                                       <-- Optional Identifier
        "name"                        : "DEP00",                                  <-- Required Parameter if arm_id is not specified
        "address_space"               : "10.0.0.0/27",                            <-- Required Parameter if arm_id is not specified
        "subnet_mgmt": {
          "arm_id"                    : ""                                        <-- Optional Identifier
          "name"                      : "deployment_subnet"                       <-- Optional Identifier
          "prefix"                    : "10.0.0.16/28"                            <-- Required Parameter
        }
      }
    },
   "resource_group": {
      "arm_id"                        : ""                                        <-- Optional Identifier
    }

  },
  "key_vault": {
    "kv_user_id"                      : "",                                       <-- Optional
    "kv_prvt_id"                      : "",                                       <-- Optional
    "kv_sshkey_prvt"                  : "",                                       <-- Optional
    "kv_sshkey_pub"                   : "",                                       <-- Optional
    "kv_username"                     : "",                                       <-- Optional
    "kv_pwd"                          : ""                                        <-- Optional
  },
  "sshkey": {
    "path_to_public_key"              : "sshkey.pub",                             <-- Optional
    "path_to_private_key"             : "sshkey"                                  <-- Optional
  },
  "options": {
    "enable_secure_transfer"          : true,                                     <-- Optional, Default: true
    "enable_deployer_public_ip"       : false                                     <-- Optional, Default: false
  }
}                                                                                 <-- JSON Closing tag
```

| Object Path                                   | Parameter                     | Type          | Default  | Description |
| :-------------------------------------------- | :---------------------------- | ------------- | :------- | :---------- |
| infrastructure                                | `environment`                 | **required**  | -        | The Environment is a 5 Character designator used for partitioning. An example of partitioning would be, PROD / NP /QA /DEV (Production, Non-Production, Quality Assurance, Development). Environments may also be tied to a unique SPN or Subscription |
| <p>                                           | `region`                      | **required**  | -        | This specifies the Azure Region in which to deploy |
|<P>|||
| infrastructure.vnets.management               | `arm_id`                      | **required**      | -        | If provided, The Azure Resource Identifier of the VNet to use
| | **or** | 
| infrastructure.vnets.management               | `name`                      | **required**  | -        | The name of the VNet| infrastructure.vnets.management               | `name`                        | **required**  | -        | This assigns a 7 Character designator for the Deployer VNET. Recommended value: DEP00 |
| <p>                                           | `address_space`               | **required**  | -        | CIDR of the VNET Address Space. We recommend a /27 CIDR (32 IP's).<br/>This allows space for 2x /28 CIDR (16 IP's). |
||<p>| 
| infrastructure.vnets.management.subnet_mgmt               | `arm_id`                      | **required**      | -        | If provided, The Azure Resource Identifier of the subnet to use
| | **or** | 
| infrastructure.vnets.management.subnet_mgmt               | `name`                      | **required**  | -        | The name of the subnet| infrastructure.vnets.management               | `name`                        | **required**  | -        | This assigns a 7 Character designator for the Deployer VNET. Recommended value: deployment-subnet |
|infrastructure.vnets.management.subnet_mgmt   | `prefix`                      | **required**  | -        | CIDR of the Deployer Subnet. We recommend a /28 CIDR (16 IP's). |
||<p>| 
infrastructure.resource_group               | `arm_id`                      | optional      | -        | If provided, the Azure Resource Identifier for the resource group to use for the deployment 
||<p>| 
| key_vault                                     | `kv_user_id`                  | optional      | -        | This provides a way to override the user keyvault to use. If specified no key vault will be created by the deployment<br/>- Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `kv_prvt_id`                  | optional      | -        | This provides a way to override the private keyvault to use. If specified no key vault will be created by the deployment<br/>- Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `kv_spn_id`                   | optional      | -        | - This provides a way to provide the override for the keyvault that will contain the Service Principal Secrets <br/>Not required in a standard deployment.<br/>|
| <p>                                           | `kv_sshkey_prvt`              | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `kv_sshkey_pub`               | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `kv_username`                 | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `kv_pwd`                      | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| sshkey                                        | `path_to_public_key`          | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| <p>                                           | `path_to_private_key`         | optional      | -        | - Not required in a standard deployment.<br/> <!-- TODO: Yunzi --> |
| options                                       | `enable_secure_transfer`      | optional      | true     | - Not required in a standard deployment.<br/> <!-- TODO: --> |
| <p>                                           | `enable_deployer_public_ip`   | optional      | false    | Controls whether the deployer VM will have a public IP address or not.- Not required in a standard deployment.<br/> <!-- TODO: --> |


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

<br/><br/><br/>

## Complete input parameter JSON

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnets": {
      "management": {
        "name"                        : "NP-EUS2-DEP00-vnet",
        "address_space"               : "10.0.0.0/27",
        "subnet_mgmt": {
          "prefix"                    : "10.0.0.16/28"
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
  "options": {
    "enable_secure_transfer"          : true,
    "enable_deployer_public_ip"       : false
  }
}
```
