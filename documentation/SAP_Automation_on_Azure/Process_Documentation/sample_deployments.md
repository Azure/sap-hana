# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## Table of Contents <!-- omit in toc --> ##

- [Sample Deployments](#Sample-Deployments)
  - [Greenfield](##Scenario-1:-Greenfield-including-deployer)
  - [Greenfield (no deployer)](##Scenario-2:-Greenfield-without-deployer)
  - [Brownfield](##Scenario-3:-Brownfield-including-deployer)
  - [Brownfield (no deployer)](##Scenario-4:-Brownfield-without-deployer)
  - [Brownfield with custom disk sizing (no deployer)](##Scenario-4:-Brownfield-without-deployer-using-a-custom-disk-configuration)

---

This document describes 5 sample deployments, two greenfield deployments and 3 brownfield deployments

## **Scenario 1: Greenfield including deployer** ##

In this scenario all Azure artifacts will be created by the automation framework.
The deployment includes two environments "MGMT" and "DEV" in the West Europe Azure region.

This scenario contains the following deployments

- Deployer
- Library
- Workload
- System: SID X00, with 2 Application Servers, a highly available Central Services instance, a single webdispatcher using a single node HANA backend using SUSE 12 SP5


**Note** Both environments need a Service Principal registered in the deployer key vault.


A sample configuration for this is available here:

| Component                | Template |
| :------------------------| :----------------------------------------------------------------------- |
| Deployer                 | [DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json](./WORKSPACES/DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json)
| Library                  | [LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json](./WORKSPACES/LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json)
| Workload                 | [LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json](./WORKSPACES//LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE/DEV-WEEU-SAP01-INFRASTRUCTURE.json)
| System                   | [SYSTEM/DEV-WEEU-SAP01-X00/DEV-WEEU-SAP01-X00.json](./WORKSPACES/SYSTEM/DEV-WEEU-SAP01-X00/DEV-WEEU-SAP01-X00.json)

<br>

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

### **Scenario 1 - Prepare the region** ###

The deployer and library can be deployed using the ***prepare_region.sh*** command. Before executing this command ensure that you have the details for the Service Principal that will be used to deploy the artifacts. 

For Service Principal creation see [Service Principal Creation](./spn.md).
Substitute the Service Principal values in the script below before running the script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES

    $DEPLOYMENT_REPO_PATH/scripts/prepare_region.sh
        --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json \
        --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json
        --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
        --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
        --spn_secret ************************ \
        --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \
        --auto-approve

```

When using PowerShell the same can be achieved with the ***New-SAPAutomationRegion*** PowerShell cmdlet

```PowerShell
    New-SAPAutomationRegion 
    -DeployerParameterfile .\DEPLOYER\MGMT-EUS2-DEP01-INFRASTRUCTURE\MGMT-EUS2-DEP01-INFRASTRUCTURE.json 
    -LibraryParameterfile .\LIBRARY\MGMT-EUS2-SAP_LIBRARY\MGMT-EUS2-SAP_LIBRARY.json 
    -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
    -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
    -SPN_password  ************************ 
    -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 
    -Silent             
```

### **Scenario 1 - Deploy the workload** ###

Before the actual SAP system can be deployed a workload zone needs to be prepared. For deploying the DEV workload zone (vnet & keyvaults) navigate to the folder(LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE) containing the DEV-WEEU-SAP01-INFRASTRUCTURE.json parameter file and use the ***install_workloadzone.ssh*** script.

For Service Principal creation see [Service Principal Creation](./spn.md).
Substitute your Service Principal values in the script below before running the script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/install_workloadzone.sh --parameterfile DEV-WEEU-SAP01-INFRASTRUCTURE.json \
    --deployer_environment MGMT
    --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
    --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
    --spn_secret ************************ \
    --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \
    --auto-approve
```

When using PowerShell the same can be achieved with the ***New-SAPWorkloadZone*** PowerShell cmdlet:

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-NOEU-SAP02-INFRASTRUCTURE

    New-SAPWorkloadZone --parameterfile .\DEV-NOEU-SAP02-INFRASTRUCTURE.json 
        -DeployerEnvironment MGMT
        -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
        -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
        -SPN_password ************************ 
        -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 

```

### **Scenario 1 - Deploying the SAP system** ###

For deploying the SAP system navigate to the folder(DEV-WEEU-SAP01-X00) containing the DEV-WEEU-SAP01-X00.json parameter file and use the ***installer.sh*** script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/DEV-WEEU-SAP01-X00

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh --parameterfile DEV-WEEU-SAP01-X00.json --type sap_system --auto-approve
```

When using PowerShell the same can be achieved with the ***New-SAPSystem*** PowerShell cmdlet.

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\DEV-WEEU-SAP01-X00

    New-SAPSystem --parameterfile .\DEV-WEEU-SAP01-X00.json 
        -Type sap_system

```

<br>

## **Scenario 2: Greenfield without deployer** ##

In this scenario all Azure artifacts will be created by the automation framework. The deployment includes two environments "MGMT" and "DEV" in the North Europe Azure region.

This scenario contains the following deployments:

- Library
- Workload
- System: SID X00, with a single Application Server,  a Central Services instance and single node HANA backend all using Redhat 7.7

**Note** Both environments need a Service Principal registered in the deployer key vault.

A sample configuration for this is available here:

| Component                | Template |
| :------------------------| :----------------------------------------------------------------------- |
| Library                  | [LIBRARY/MGMT-NOEU-SAP_LIBRARY/MGMT-NOEU-SAP_LIBRARY.json](./WORKSPACES/LIBRARY/MGMT-NOEU-SAP_LIBRARY/MGMT-NOEU-SAP_LIBRARY.json) |
| Workload                 | [DEV-NOEU-SAP02-INFRASTRUCTURE.json](./WORKSPACES//LANDSCAPE/DEV-NOEU-SAP02-INFRASTRUCTURE/DEV-NOEU-SAP02-INFRASTRUCTURE.json) |
| System                   | [DEV-NOEU-SAP02-X02/DEV-NOEU-SAP02-X02.json](./WORKSPACES/SYSTEM/DEV-NOEU-SAP02-X02/DEV-NOEU-SAP02-X02.json) |

<br>

From the cloned repository copy the following folders to your root folder (*Azure_SAP_Automated_Deployment/WORKSPACES*) for parameter files

- LIBRARY/MGMT-NOEU-SAP_LIBRARY
- LANDSCAPE/DEV-NOEU-SAP02-INFRASTRUCTURE
- SYSTEM/DEV-NOEU-SAP01-X02

The helper script below can be used to copy the folders.

```bash
cd ~/Azure_SAP_Automated_Deployment

mkdir -p WORKSPACES/LIBRARY
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LIBRARY/MGMT-NOEU-SAP_LIBRARY WORKSPACES/LIBRARY/. -r

mkdir -p WORKSPACES/LANDSCAPE
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LANDSCAPE/DEV-NOEU-SAP02-INFRASTRUCTURE WORKSPACES/LANDSCAPE/. -r

mkdir -p WORKSPACES/SYSTEM
cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/SYSTEM/DEV-NOEU-SAP02-X02 WORKSPACES/SYSTEM/. -r
cd WORKSPACES
```

The scenario requires an existing key vault that contains the SPN credentials for the SPN that will be used to deploy the workload zone. This must be defined in the parameter file with the kv_spn_id parameter.

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

### **Scenario 2 - Deploy the library** ###

The deployer and library can be deployed using the ***install_library.sh*** and the ***installer.sh*** commands. Update the MGMT-NOEU-SAP_LIBRARY.json file and add the resource id for the keyvault containing the service principal details.

```bash

    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/MGMT-NOEU-SAP_LIBRARY

    $DEPLOYMENT_REPO_PATH/deploy/scripts/install_library.sh --parameterfile MGMT-NOEU-SAP_LIBRARY.json 
```

Capture the value for the remote_state_storage_account_name from the output of the previous command and migrate the terraform state to Azure using:

```bash

    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/MGMT-NOEU-SAP_LIBRARY

    $DEPLOYMENT_REPO_PATH/deploy/scripts/installer.sh --parameterfile MGMT-NOEU-SAP_LIBRARY.json --type sap_library
```

When using PowerShell the same can be achieved with the ***New-SAPLibrary*** and the ***New-SAPSystem** PowerShell cmdlets:

```PowerShell

    cd Azure_SAP_Automated_Deployment\WORKSPACES\LIBRARY\MGMT-NOEU-SAP_LIBRARY

    New-SAPLibrary --parameterfile .\MGMT-NOEU-SAP_LIBRARY.json 

```

Capture the value for the remote_state_storage_account_name from the output of the previous command and migrate the terraform state to Azure.

```PowerShell
    cd Azure_SAP_Automated_Deployment\WORKSPACES\LIBRARY\MGMT-NOEU-SAP_LIBRARY

    New-SAPSystem --parameterfile .\MGMT-WUS2-SAP_LIBRARY.json -Type sap_library -StorageAccountName mgmtwus2tfstate###   

```

### **Scenario 2 - Deploy the workload** ###

The workload deployed using the ***install_workloadzone.sh*** command. Update the MGMT-NOEU-SAP_LIBRARY.json file and add the resource id for the keyvault containing the service principal details.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/DEV-NOEU-SAP02-INFRASTRUCTURE

     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh --parameterfile DEV-NOEU-SAP02-INFRASTRUCTURE.json \
     --state_subscription wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww \
     --storageaccountname mgmtweeutfstate### \
     --vault MGMTWEEUDEP00user### \
     --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
     --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
     --spn_secret ************************ \
     --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 
```

When using PowerShell the same can be achieved with the ***New-SAPWorkloadZone*** PowerShell cmdlet.

```PowerShell
    
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-NOEU-SAP02-INFRASTRUCTURE

    New-SAPWorkloadZone --parameterfile .\DEV-NOEU-SAP02-INFRASTRUCTURE.json 
        -State_subscription wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww 
        -Vault MGMTWEEUDEP00user###
        -StorageAccountName mgmtweeutfstate 
        -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
        -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
        -SPN_password ************************ 
        -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 

```

### **Scenario 2 - Deploying the SAP system** ###

For deploying the SAP system navigate to the folder(DEV-NOEU-SAP02-X02) containing the DEV-NOEU-SAP02-X02.json parameter file and use the ***installer.sh*** script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/DEV-NOEU-SAP02-X02

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh --parameterfile DEV-NOEU-SAP02-X02.json --type sap_system --auto-approve
```

When using PowerShell the same can be achieved with the ***New-SAPSystem*** PowerShell cmdlet:

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\DEV-NOEU-SAP02-X02

    New-SAPSystem --parameterfile .\DEV-NOEU-SAP02-X02.json 
        -Type sap_system

```

<br>

## **Scenario 3: Brownfield including deployer** ##

In this scenario the deployment will be performed using existing resource groups, storage accounts, virtual networks, subnets and network security groups.

In this scenario the Azure artifacts will be deployed into an existing Azure environment. The deployment includes two environments "MGMT" and "QA" in the East US 2 region.

**Note** Both environments need a Service Principal registered in the deployer key vault.

This scenario contains the following deployments

- Deployer
- Library
- Workload
- System: SID X01, with 2 Application Servers, a highly available Central Services instance, a single webdispatcher all Windows Server 2016, using a Microsoft SQL Server backend using.

A sample configuration for this is available here:

| Component                | Template |
| :------------------------| :----------------------------------------------------------------------- |
| Deployer                 | [DEPLOYER/MGMT-EUS2-DEP01-INFRASTRUCTURE/MGMT-EUS2-DEP01-INFRASTRUCTURE.json](./WORKSPACES/DEPLOYER/MGMT-EUS2-DEP00-INFRASTRUCTURE/MGMT-EUS2-DEP01-INFRASTRUCTURE.json)
| Library                  | [LIBRARY/MGMT-EUS2-SAP_LIBRARY/MGMT-EUS2-SAP_LIBRARY.json](./WORKSPACES/LIBRARY/MGMT-EUS2-SAP_LIBRARY/MGMT-EUS2-SAP_LIBRARY.json)
| Workload                 | [LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE/QA-EUS2-SAP03-INFRASTRUCTURE.json](./WORKSPACES//LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE/QA-EUS2-SAP03-INFRASTRUCTURE.json)
| System                   | [SYSTEM/QA-EUS2-SAP03-X01/QA-EUS2-SAP03-X01.json](./WORKSPACES/SYSTEM/QA-EUS2-SAP03-X01/QA-EUS2-SAP03-X01.json)

<br>

From the cloned repository copy the following folders to your root folder (*Azure_SAP_Automated_Deployment/WORKSPACES*) for parameter files

- DEPLOYER/MGMT-EUS2-DEP00-INFRASTRUCTURE
- LIBRARY/MGMT-EUS2-SAP_LIBRARY
- LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE
- SYSTEM/QA-EUS2-SAP03-X01

The helper script below can be used to copy the pertinent folders.

```bash
    cd ~/Azure_SAP_Automated_Deployment
    mkdir -p WORKSPACES/DEPLOYER
    cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/DEPLOYER/MGMT-EUS2-DEP01-INFRASTRUCTURE WORKSPACES/DEPLOYER/. -r

    mkdir -p WORKSPACES/LIBRARY
    cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LIBRARY/MGMT-EUS2-SAP_LIBRARY WORKSPACES/LIBRARY/. -r

    mkdir -p WORKSPACES/LANDSCAPE
    cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE WORKSPACES/LANDSCAPE/. -r

    mkdir -p WORKSPACES/SYSTEM
    cp sap-hana/documentation/SAP_Automation_on_Azure/Process_Documentation/WORKSPACES/SYSTEM/QA-EUS2-SAP03-X01 WORKSPACES/SYSTEM/. -r
    cd WORKSPACES

```

### **Scenario 3 - Prepare the region** ###

The deployer and library can be deployed using the ***prepare_region.sh*** command. Before executing this command ensure that you have the details for the Service Principal that will be used to deploy the artifacts.

For Service Principal creation see [Service Principal Creation](./spn.md).
Substitute you Service Principal values in the script below before running the script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES

    $DEPLOYMENT_REPO_PATH/scripts/prepare_region.sh
        --deployer_parameter_file DEPLOYER/MGMT-EUS2-DEP01-INFRASTRUCTURE/MGMT-EUS2-DEP01-INFRASTRUCTURE.json \
        --library_parameter_file LIBRARY/MGMT-EUS2-SAP_LIBRARY/MGMT-EUS2-SAP_LIBRARY.json
        --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
        --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
        --spn_secret ************************ \
        --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \
        --auto-approve

```

When using PowerShell the same can be achieved with the ***New-SAPAutomationRegion*** PowerShell cmdlet:

```PowerShell
    New-SAPAutomationRegion 
    -DeployerParameterfile .\DEPLOYER\MGMT-EUS2-DEP01-INFRASTRUCTURE\MGMT-EUS2-DEP01-INFRASTRUCTURE.json 
    -LibraryParameterfile .\LIBRARY\MGMT-EUS2-SAP_LIBRARY\MGMT-EUS2-SAP_LIBRARY.json 
    -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
    -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
    -SPN_password  ************************ 
    -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 
    -Silent             
```

### **Scenario 3 - Deploy the workload** ###

Before the actual SAP system can be deployed a workload zone needs to be prepared. For deploying the QA workload zone (vnet & keyvaults) navigate to the folder(LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE) containing the QA-EUS2-SAP03-INFRASTRUCTURE.json parameter file and use the install_workloadzone script.

For Service Principal creation see [Service Principal Creation](./spn.md).
Substitute you Service Principal values in the script below before running the script.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/QA-EUS2-SAP03-INFRASTRUCTURE

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/install_workloadzone.sh --parameterfile QA-EUS2-SAP03-INFRASTRUCTURE.json \
    --deployer_environment MGMT
    --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
    --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
    --spn_secret ************************ \
    --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \
    --auto-approve
```

When using PowerShell the same can be achieved with the ***New-SAPWorkloadZone*** PowerShell cmdlet:

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\QA-EUS2-SAP03-INFRASTRUCTURE

    New-SAPWorkloadZone --parameterfile .\QA-EUS2-SAP03-INFRASTRUCTURE.json 
        -DeployerEnvironment MGMT
        -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
        -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
        -SPN_password ************************ 
        -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 

```

### **Scenario 3 - Deploying the SAP system** ###

For deploying the SAP system navigate to the folder(QA-EUS2-SAP03-X01) containing the QA-EUS2-SAP03-X01.json parameter file and use the ***installer.sh*** script.



```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/QA-EUS2-SAP03-X01

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh --parameterfile QA-EUS2-SAP03-X01.json --type sap_system --auto-approve
```

When using PowerShell the same can be achieved with the ***New-SAPSystem*** PowerShell cmdlet

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\QA-EUS2-SAP03-X01

    New-SAPSystem --parameterfile .\QA-EUS2-SAP03-X01.json 
        -Type sap_system

```

## **Scenario 4: Brownfield without deployer** ##

In this scenario the Azure artifacts will be deployed into an existing Azure environment. The deployment includes two environments "MGMT" and "PROD" in the West US 2 region.

**Note** Both environments need a Service Principal registered in the deployer key vault.

This scenario contains the following deployments:

- Library
- Workload
- System: SID X03, with 2 Application Servers, a highly available Central Services instance, a single webdispatcher using a single node HANA backend using SUSE 12 SP5
- System: SID X04, with 2 Application Servers, a highly available Central Services instance, a single webdispatcher using a single node HANA backend using SUSE 12 SP5 using a custom disk configuration

A sample configuration for this is available here

| Component                  | Template |
| :--------------------------|  :----------------------------------------------------------------------- |
| Library                    | [MGMT-WUS2-SAP_LIBRARY/MGMT-WUS2-SAP_LIBRARY.json](./WORKSPACES/LIBRARY/MGMT-WUS2-SAP_LIBRARY/MGMT-WUS2-SAP_LIBRARY.json) |
| Workload                   | [PROD-WUS2-SAP04-INFRASTRUCTURE/PROD-WUS2-SAP04-INFRASTRUCTURE.json](./WORKSPACES/LANDSCAPE/PROD-WUS2-SAP04-INFRASTRUCTURE/PROD-WUS2-SAP04-INFRASTRUCTURE.json) |
| System                     | [PROD-WUS2-SAP04-X03/PROD-WUS2-SAP04-X03.json](./WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X03/PROD-WUS2-SAP04-X03.json) |
| System (custom disk sizes) | [PROD-WUS2-SAP04-X04/PROD-WUS2-SAP04-X04.json](./WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X04/PROD-WUS2-SAP04-X04.json) |
| Custom disk size file      | [PROD-WUS2-SAP04-X04/X04-Disk_sizes.json](./WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X04/X04-Disk_sizes.json) |

<br>

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

### **Scenario 4 - Deploy the library** ###

The deployer and library can be deployed using the ***install_library.sh*** command. Update the MGMT-WUS2-SAP_LIBRARY.json file and add the resource id for the keyvault containing the service principal details.

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/MGMT-WUS2-SAP_LIBRARY

    $DEPLOYMENT_REPO_PATH/deploy/scripts/install_library.sh --parameterfile MGMT-WUS2-SAP_LIBRARY.json 

```

Capture the value for the remote_state_storage_account_name from the output of the previous command and migrate the terraform state to Azure using:

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/MGMT-WUS2-SAP_LIBRARY

    $DEPLOYMENT_REPO_PATH/deploy/scripts/installer.sh --parameterfile MGMT-WUS2-SAP_LIBRARY.json --type sap_library

```

When using PowerShell the same can be achieved with the ***New-SAPLibrary*** PowerShell cmdlet.

```PowerShell

    New-SAPLibrary --parameterfile .\MGMT-WUS2-SAP_LIBRARY.json 

```

Capture the value for the remote_state_storage_account_name from the output of the previous command and migrate the terraform state to Azure.

```PowerShell

    New-SAPSystem --parameterfile .\MGMT-WUS2-SAP_LIBRARY.json -Type sap_library -StorageAccountName mgmtwus2tfstate###   

```

### **Scenario 4 - Deploy the workload** ###

Update the PROD-WUS2-SAP04-INFRASTRUCTURE.json file and add the resource id for the keyvault containing the service principal details. Deploy the system with the ***install_workloadzone.sh*** bash script:

```bash
    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/LANDSCAPE/PROD-WUS2-SAP04-INFRASTRUCTURE

     $DEPLOYMENT_REPO_PATH/deploy/scripts/install_workloadzone.sh --parameterfile PROD-WUS2-SAP04-INFRASTRUCTURE.json \
     --state_subscription wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww \
     --storageaccountname mgmteus2tfstate### \
     --vault MGMTEUS2DEP02user### \
     --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
     --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \
     --spn_secret ************************ \
     --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 
```

When using PowerShell the same can be achieved with the ***New-SAPWorkloadZone*** PowerShell cmdlet:

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\PROD-WUS2-SAP04-INFRASTRUCTURE

    New-SAPWorkloadZone --parameterfile .\PROD-WUS2-SAP04-INFRASTRUCTURE.json 
        -State_subscription wwwwwwww-wwww-wwww-wwww-wwwwwwwwwwww 
        -Vault MGMTEUS2DEP02user### \
        -StorageAccountName mgmteus2tfstate 
        -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
        -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy 
        -SPN_password ************************ 
        -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz 

```

### **Scenario 4 - Deploying the SAP system** ###

For deploying the SAP system navigate to the folder(PROD-WUS2-SAP04-X03) containing the PROD-WUS2-SAP04-X03.json parameter file and use the ***installer.sh*** script.

```bash

    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X03

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh --parameterfile PROD-WUS2-SAP04-X03.json --type sap_system --auto-approve

```

When using PowerShell the same can be achieved with the ***New-SAPSystem*** PowerShell cmdlet.

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\PROD-WUS2-SAP04-X03

    New-SAPSystem --parameterfile .\PROD-WUS2-SAP04-X03.json 
        -Type sap_system

```

## **Scenario 4: Brownfield without deployer using a custom disk configuration** ##

This deployment has a custom disk configuration for the HANA deployment.The custom disk sizing for the system is defined here: [PROD-WUS2-SAP04-X04/X04-Disk_sizes.json](./WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X04/X04-Disk_sizes.json)

**Note** To match the disk sizes with the deployment the node beneath the "db" node needs to be the same as the database.size attribute in the configuration json

```json
{​​​​​​
  "db": {​​​​​​
    "X04": {​​​​​​
           }
        }
}

```

```json
    "databases": [
      {
        "size"                        : "X04",
      }
    ],

```

For deploying the SAP system navigate to the folder(PROD-WUS2-SAP04-X04) containing the PROD-WUS2-SAP04-X04.json parameter file and deploy the system using the ***installer.sh*** script.

```bash

    cd ~/Azure_SAP_Automated_Deployment/WORKSPACES/SYSTEM/PROD-WUS2-SAP04-X04

    ${DEPLOYMENT_REPO_PATH}deploy/scripts/installer.sh --parameterfile PROD-WUS2-SAP04-X04.json --type sap_system --auto-approve

```

When using PowerShell the same can be achieved with the ***New-SAPSystem*** PowerShell cmdlet.

```PowerShell
    cd \Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\PROD-WUS2-SAP04-X04

    New-SAPSystem --parameterfile .\PROD-WUS2-SAP04-X04.json 
        -Type sap_system

```

