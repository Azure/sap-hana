
# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Configuration - SAP Library <!-- omit in toc --> #

This document describes how the SAP Library infrastructure is configured.

## Table of Contents ##

- [Parameter file construction](#parameter-file-construction)
- [Examples](#examples)
  - [Minimal (Default) input parameter JSON](#minimal-default-input-parameter-json)
  - [Complete input parameter JSON](#complete-input-parameter-json)

## Parameter file construction ##

The configuration of the SAP Library infrastructure is achieved using a json formatted parameter file. The key section is the **infrastructure** section which is used to define the Azure region. The **key_vault** section is used to specify the Azure Resource Identifiers for existing key vaults if the customer wants to use existing vaults.

### JSON structure ###

```
{                                                                                 <-- JSON opening tag
  "infrastructure": {
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2"                                 <-- Required Parameter
    "resource_group": {
      "name"                          : ""                                        <-- Optional Parameter
      "arm_id"                        : ""                                        <-- Optional Identifier
    }

  },
  "deployer": {
    "environment"                     : "NP",                                     <-- Required Parameter
    "region"                          : "eastus2",                                <-- Required Parameter
    "vnet"                            : "DEP00"                                   <-- Required Parameter
    "use"                             : true                                      <-- Optional parameter
  },
  "key_vault":{
    "kv_user_id"                      : "",                                       <-- Optional
    "kv_prvt_id"                      : ""                                        <-- Optional
    "kv_spn_id"                       : ""                                        <-- Optional
  }
  "storage_account_sapbits": {
    "arm_id"                          : "",                                       <-- Optional
    "file_share" :{
      "is_existing"                   : true                                      <-- Optional
    },
    "sapbits_blob_container" :{
      "is_existing"                   : true                                      <-- Optional      
    }
  },
  "storage_account_tfstate": {
    "arm_id"                          : "",                                       <-- Optional
    "tfstate_blob_container" : {
      "is_existing"                   : true                                      <-- Optional
    },
    "ansible_blob_container" : {
      "is_existing"                   : true                                      <-- Optional
    }
  },
  "tfstate_resource_id",               : ""                                        <-- On reinitialization for Remote Statefile usage. 
  "deployer_statefile_foldername"      : ""                                        <-- Optional relative part to the folder containing the deployer state file. 
  
}                                                                                 <-- JSON Closing tag
```

| Node                                   | Attribute                     | Type          | Default  | Description |
| :-------------------------------------------- | :---------------------------- | ------------- | :------- | :---------- |
| infrastructure.                             | `environment`                 | **required**  | -------- | The Environment is a 5 Character designator used for identifying the workload zone. An example of partitioning would be, PROD / NP (Production and Non-Production). Environments may also be tied to a unique SPN or Subscription. |
| infrastructure.                             | `region`                      | **required**  |          | This specifies the Azure Region in which to deploy. |
| infrastructure.resource_group.              | `arm_id`                      | optional      |          | If specified the Azure Resource ID of Resource Group to use for the deployment |
| | <br/> |
| infrastructure.resource_group.              | `name`                        | optional      |          | If specified the name of the resource group to be created |
||<p>|
| deployer.                                     | `environment`                 | **required**  | -------- | This represents the environment of the deployer. Typically this will be the same as the `infrastructure.environment`. When multi-subscription is supported, this can be set to a different value. |
| deployer.                                     | `region`                      | **required**  | -------- | Azure Region in which the Deployer was deployed. |
| deployer.                                     | `vnet`                       | **required**  | -------- | Designator used for the Deployer VNET. |
| deployer.                                     | `use`                       | optional  | -------- | Flag to control if the deployment will include a "Deployer" |
| | <br/> |
| key_vault.                     | `kv_user_id`                                | optional      |          |If provided, the Key Vault resource ID of the user Key Vault to be used.  |
| key_vault.                     | `kv_prvt_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault to be used. |
| key_vault.                     | `kv_spn_id`                                | optional      |          |If provided, the Key Vault resource ID of the private Key Vault containing the SPN details. |
||<p>|
storage_account_sapbits.                        | `arm_id`                     | optional      | -        | If provided, the Azure Resource Identifier for the storage account to use for storing the SAP binaries
storage_account_sapbits.file_share.             | `is_existing`                | true/false    | -        | If true then the file share for the SAP media already exists
storage_account_sapbits.sapbits_blob_container. | `is_existing`                | true/false    | -        | If true then the container already exists
||<p>|
storage_account_tfstate.                        | `arm_id`                     | optional      | -        | If provided, the Azure Resource Identifier for the storage account to use for storing the Terraform state files
storage_account_tfstate.tfstate_blob_container. | `is_existing`                | true/false    | -        | If true then the container already exists
||<p>|
|                                              | `tfstate_resource_id`         | Remote State  |          | - This parameter is introduced when transitioning from a LOCAL deployment to a REMOTE Statefile deployment, during Reinitialization.<br/>- This is the Azure Resource ID for the Storage Account in which the Statefiles are stored. Typically this is deployed by the SAP Library execution unit. <br/>**Case-sensitive**|
|                                              | `deployer_statefile_foldername`         | Local State  |          | Defines the relative path from the folder containing the SAP Library json file to the folder containing the deployer terraform state file|

---

## Examples ##

### Minimal (Default) input parameter JSON ###

```json
  {
    "infrastructure": {
      "environment"                     : "NP",
      "region"                          : "eastus2"
    },
    "deployer": {
      "environment"                     : "NP",
      "region"                          : "eastus2",
      "vnet"                            : "DEP00"
    }
  }
```

### Complete input parameter JSON ###

```json
{
  "infrastructure": {
    "environment"                     : "NP",
    "region"                          : "eastus2"
  },
  "deployer": {
    "environment"                     : "NP",
    "region"                          : "eastus2",
    "vnet"                            : "DEP00"
    "use"                            : true
  },
  "key_vault":{
    "kv_user_id"                      : "",
    "kv_snp_id"                       : "",
    "kv_prvt_id"                      : ""
  },
  "storage_account_sapbits": {
    "arm_id"                          : "", 
    "file_share" :{
      "is_existing"                   : false
    },
    "sapbits_blob_container" :{
      "is_existing"                   : false
    }
  },
  "storage_account_tfstate": {
    "arm_id"                          : "",
    "tfstate_blob_container" : {
      "is_existing"                   : false
    },
    "ansible_blob_container" : {
      "is_existing"                   : false
    }
  },
  "tfstate_resource_id",               : ""
  "deployer_statefile_foldername",     : ""

}
```
