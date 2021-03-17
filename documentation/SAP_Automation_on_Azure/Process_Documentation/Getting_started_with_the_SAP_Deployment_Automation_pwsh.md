# Running the automation from a Windows PC

To run the automation from a local Windows PC, following components need to be installed.

## **Pre-Requisites**

1. **Terraform** - Terraform can be downloaded from [Download Terraform - Terraform by HashiCorp](https://www.terraform.io/downloads.html). Once downloaded and extracted, ensure that the Terraform.exe executable is in a directory which is included in the SYSTEM PATH variable.
2. **Git** - Git can be installed from [Git (git-scm.com)](https://git-scm.com/)
3. **Azure CLI** - Azure CLI can be installed from <https://aka.ms/installazurecliwindows>
4. **Azure PowerShell** - Azure PowerShell can be installed from [Install Azure PowerShell with PowerShellGet | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.5.0)
5. **The latest Azure PowerShell modules** - If you already have Azure PowerShell modules, you can update to the latest version from here [Update the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.5.0#update-the-azure-powershell-module)

## **Setting up the samples for execution**

Once the pre-requisites are met, proceed with the next steps.

1. Create a root directory "Azure_SAP_Automated_Deployment"
2. Navigate to the "Azure_SAP_Automated_Deployment" directory
3. Clone the sap-hana repository by running the following command

   ```bash
    git clone https://github.com/Azure/sap-hana.git

    cd sap-hana

    git checkout beta
   ```

4. Copy the sample parameter `folder WORKSPACES` from
   `sap-hana\documentation\SAP_Automation_on_Azure\Process_Documentation` to the `Azure_SAP_Automated_Deployment` folder.

5. Navigate to the `Azure_SAP_Automated_Deployment\WORKSPACES\DEPLOYMENT-ORCHESTRATION` folder.

6. Kindly note, that triggering the deployment will need the Service Principal details (application id, secret and tenant ID)

## **Listing the contents of the deployment**

For a highlevel overview of what will be deployed use the Read-SAPDeploymentTemplate cmdlet to list the resources deployed by the deployment. **Note** The list does not contain all artifacts

```powershell
Read-SAPDeploymentTemplate -Parameterfile .\DEPLOYER\MGMT-WEEU-DEP00-INFRASTRUCTURE\MGMT-WEEU-DEP00-INFRASTRUCTURE.json -Type sap_deployer

Read-SAPDeploymentTemplate -Parameterfile .\LIBRARY\MGMT-WEEU-SAP_LIBRARY\MGMT-WEEU-SAP_LIBRARY.json -Type sap_library

Read-SAPDeploymentTemplate -Parameterfile .\LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE\DEV-WEEU-SAP01-INFRASTRUCTURE.json -Type sap_landscape

Read-SAPDeploymentTemplate -Parameterfile .\SYSTEM\DEV-WEEU-SAP01-ZZZ\DEV-WEEU-SAP01-ZZZ.json -Type sap_system

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

## **Preparing the region**

This step will deploy the deployment infrastructure and the shared library to the region specified in the parameter files.

Import the Powershell module by running the

```PowerShell
Import-Module  C:\Azure_SAP_Automated_Deployment\sap-hana\deploy\scripts\pwsh\SAPDeploymentUtilities\Output\SAPDeploymentUtilities\SAPDeploymentUtilities.psd1
```

For preparing the region (Deployer, Library) use the New-SAPAutomationRegion cmdlet

```PowerShell
New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\DEV-WEEU-DEP00-INFRASTRUCTURE\DEV-WEEU-DEP00-INFRASTRUCTURE.json  -LibraryParameterfile .\LIBRARY\DEV-WEEU-SAP_LIBRARY\DEV-WEEU-SAP_LIBRARY.json
```

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details.

When prompted for the environment details enter "DEV" and then enter the Service Principal details.

The script will them deploy the rest of the resources required.

## **Preparing the "DEV" environment**

For deploying the SAP system navigate to the folder(LANDSCAPE/DEV-WEEU-SAP01-INFRASTRUCTURE) containing the DEV-WEEU-SAP01-INFRASTRUCTURE.json parameter file and use the New-SAPWorkloadZone cmdlet

```PowerShell
New-SAPWorkloadZone -Parameterfile .\DEV-WEEU-SAP01-INFRASTRUCTURE.json
```

## **Deploying the SAP system**

For deploying the SAP system navigate to the folder(DEV-WEEU-SAP01-ZZZ) containing the DEV-WEEU-SAP01-ZZZ.json parameter file and use the New-SAPSystem cmdlet

```PowerShell
New-SAPSystem -Parameterfile .\DEV-WEEU-SAP01-ZZZ.json -Type sap\_system
```

## **Clean up the deployment**

The script below removes the two deployments and their supporting terraform files.

```PowerShell
Remove-Module SAPDeploymentUtilities -ErrorAction SilentlyContinue

function Remove-TfDeploymentItems {
    param (
        $rgName,
        $dirname
    )

    Write-Host "Cleaning up " $rgName " and " $dirname
    $rg = Get-AzResourceGroup -n $rgname -ErrorAction SilentlyContinue
    if ($null -ne $rg) {
        Remove-AzResourceGroup -Name $rgname -Force
        Write-Host $rgName " removed"
    }

    if (Test-Path $dirname".terraform" -PathType Container) {
        remove-item $dirname".terraform" -Recurse

        Write-Host  $dirname".terraform" " removed"
    }
    else {
        Write-Host  $dirname".terraform" " not found"
    }
    if (Test-Path $dirname"terraform.tfstate" -PathType Leaf) {
        remove-item $dirname"terraform.tfstate" -Recurse
    }
    if (Test-Path $dirname"backend.tf" -PathType Leaf) {
        remove-item $dirname"backend.tf" -Recurse
    }
    if (Test-Path $dirname"terraform.tfstate.backup" -PathType Leaf) {
        remove-item $dirname"terraform.tfstate.backup" -Recurse
    }

    Write-Host "Leaving Remove-Items"
    return

}

$rgname = "DEV-WEEU-SAP00-ZZZ"
$dirname = "SYSTEM\DEV-WEEU-SAP00-ZZZ\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname

$rgname = "DEV-WEEU-SAP01-INFRASTRUCTURE"
$dirname = "LANDSCAPE\DEV-WEEU-SAP01-INFRASTRUCTURE\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname

$rgname = "WEEU-DEP00-INFRASTRUCTURE"
$dirname = "DEPLOYER\DEV-WEEU-DEP00-INFRASTRUCTURE\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname

$rgname = "WEEU-SAP_LIBRARY"
$dirname = "LIBRARY\DEV-WEEU-SAP_LIBRARY\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname


Get-Module -Name SAPDeploymentUtilities #should not return any result
```
