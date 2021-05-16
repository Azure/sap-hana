# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #
# Running the automation from a Windows PC #

To run the automation from a local Windows PC, following components need to be installed.

## **Pre-Requisites** ##

1. **Terraform** - Terraform can be downloaded from [Download Terraform - Terraform by HashiCorp](https://www.terraform.io/downloads.html). Once downloaded and extracted, ensure that the Terraform.exe executable is in a directory which is included in the SYSTEM PATH variable.
2. **Git** - Git can be installed from [Git (git-scm.com)](https://git-scm.com/)
3. **Azure CLI** - Azure CLI can be installed from <https://aka.ms/installazurecliwindows>
4. **Azure PowerShell** - Azure PowerShell can be installed from [Install Azure PowerShell with PowerShellGet | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.5.0)
5. **The latest Azure PowerShell modules** - If you already have Azure PowerShell modules, you can update to the latest version from here [Update the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.5.0#update-the-azure-powershell-module)

## **Setting up the samples for execution** ##

Once the pre-requisites are met, proceed with the next steps.

1. Create a root directory "Azure_SAP_Automated_Deployment"
2. Navigate to the "Azure_SAP_Automated_Deployment" directory
3. Clone the sap-hana repository by running the following command

   ```bash
    git clone https://github.com/Azure/sap-hana.git

    cd sap-hana

    git checkout
   ```

4. Copy the content from the
   `sap-hana\documentation\SAP_Automation_on_Azure\Process_Documentation\WORKSPACES` to the `Azure_SAP_Automated_Deployment\WORKSPACES` folder.

5. Navigate to the `Azure_SAP_Automated_Deployment\WORKSPACES` folder.

Kindly note, that triggering the deployment will need the Service Principal details (application id, secret and tenant ID)

## **Listing the contents of the deployment** ##

For a highlevel overview of what will be deployed use the Read-SAPDeploymentTemplate cmdlet to list the resources deployed by the deployment. **Note** The list does not contain all artifacts

```powershell
Read-SAPDeploymentTemplate -Parameterfile .\DEPLOYER\MGMT-WEEU-DEP00-INFRASTRUCTURE\MGMT-WEEU-DEP00-INFRASTRUCTURE.json -Type sap_deployer

Read-SAPDeploymentTemplate -Parameterfile .\LIBRARY\MGMT-WEEU-SAP_LIBRARY\MGMT-WEEU-SAP_LIBRARY.json -Type sap_library

Read-SAPDeploymentTemplate -Parameterfile .\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE\DEV-WEEU-SAP01-INFRASTRUCTURE.json -Type sap_landscape

Read-SAPDeploymentTemplate -Parameterfile .\SYSTEM\DEV-WEEU-SAP01-X00\DEV-WEEU-SAP01-X00.json -Type sap_system

```

A sample output is listed below

```txt
    Deployment information
    ----------------------------------------------------------------------------
    Environment:                  DEV
    Region:                       westeurope
    * Resource group:             (name defined by automation)

    Networking
    ----------------------------------------------------------------------------
    VNet Logical Name:            SAP01
    * Admin subnet:               (name defined by automation)
    * Admin subnet prefix:        10.110.0.0/27
    * Admin subnet nsg:           (name defined by automation)
    * Database subnet:            (name defined by automation)
    * Database subnet prefix:     10.110.0.64/27
    * Database subnet nsg:        (name defined by automation)
    * Application subnet:         (name defined by automation)
    * Application subnet prefix:  10.110.0.32/27
    * Application subnet nsg:     (name defined by automation)
    * Web subnet:                 (name defined by automation)
    * Web subnet prefix:          10.110.0.96/27
    * Web subnet nsg:             (name defined by automation)

    Database tier
    ----------------------------------------------------------------------------
    Platform:                     HANA
    High availability:            false
    Number of servers:            1
    Database sizing:              Default
    Image publisher:              SUSE
    Image offer:                  sles-sap-12-sp5
    Image sku:                    gen1
    Image version:                latest
    Deployment:                   Regional
    Networking:                   Use Azure provided IP addresses
    Authentication:               key

    Application tier
    ----------------------------------------------------------------------------
    Authentication:               key
    Application servers
    Number of servers:          2
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional
    Central Services
    Number of servers:          1
    High availability:          true
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional
    Web dispatcher
    Number of servers:          1
    Image publisher:            SUSE
    Image offer:                sles-sap-12-sp5
    Image sku:                  gen1
    Image version:              latest
    Deployment:                 Regional

    Key Vault
    ----------------------------------------------------------------------------
    SPN Key Vault:              Deployer keyvault
    User Key Vault:             Workload keyvault
    Automation Key Vault:       Workload keyvault

```

## **Preparing the region** ##

This step will deploy the deployment infrastructure and the shared library to the region specified in the parameter files.

Import the Powershell module by running the

```PowerShell
   Import-Module              C:\Azure_SAP_Automated_Deployment\sap-hana\deploy\scripts\pwsh\SAPDeploymentUtilities\Output\SAPDeploymentUtilities\SAPDeploymentUtilities.psd1
```

For preparing the region (Deployer, Library) use the New-SAPAutomationRegion cmdlet. Navigate to the root folder of your repository containing your parameter files (WORKSPACES).

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES
   New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\MGMT-WEEU-DEP00-INFRASTRUCTURE\MGMT-WEEU-DEP00-INFRASTRUCTURE.json  -LibraryParameterfile .\LIBRARY\MGMT-WEEU-SAP_LIBRARY\MGMT-WEEU-SAP_LIBRARY.json
```

or

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES
   New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\MGMT-WEEU-DEP00-INFRASTRUCTURE\MGMT-WEEU-DEP00-INFRASTRUCTURE.json  -LibraryParameterfile .\LIBRARY\MGMT-WEEU-SAP_LIBRARY\MGMT-WEEU-SAP_LIBRARY.json -Force
```

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details.

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details. If prompted for the environment details enter "MGMT" and enter the Service Principal details. The script will then deploy the rest of the resources required.

The -Force parameter can be used to clean up the terraform deployment support files from the file system (.terraform folder, terrafrom.tfstate file).

It is also possible to provide the Service Principal details as part of the script parameters:

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES
   New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\MGMT-WEEU-DEP00-INFRASTRUCTURE\MGMT-WEEU-DEP00-INFRASTRUCTURE.json  
   -LibraryParameterfile .\LIBRARY\MGMT-WEEU-SAP_LIBRARY\MGMT-WEEU-SAP_LIBRARY.json 
   -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
   -SPN_password ************************
   -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz  
   -Silent
```


## **Deploying the SAP workload zone** ## 

Before the actual SAP system can be deployed a workload zone needs to be prepared. For deploying the DEV workload zone (vnet & keyvaults) navigate to the folder(LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE) containing the DEV-WEEU-SAP01-INFRASTRUCTURE.json parameter file and use the New-SAPWorkloadZone cmdlet

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE
   New-SAPWorkloadZone -Parameterfile .\DEV-WEEU-SAP01-INFRASTRUCTURE.json
```

If the deployer deployment uses a different environment name it is possible to specify that using the Deployerenvironment parameter,

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE
   New-SAPWorkloadZone -Parameterfile .\DEV-WEEU-SAP01-INFRASTRUCTURE.json -Deployerenvironment MGMT
```

It is also possible to provide the Service Principal details as part of the parameters:

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE
   New-SAPWorkloadZone -Parameterfile .\DEV-WEEU-SAP01-INFRASTRUCTURE.json 
   -Deployerenvironment MGMT
   -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
   -SPN_password ************************
   -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz  

```

## **Removing the SAP workload zone** ##

For removing the SAP workload zone navigate to the folder(DEV-WEEU-SAP01-INFRASTRUCTURE) containing the DEV-WEEU-SAP01-INFRASTRUCTURE.json parameter file and use the Remove-SAPSystem cmdlet:

Remove-SAPSystem cmdlet:

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE
   Remove-SAPSystem -Parameterfile .\DEV-WEEU-SAP01-INFRASTRUCTURE.json -Type sap_landscape
```

## **Deploying the SAP system** ##

For deploying the SAP system navigate to the folder(DEV-WEEU-SAP01-X00) containing the DEV-WEEU-SAP01-X00.json parameter file and use the New-SAPSystem cmdlet:

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\DEV-WEEU-SAP01-X00
   New-SAPSystem -Parameterfile .\DEV-WEEU-SAP01-X00.json -Type sap_system
```

## **Clean up the deployment** ##

For removing the SAP system navigate to the folder(DEV-WEEU-SAP01-X00) containing the DEV-WEEU-SAP01-X00.json parameter file and use the Remove-SAPSystem cmdlet:

```PowerShell
   cd C:\Azure_SAP_Automated_Deployment\WORKSPACES\SYSTEM\DEV-WEEU-SAP01-X00
   Remove-SAPSystem -Parameterfile .\DEV-WEEU-SAP01-X00.json -Type sap_system
```
