function New-Environment {
    <#
    .SYNOPSIS
        Deploys a new SAP Environment (Deployer, Library and Workload VNet)

    .DESCRIPTION
        Deploys a new SAP Environment (Deployer, Library and Workload VNet)

    .PARAMETER DeployerParameterfile
        This is the parameter file for the Deployer

    .PARAMETER LibraryParameterfile
        This is the parameter file for the library

    .PARAMETER -EnvironmentParameterfile
        This is the parameter file for the Workload VNet


    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
     New-Environment -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json \
     -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json \
     -EnvironmentParameterfile .\LANDSCAPE\PROD-WEEU-SAP00-INFRASTRUCTURE\PROD-WEEU-SAP00-INFRASTRUCTURE.json

    
.LINK
    https://github.com/Azure/sap-hana

.NOTES
    v0.1 - Initial version

.

    #>
    <#
Copyright (c) Microsoft Corporation.
Licensed under the MIT license.
#>
    [cmdletbinding()]
    param(
        #Parameter file
        [Parameter(Mandatory = $true)][string]$DeployerParameterfile,
        [Parameter(Mandatory = $true)][string]$LibraryParameterfile,
        [Parameter(Mandatory = $true)][string]$EnvironmentParameterfile
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Deploying the Full Environment"

    $curDir = Get-Location 
    [IO.DirectoryInfo] $dirInfo = $curDir.ToString()

    $fileDir = $dirInfo.ToString() + $EnvironmentParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    $envkey = $fInfo.Name.replace(".json", ".terraform.tfstate")

    $fileDir = $dirInfo.ToString() + $DeployerParameterfile
    [IO.FileInfo] $fInfo = $fileDir

    $DeployerRelativePath = "..\..\" + $fInfo.Directory.FullName.Replace($dirInfo.ToString() + "\", "")

    $Environment = ($fInfo.Name -split "-")[0]
    $region = ($fInfo.Name -split "-")[1]
    $combined = $Environment + $region

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"

    if ( -not (Test-Path -Path $FilePath)) {
        New-Item -Path $mydocuments -Name "sap_deployment_automation.ini" -ItemType "file" -Value "[Common]`nrepo=`nsubscription=`n[$combined]`nDeployer=`nLandscape=`n[$Environment]`nDeployer=" -Force
    }

    $iniContent = Get-IniContent $filePath

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    
    $iniContent[$combined]["Landscape"] = $envkey
    $iniContent[$combined]["Deployer"] = $key

    Out-IniFile -InputObject $iniContent -FilePath $filePath

    Set-Location -Path $fInfo.Directory.FullName
    New-Deployer -Parameterfile $fInfo.Name 
    Set-Location -Path $curDir

    # Re-read ini file
    $iniContent = Get-IniContent $filePath

    $ans = Read-Host -Prompt "Do you want to enter the Keyvault secrets Y/N?"
    if ("Y" -eq $ans) {
        $vault = $iniContent[$Environment]["Vault"]
        Set-Secrets -Environment $Environment -VaultName $vault
        
    }

    $fileDir = $dirInfo.ToString() + $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    New-Library -Parameterfile $fInfo.Name -DeployerFolderRelativePath $DeployerRelativePath
    Set-Location -Path $curDir

    $fileDir = $dirInfo.ToString() + $DeployerParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    New-System -Parameterfile $fInfo.Name -Type "sap_deployer"
    Set-Location -Path $curDir

    $fileDir = $dirInfo.ToString() + $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    New-System -Parameterfile $fInfo.Name -Type "sap_library"
    Set-Location -Path $curDir

    $fileDir = $dirInfo.ToString() + $EnvironmentParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    New-System -Parameterfile $fInfo.Name -Type "sap_landscape"
    Set-Location -Path $curDir


}