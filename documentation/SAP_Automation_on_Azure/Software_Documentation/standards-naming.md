
# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## Naming Conventions for SAP Automation Framework <!-- omit in toc --> ##

Table of Contents
- [1 Naming Standards](#1-naming-standards)
  - [1.1 Terraform](#11-terraform)
  - [1.2 Concepts](#12-concepts)
    - [1.2.1 ENVIRONMENT](#121-environment)
    - [1.2.2 SAP_VNET](#122-sap_vnet)
    - [1.2.3 CODENAME](#123-codename)
  - [1.3 Conventions](#13-conventions)
    - [1.3.1 Key](#131-key)
    - [1.3.2 DEPLOYER](#132-deployer)
    - [1.3.3 SAP_LIBRARY](#133-sap_library)
    - [1.3.4 SAP_VNET](#134-sap_vnet)
    - [1.3.5 SDU](#135-sdu)
    - [1.3.6 Region Mapping](#136-region-mapping)
      - [1.3.6.1 Example: Variable Definition](#1361-example-variable-definition)
      - [1.3.6.2 Example Usage:](#1362-example-usage)
- [2 TAGS](#2-tags)
- [3 Appendix](#3-appendix)
  - [3.1 Definitions, acronyms, and abbreviations](#31-definitions-acronyms-and-abbreviations)

<br/><br/>

## 1 Naming Standards##
<br/>

## 1.1 Terraform
The objective in the naming convention is to provide a descriptive naming scheme while also allowing for logical partitioning.
- Allow for the SAP_VNET Infrastructure to be deployed into any supported region.
- Allow for multiple deployments of the SAP_VNET Infrastructure into the same region. This creates a Partitioning of the SAP_VNETS.
- Allow the SDU to be deployed into any SAP_VNET to support SA, HA, DR, and Fall-Forward.
<br/><br/>

## 1.2 Concepts
<br/>

### 1.2.1 ENVIRONMENT
Logical boundary for the environment. (ex. PROTOTYPE, SANDBOX, NONPROD, PROD).
This introduces the concept of Partitioning or Blast Radius Containment.
Terraform could have credentials/RBAC to provision exclusively within a subscription, and NOT have the credentials/RBAC to provision into other environments.
The naming convention allows this to be collapsed to a single subscription, but that is not the preferred model.
<br/><br/><br/>

### 1.2.2 SAP_VNET
Logical partitioning of VNETs. This is the support for more than one VNET within a region.
<br/><br/><br/>

### 1.2.3 CODENAME
Logical partitioning of development cycles or projects.
<br/><br/><br/>

## 1.3 Conventions
<br/>

### 1.3.1 Key
<br/>

| Key         | Legnth   | Description                   |
| ----------- | -------- | ----------------------------- |
| ENVIRONMENT | (5 CHAR) | SND, PROTO, NP, PROD          |
| REGION_MAP  | (4 CHAR) | Representation of region.     |
| SAP_VNET    | (7 CHAR) | Logical VNET Name (Ex: SAP0)  |
| CODENAME    |          | A Logical name assigned to a development effort. This would allow old and new versions of identical resources to coexist in the dev environment. Or it is just a fun name for your deployment. |
|             |          |                                                                    |
<br/><br/><br/>

### 1.3.2 DEPLOYER
<br/>

| DEPLOYER         | Max Char     | Example                       |
| ---------------  | -----------: | ----------------------------- |
| Resource Group   | 80           | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}-INFRASTRUCTURE`<br/>Ex: `PROTO-WUS2-DEPLOY-INFRASTRUCTURE`               |
| VNET             | 38<br/>(64)  | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}-vnet`                                                                    |
| Subnet           | 80           | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_deployment-subnet`                                                       |
| Storage Account  | 24           | `{environment(5CHAR)}{region_map(4CHAR)}{sap_vnet(7CHAR)}diag(5CHAR){RND(3CHAR)}`<br/>Ex: `protowus2deploydiagxxx` |
| NSG              | 80           | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_deployment-nsg`                                                          |
| Route Table      |              | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_routeTable`                                                              |
| UDR              |              | `{remote_vnet}_Hub-udr`                                                                                            |
| NIC              | 80           | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_{computername}-nic`<br/>No naming convention needed for ip_configuration block.<br/>Ex: name `-ipconfig1`
| Disk             |              | `{vm.name}-deploy00`<br/>Code: `${azurerm_virtual_machine.iscsi.*.name}-iscsi00`<br/>Ex: `PROTO-WUS2-DEPLOY_deploy00-deploy00`
| VM               | 80           | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_{computername}`
| OS Disk          |              | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_{computername}-OsDisk`
| Computer Name    |              | `{environment[_map]}{region_map}{deploy_vnet}deploy##`
| Managed Identity |              | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}-msi`
| Key Vault        | 24           | `{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}{DEPLOY_VNET(7CHAR)}prvt{RND(3CHAR)}`<br/>`{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}{DEPLOY_VNET(7CHAR)}user{RND(3CHAR)}`
| Public IP        |              | `{ENVIRONMENT}-{REGION_MAP}-{DEPLOY_VNET}_{computername}-pip`
|                  |              |                                                                    |
<br/><br/><br/>

### 1.3.3 SAP_LIBRARY
<br/>

| SAP_LIBRARY      | Max Char     | Example                       |
| ---------------  | -----------: | ----------------------------- |
| Resource Group   | 80           | `{ENVIRONMENT}-{REGION_MAP}-SAP_LIBRARY`<br/>Ex: `PROTO-WUS2-SAP_LIBRARY`
| Storage Account  | 24           | `{environment(5char)}{region_map(4CHAR)}saplib(12CHAR){RND(3CHAR)}`<br/>Ex: `protowus2saplibxxx`
| Key Vault        | 24           | `{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}SAPLIBprvt(12CHAR){RND(3CHAR)}`<br/>`{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}SAPLIBuser(12CHAR){RND(3CHAR)}`
|                  |              |                                                                    |
<br/><br/><br/>


### 1.3.4 SAP_VNET
<br/>

| SAP_VNET         | Max Char     | Example                       |
| ---------------  | -----------: | ----------------------------- |
| Resource Group   | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}-INFRASTRUCTURE`<br/>Ex: PROTO-WUS2-SAP0-INFRASTRUCTURE
| VNET             | 38<br/>(64)  | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}-vnet`
| Peering          | 80           | `{local_vnet_name}_to_{remote_vnet_name}`
| Subnet           | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_utility-subnet`
| Storage Account  | 24           | `{environment(5char)}{region_map(4CHAR)}{sap_vnet(7CHAR)}diag(5CHAR){RND(3CHAR)}`<br/>Ex: protowus2sap0diagxxx
| NSG              | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_iscsi-nsg`
| Route Table      |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_routeTable`
| UDR              |              | `{remote_vnet}_Hub-udr`
| AVSET            |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_iscsi-avset`
| NIC              | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_iscsi##-nic`
| Disk             |              | `{vm.name}-iscsi00`<br/>Code: `${azurerm_virtual_machine.iscsi.*.name}-iscsi00`<br/>Ex: PROTO-WUS2-SAP0_iscsi00-iscsi00
| VM               |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_iscsi##`
| OS Disk          |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_iscsi##-OsDisk`
| Computer Name    |              | `{environment[_map]}{sap_vnet}{region_map}iscsi##`
| Key Vault        | 24           | `{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}{SAP_VNET(7CHAR)}prvt(5CHAR){RND(3CHAR)}`<br/>`{ENVIRONMENT(5char)}{REGION_MAP(4CHAR)}{SAP_VNET(7CHAR)}user(5CHAR){RND(3CHAR)}`
|                  |              |                                                                    |
<br/><br/><br/>


### 1.3.5 SDU
<br/>

| SDU                    | Max Char     | Example                       |
| ---------------        | -----------: | ----------------------------- |
| Resource Group         | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}`<br/>Ex: PROTO-WUS2_S4DEV-Z00
| PPG                    |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_ppg`
| Subnet                 | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_app-subnet`
| NSG (NIC)              | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_app-nsg` |
| NIC (Subnet)           | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_appSubnet-nsg` |
| AVSET                  |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_app-avset` |
| NIC                    | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_{vm.name}-{sub}-nic`<br/>Ex: `_{vm.name}-app-nic`<br/>Ex: `_{vm.name}-web-nic`<br/>Ex: `_{vm.name}-admin-nic`<br/>Ex: `_{vm.name}-db-nic` |
| Disk                   |              | `{vm.name}-sap00`<br/>`{vm.name}-data00`<br/>`{vm.name}-log00`<br/>`{vm.name}-backup00`<br/><br/>Code: `${element(azurerm_virtual_machine.app.*.name, count.index)}-sap00` |
| VM                     | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_{computername}` |
| OS Disk                |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_{computername}-osDisk` |
| Computer Name (DB)     | 14           | `{sapsid}d{dbsid}##[l|w]{nodeNumber(1CHAR)}{RND(3CHAR)}`<br/><br/>Ex: `z00dhdb00l0abc`<br/>Ex: `z00dora00l0abc`<br/><br/>14< Char SAP Specific |
| Computer Name (Non-DB) | 14           | `{sapsid}app##[l|w]{RND(3CHAR)}`<br/>Code: `${lower(var._sap_sid)}app${format("%02d", count.index)}`<br/><br/>Ex: `z00app00labc`<br/>Ex: `z00scs00wabc`<br/>Ex: `z00web00labc`<br/><br/>14< Char SAP Specific |
| ALB                    | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_db-alb` |
| ALB Front end IP       |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_dbAlb-feip` |
| ALB Backend Pool       |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_dbAlb-bePool` |
| ALB Rule               | 80           | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_dbAlb-rule_port-01` |
| Key Vault (Private)    | 24           | `{ENVIRONMENT(5CHAR)}{REGION_MAP(4CHAR)}{SAP_VNET(7CHAR)}SIDp(5CHAR){RND(3CHAR)}` |
| Key Vault (User)       | 24           | `{ENVIRONMENT(5CHAR)}{REGION_MAP(4CHAR)}{SAP_VNET(7CHAR)}SIDu(5CHAR){RND(3CHAR)}` |
| ALB Health Probe       |              | `{ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}_{CODENAME}-{SID}_dbAlb-hp?` |
|                        |              |                                                                    |
- app or hdb can be replaced with an identifier. (ex. app, db, scs, web)
- Numbering starts at 0
- Numbers formatted for two characters (ex. 00)
<br/><br/><br/>


### 1.3.6 Region Mapping
<br/>


#### 1.3.6.1 Example: Variable Definition
<br/>

```
variable "_region_mapping" {
                              type        = map(string)
                              description = "Region Mapping: Full = Single CHAR, 4-CHAR"

  # 28 Regions
  default = {
                              westus              = "weus"
                              westus2             = "wus2"
                              centralus           = "ceus"
                              eastus              = "eaus"
                              eastus2             = "eus2"
                              northcentralus      = "ncus"
                              southcentralus      = "scus"
                              westcentralus       = "wcus"
                              northeurope         = "noeu"
                              westeurope          = "weeu"
                              eastasia            = "eaas"
                              southeastasia       = "seas"
                              brazilsouth         = "brso"
                              japaneast           = "jpea"
                              japanwest           = "jpwe"
                              centralindia        = "cein"
                              southindia          = "soin"
                              westindia           = "wein"
                              uksouth2            = "uks2"
                              uknorth             = "ukno"
                              canadacentral       = "cace"
                              canadaeast          = "caea"
                              australiaeast       = "auea"
                              australiasoutheast  = "ause"
                              uksouth             = "ukso"
                              ukwest              = "ukwe"
                              koreacentral        = "koce"
                              koreasouth          = "koso"
  }
}
```
<br/><br/><br/>


#### 1.3.6.2 Example Usage:
<br/>

```
  # naming standard       = {ENVIRONMENT}-{REGION_MAP}-{SAP_VNET}-INFRASTRUCTURE
  name                    = "${upper(var.__environment)}-${
                               upper(element(split(",", lookup(var.__region_mapping, var.__region, "-,unknown")),1))}-${
                               upper(var.__sap_vnet)}-INFRASTRUCTURE"
```
<br/><br/><br/>


# 2 TAGS
<br/>
Notes:
Track
<br/><br/><br/>


# 3 Appendix
<br/>


## 3.1 Definitions, acronyms, and abbreviations
<br/>

| Term         | Description                                     |
| ------------ | ----------------------------------------------- |
| ALB          | Azure Load Balancer                             |
| AVSET        | Azure Availability Set                          |
| B&D          | Build and Destroy, alternate term, Fall-Forward |
| DR           | Disaster Recovery                               |
| Fall-Forward | See B&D                                         |
| HA           | High-Availability                               |
| NIC          | Network Interface Component                     |
| NSG          | Network Security Group                          |
| SA           | Stand-Alone                                     |
| SDU          | SAP Deployment Unit                             |
| UDR          | User Defined Route                              |
| VM           | Virtual Machine                                 |
| VNET         | Virtual Network                                 |
|              |                                                 | 
<br/><br/><br/>