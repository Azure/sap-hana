# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Deployment scripts

The repository contains scripts for bootstrapping the deployer, bootstrapping the library, and a generic deployment script that can be used to deploy any of the systems, there are two sets of orchestration scripts, one for bash and one for PowerShell.

These scripts assume that the configuration files are stored using the structure specified above.

## Requirements

The following two environment variables need to be exported:

|Environment Variable|Description|
| :- | :- |
|ARM_SUBSCRIPTION_ID|Specifies the subscription to use for the deployment|
|DEPLOYMENT_REPO_PATH|Specifies the path to the “sap-hana” folder containing the cloned repository.|

The section below lists the scripts and their usage.

## **install_deployer.sh**

This script bootstraps the deployer.

Usage:

```bash
${DEPLOYMENT_REPO_PATH}scripts/install_deployer.sh

Parameters:

-p parameter file for the deployer
-h show help
```

Example:

```bash
${DEPLOYMENT_REPO_PATH}scripts/install_deployer.sh -p DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json
```

## **install_library.sh**

This script bootstraps the deployer.

Usage:

```bash
${DEPLOYMENT_REPO_PATH}scripts/install_library.sh

Parameters:

-p parameter file for the library
-d relative path to the deployer folder (relative from the library parameter file)
-h show help
```

Example:

```bash
${DEPLOYMENT_REPO_PATH}scripts/install_library.sh 
-p LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json
-d ../../DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/ 
```

## **prepare_region.sh**

Wrapper script that:

1. Bootstraps the deployer
2. Set the SPN secrets
3. Bootstraps the library
4. Migrates the state of the deployer to Azure
5. Migrates the state of the library to Azure
6. Deploys the environment

Usage:

```bash
${DEPLOYMENT_REPO_PATH}scripts/prepare_region.sh

Parameters:
-d deployer parameter file
-l library parameter file
-e environment parameter file
-h show help
```

Example

```bash
${DEPLOYMENT_REPO_PATH}scripts/prepare_region.sh 
-d DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \
-l LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \
-e LANDSCAPE/PROD-WEEU-SAP00-INFRASTRUCTURE/PROD-WEEU-SAP00-INFRASTRUCTURE.json
```

## **installer.sh**

Deployment helper, the script can be used to deploy the deployer, the library, the landscape or the system (SID)

Usage:

```bash
${DEPLOYMENT_REPO_PATH}scripts/installer.sh

Parameters:
-p parameter file
-t type of system to deploy
-h show help
```

Example:

```bash
${DEPLOYMENT_REPO_PATH}scripts/installer.sh
-p SYSTEM/PROD-WEEU-SAP00-ABC/PROD-WEEU-SAP00-ABC.json \
-t sap_system
```

## **set_secret.sh**

Helper script to set the SPN secrets in Azure keyvault.

Usage:

```bash
${DEPLOYMENT_REPO_PATH}scripts/set_secret.sh

Parameters:
-e environment name
-v vault name
-c SPN app id
-s SPN password
-t tenant id
-i true/false. If true runs in interactive mode prompting for input
-h Show help
```

Example:

```bash
set\_secret.sh
-e PROD
-v prodweeuusrabc
-c 11111111-1111-1111-1111-111111111111
-s SECRETPassword
-t 222222222-2222-2222-2222-222222222222
```

## **PowerShell based orchestration cmdlets**

The repository contains a PowerShell module for bootstrapping the deployer, bootstrapping the library, and a generic deployment script that can be used to deploy and of the systems.

## Installation

1. Create a new folder "SAPDeploymentUtilities" in the "[$Env:USERPROFILE]\Documents\WindowsPowerShell\Modules" folder.
2. Copy the files from the "sap-hana\deploy\scripts\pwsh\SAPDeploymentUtilities\Output\SAPDeploymentUtilities\" folder to the folder from the previous step.

Open a Powershell prompt with Administrative privileges and run the:

```Powershell
Import-Module SAPDeploymentUtilities.psd1
```

### **New-SAPDeployer**

This cmdlet bootstraps the deployer.

Usage:

```Powershell
New-SAPDeployer -Parameterfile <>

Parameters:
-Parameterfile parameter file for the deployer
```

Example:

```Powershell
New-SAPDeployer -Parameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json
```

Help:

```Powershell
Get-Help New-SAPDeployer -Examples
```

### **New-SAPLibrary**

This cmdlet bootstraps the deployer.

Usage:

```Powershell
New-SAPLibrary -Parameterfile <> -DeployerFolderRelativePath <>

Parameters:
-Parameterfile This is the parameter file for the library
-DeployerFolderRelativePath This is relative path to the deployer folder (relative from the library parameter file)
```

Example:

```Powershell
New-SAPLibrary -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -DeployerFolderRelativePath ..\..\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\
```

Help:

```Powershell
Get-Help New-SAPLibrary -Examples
```

## **New-SAPAutomationRegion**

Wrapper cmdlet that deploys a full new SAP Workload Zone (Deployer, Library and Workload VNet), using the following steps:

1. Bootstrap the deployer.
2. Set the SPN secrets.
3. Bootstrap the library.
4. Migrates the state of the deployer to Azure.
5. Migrates the state of the library to Azure.
6. Deploy the environment.

Usage:

```Powershell
New-SAPAutomationRegion -DeployerParameterfile <> -LibraryParameterfile <>
`     `-EnvironmentParameterfile <>

Parameters:
-DeployerParameterfile This is the parameter file for the Deployer
-LibraryParameterfile This is the parameter file for the Library
-EnvironmentParameterfile This is the parameter file for the workload vnet
```

Example:

```Powershell
New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json -LibraryParameterfile .LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json -EnvironmentParameterfile .\LANDSCAPE\PROD-WEEU-SAP00-INFRASTRUCTURE\PROD-WEEU-SAP00-INFRASTRUCTURE.json
```

Help:

```Powershell
Get-Help New-SAPAutomationRegion -Examples
```

## **New-SAPSystem**

Deployment helper, the cmdlet can be used to deploy the deployer, the library, the landscape or the system (SID)

Usage:

```Powershell
$New-SAPSystem -Parameterfile <> -Type <>

Parameters:
-Parameterfile This is the parameter file for the system
-Type Is the type of system to deploy (sap_deployer, sap_library, sap_landscape, sap_system)
```

Example:

```Powershell
$New-SAPSystem -Parameterfile SYSTEM/PROD-WEEU-SAP00-ABC / PROD-WEEU-SAP00-ABC.json -Type sap_system
```

## **Set-SAPSPNSecrets**

Helper cmdlet to set the SPN secrets in Azure keyvault.

Usage:

```Powershell
Set-SAPSPNSecrets -Environment <> -VaultName <vaultname> -SPN_id <appId> -SPN_password <clientsecret> -Tenant <TenantID> 

Parameters:
-Environment environment name
-VaultName vault name
-SPN_id SPN app id
-SPN_password SPN password
-Tenant tenant id of the SPN
```

Example:

```Powershell
Set-SAPSPNSecrets -Environment PROD -VaultName prodweeuusrabc -SPN_id 11111111-1111-1111-1111-111111111111 -SPN_password SECRETPassword -Tenant 222222222-2222-2222-2222-222222222222
```
