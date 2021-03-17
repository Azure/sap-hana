function New-SAPAutomationRegion {
    <#
    .SYNOPSIS
        Deploys a new SAP Environment (Deployer, Library and Workload VNet)

    .DESCRIPTION
        Deploys a new SAP Environment (Deployer, Library and Workload VNet)

    .PARAMETER DeployerParameterfile
        This is the parameter file for the Deployer

    .PARAMETER LibraryParameterfile
        This is the parameter file for the library

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
     New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json \
     -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json \

    
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
        [Parameter(Mandatory = $true)][string]$LibraryParameterfile
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Preparing the azure region for the SAP automation"

    $curDir = Get-Location 
    [IO.DirectoryInfo] $dirInfo = $curDir.ToString()

    $fileDir = $dirInfo.ToString() + $DeployerParameterfile
    [IO.FileInfo] $fInfo = $fileDir

    $DeployerRelativePath = "..\..\" + $fInfo.Directory.FullName.Replace($dirInfo.ToString() + "\", "")

    $jsonData = Get-Content -Path $DeployerParameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"

    if ( -not (Test-Path -Path $FilePath)) {
        New-Item -Path $mydocuments -Name "sap_deployment_automation.ini" -ItemType "file" -Value "[Common]`nrepo=`nsubscription=`n[$region]`nDeployer=`nLandscape=`n[$Environment]`nDeployer=`n[$combined]`nDeployer=`nSubscription=" -Force
    }

    $iniContent = Get-IniContent -Path $filePath

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    
    try {
        if ($null -ne $iniContent[$region] ) {
            $iniContent[$region]["Deployer"] = $key
        }
        else {
            $Category1 = @{"Deployer" = $key }
            $iniContent += @{$region = $Category1 }
            Out-IniFile -InputObject $iniContent -Path $filePath                    
        }
                
    }
    catch {
        
    }

    $errors_occurred = $false
    Set-Location -Path $fInfo.Directory.FullName
    try {
        New-SAPDeployer -Parameterfile $fInfo.Name 
    }
    catch {
        $errors_occurred = true
    }
    Set-Location -Path $curDir
    if ($errors_occurred) {
        return
    }

    # Re-read ini file
    $iniContent = Get-IniContent -Path $filePath

    $ans = Read-Host -Prompt "Do you want to enter the SPN secrets Y/N?"
    if ("Y" -eq $ans) {
        $vault = ""
        if ($null -ne $iniContent[$region] ) {
            $vault = $iniContent[$region]["Vault"]
        }

        if (($null -eq $vault ) -or ("" -eq $vault)) {
            $vault = Read-Host -Prompt "Please enter the vault name"
            $iniContent[$region]["Vault"] = $vault 
            Out-IniFile -InputObject $iniContent -Path $filePath
    
        }
        try {
            Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vault  -Workload $false
        }
        catch {
            $errors_occurred = true
            return
        }
    
        
    }

    $fileDir = $dirInfo.ToString() + $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    try {
        New-SAPLibrary -Parameterfile $fInfo.Name -DeployerFolderRelativePath $DeployerRelativePath
    }
    catch {
        $errors_occurred = true
    }

    Set-Location -Path $curDir
    if ($errors_occurred) {
        return
    }

    $fileDir = $dirInfo.ToString() + $DeployerParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    try {
        New-SAPSystem -Parameterfile $fInfo.Name -Type [SAP_Types]::sap_deployer
    }
    catch {
        $errors_occurred = true
    }

    Set-Location -Path $curDir
    if ($errors_occurred) {
        return
    }

    $fileDir = $dirInfo.ToString() + $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    Set-Location -Path $fInfo.Directory.FullName
    try {
        New-SAPSystem -Parameterfile $fInfo.Name -Type [SAP_Types]::sap_library
    }
    catch {
        $errors_occurred = true
    }

    Set-Location -Path $curDir
    if ($errors_occurred) {
        return
    }

}