
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
    ```

4. Copy the sample parameter folder from
```sap-hana\documentation\SAP_Automation_on_Azure\Process_Documentation\WORKSPACES``` to the ```Azure_SAP_Automated_Deployment``` folder.

5. Navigate to the ```Azure_SAP_Automated_Deployment\WORKSPACES\DEPLOYMENT-ORCHESTRATION``` folder.

6. Kindly note, that triggering the deployment will need the Service Principal details (application id, secret and tenant ID)


## **Deploying the environment**

Import the Powershell module by running the

```PowerShell
Import-Module  C:\Azure_SAP_Automated_Deployment\sap-hana\deploy\scripts\pwsh\SAPDeploymentUtilities\Output\SAPDeploymentUtilities\SAPDeploymentUtilities.psd1
```

For deploying the supporting infrastructure (Deployer, Library and Workload zone) use the New-Environment cmdlet

```PowerShell
New-Environment -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json  -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json -EnvironmentParameterfile .\LANDSCAPE\PROD-WEEU-SAP00-INFRASTRUCTURE\PROD-WEEU-SAP00-INFRASTRUCTURE.json
```

The script will deploy the deployment infrastructure and create the Azure keyvault for storing the Service Principal details.

When prompted for the environment details enter "PROD" and then enter the Service Principal details. 

The script will them deploy the rest of the resources required.

## **Deploying the SAP system**

For deploying the SAP system navigate to the folder containing the parameter file and use the New-System cmdlet

```PowerShell
New-System -Parameterfile .\PROD-WEEU-SAP00-ZZZ.json -Type sap\_system
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
    if (Test-Path $dirname"backup.tf" -PathType Leaf) {
        remove-item $dirname"backup.tf" -Recurse
    }
    if (Test-Path $dirname"terraform.tfstate.backup" -PathType Leaf) {
        remove-item $dirname"terraform.tfstate.backup" -Recurse
    }
    
    Write-Host "Leaving Remove-Items"
    return
            
}

$rgname = "PROD-WEEU-SAP00-ZZZ"
$dirname = "SYSTEM\PROD-WEEU-SAP00-ZZZ\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname


$rgname = "PROD-WEEU-DEP00-INFRASTRUCTURE"
$dirname = "DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname

$rgname = "PROD-WEEU-SAP00-INFRASTRUCTURE"
$dirname = "LANDSCAPE\PROD-WEEU-SAP00-INFRASTRUCTURE\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname

$rgname = "PROD-WEEU-SAP_LIBRARY"
$dirname = "LIBRARY\PROD-WEEU-SAP_LIBRARY\"

Remove-TfDeploymentItems -rgName $rgname -dirname $dirname


Get-Module -Name SAPDeploymentUtilities #should not return any result
```
