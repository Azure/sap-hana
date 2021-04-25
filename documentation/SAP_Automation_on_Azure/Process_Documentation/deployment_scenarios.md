# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Deployment Scenarios #

The SAP Deployment Automation Framework support the following deployment models:

# Greenfield deployment #

In this scenario All Azure artifacts will be created by the automation framework.

## **Greenfield deployment using the deployer** ##

This scenario contains the following deployments

- Deployer
- Library
- Workload(s)
- System(s)

A sample configuration for this is available here:

| Component                | Template |
| :------------------------| :----------------------------------------------------------------------- |
| Deployer                 | [DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json](./WORKSPACES/DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json)
| Library                  | [LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json](./WORKSPACES/LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json)
| Workload                 | [LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json](./WORKSPACES//LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json)
| System                   | [SYSTEM/DEV-WEEU-SAP01-X00/DEV-WEEU-SAP01-X00.json](./WORKSPACES/SYSTEM/DEV-WEEU-SAP01-X00/DEV-WEEU-SAP01-X00.json)


## **Testing the Greenfield deployment using the deployer - scenario** ##



From the cloned repository copy the following folders to your root folder (*Azure_SAP_Automated_Deployment/WORKSPACES*) for parameter files

- DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE
- LIBRARY/MGMT-WEEU-SAP_LIBRARY
- LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE
- SYSTEM/DEV-WEEU-SAP01-X00

The helper script below can be used to copy the pertinent folders.

```bash
cd ~/Azure_SAP_Automated_Deployment
mkdir -p WORKSPACES/DEPLOYER
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE WORKSPACES/DEPLOYER/. -r

mkdir -p WORKSPACES/LIBRARY
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LIBRARY/MGMT-WEEU-SAP_LIBRARY WORKSPACES/LIBRARY/. -r

mkdir -p WORKSPACES/LANDSCAPE
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE WORKSPACES/LANDSCAPE/. -r

mkdir -p WORKSPACES/SYSTEM
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/SYSTEM/DEV-WEEU-SAP01-X00 WORKSPACES/SYSTEM/. -r
cd WORKSPACES

```

**Prepare the region**

The deployer and library can be deployed using the ***prepare_region.sh*** command. Before executing this command ensure that you have the details for the Service Principal that will be used to deploy the artifacts. For Service Principal creation see [Service Principal Creation](./spn.md).

```bash
cd ~/Azure_SAP_Automated_Deployment/WORKSPACES
mkdir -p WORKSPACES/DEPLOYER
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE WORKSPACES/DEPLOYER/. -r

mkdir -p WORKSPACES/LIBRARY
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LIBRARY/MGMT-WEEU-SAP_LIBRARY WORKSPACES/LIBRARY/. -r

mkdir -p WORKSPACES/LANDSCAPE
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE WORKSPACES/LANDSCAPE/. -r

mkdir -p WORKSPACES/SYSTEM
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/SYSTEM/DEV-WEEU-SAP01-X00 WORKSPACES/SYSTEM/. -r
cd WORKSPACES

```





## **Greenfield deployment without the deployer** ##

This scenario contains the following deployments:

- Library
- Workload(s)
- System(s)

A sample configuration for this is available here

| Component                | Template |
| :------------------------| :----------------------------------------------------------------------- |

| Library                  | [Library](./WORKSPACES/LIBRARY/MGMT-NOEU-SAP_LIBRARY/MGMT-NOEU-SAP_LIBRARY.json)
| Workload                 | [Workload](./WORKSPACES//LANDSCAPE/DEV-NOEU-SAP02-INFRASTRUCTURE/DEV-NOEU-SAP02-INFRASTRUCTURE.json)
| System                   | [Library](./WORKSPACES/SYSTEM/DEV-NOEU-SAP02-X02/DEV-NOEU-SAP02-X02.json)

The scenario requires an existing key vault that contains the SPN credentials for the SPN that will be used to deploy the workload zone. This can be defined in the parameter file with the kv_spn_id parameter.

```json
"key_vault" : {
    "kv_spn_id"         : "<ARMresourceID>"
} 
```

By providing false in the "use" attribute in the deployer section, the automation framwork will not use any information from the deployer state file.

```json
"deployer" : {
    "use": false
} 
```

# Brownfield deployment #

In this scenario the deployment will be performed using existing virtual networks, subnets and network security groups.

## **Brownfield deployment using the deployer** ##

This scenario contains the following deployments

- Deployer
- Library
- Workload(s)
- System(s)

A sample configuration for this is available here

| Component                | Template |
| :------------------------|  :----------------------------------------------------------------------- |
| Deployer                 | [Deployer](./WORKSPACES/DEPLOYER/MGMT-EUS2-DEP01-INFRASTRUCTURE/MGMT-EUS2-DEP01-INFRASTRUCTURE.json) |  
| Library                  | [Library](./WORKSPACES/LIBRARY/MGMT-EUS2-SAP_LIBRARY/MGMT-EUS2-SAP_LIBRARY.json) |  
| Workload                 | [Workload](./WORKSPACES//LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE/QA-EUS2-SAP03-INFRASTRUCTURE.json) |  
| System                   | [System](./WORKSPACES/SYSTEM/QA-EUS2-SAP03-X01/QA-EUS2-SAP03-X01.json) |  

## **Brownfield deployment without the deployer** ##

This scenario contains the following deployments:

- Library
- Workload(s)
- System(s)

A sample configuration for this is available here

| Component                | Template |
| :------------------------|  :----------------------------------------------------------------------- |
| Library                  | [Library](./WORKSPACES/LIBRARY/MGMT-WUS2-SAP_LIBRARY/MGMT-WUS2-SAP_LIBRARY.json)
| Workload                 | [Workload](./WORKSPACES/LANDSCAPE/QA-WUS2-SAP04-INFRASTRUCTURE/QA-WUS2-SAP04-INFRASTRUCTURE.json)
| System                   | [Library](./WORKSPACES/SYSTEM/QA-WUS2-SAP04-X03/QA-WUS2-SAP04-X03.json)

The scenario requires an existing key vault that contains the SPN credentials for the SPN that will be used to deploy the workload zone. This can be defined in the parameter file with the kv_spn_id parameter.

```json
"key_vault" : {
    "kv_spn_id"         : "<ARMresourceID>"
} 

By providing false in the "use" attribute in the deployer section, the automation framwork will not use any information from the deployer state file.

```json
"deployer" : {
    "use": false
} 
```

