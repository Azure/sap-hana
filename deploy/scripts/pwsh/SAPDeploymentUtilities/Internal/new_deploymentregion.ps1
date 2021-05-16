function New-SAPAutomationRegion {
    <#
    .SYNOPSIS
        Deploys a new SAP Environment (Deployer, Library)

    .DESCRIPTION
        Deploys a new SAP Environment (Deployer, Library)

    .PARAMETER DeployerParameterfile
        This is the parameter file for the Deployer

    .PARAMETER LibraryParameterfile
        This is the parameter file for the library

    .PARAMETER Subscription
        This is the subscription into which the deployment is performed

    .PARAMETER SPN_id
        This is the Service Principal App ID

    .PARAMETER SPN_password
        This is the Service Principal password

    .PARAMETER Tenant
        This is the Tenant ID of the Service Principal

    .PARAMETER Force
        Performs a cleanup of local configuration before deployment

    .PARAMETER Silent
        Performs a silent deployment

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
     New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json 
     -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json 


    .EXAMPLE 

    #
    # Import the module

    Import-Module "SAPDeploymentUtilities.psd1"

    # Provide the subscription and SPN details as parameters

     New-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json 
     -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json 
     -Subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
     -SPN_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
     -SPN_password ************************
     -Tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz  
     -Silent
                   


    
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
        [Parameter(Mandatory = $false)][string]$Subscription,
        #SPN App ID
        [Parameter(Mandatory = $false)][string]$SPN_id,
        #SPN App secret
        [Parameter(Mandatory = $false)][string]$SPN_password,
        #Tenant
        [Parameter(Mandatory = $false)][string]$Tenant_id,
        [Parameter(Mandatory = $false)][Switch]$Force,
        [Parameter(Mandatory = $false)][Switch]$Silent
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Preparing the azure region for the SAP automation"

    $step = 0

    $curDir = Get-Location 
    [IO.DirectoryInfo] $dirInfo = $curDir.ToString()

    $fileDir = Join-Path -Path $dirInfo.ToString() -ChildPath $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir

    $fInfo = Get-ItemProperty -Path $LibraryParameterfile
    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $LibraryParameterfile + " does not exist")
        return
    }

    $fileDir = Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    
    $fInfo = Get-ItemProperty -Path $DeployerParameterfile
    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $DeployerParameterfile + " does not exist")
        return
    }

    $jsonData = Get-Content -Path $DeployerParameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region

    # Initialize Terraform plugin cache
    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath

    $combined = $Environment + $region

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"

    if ( -not (Test-Path -Path $fileINIPath)) {
        New-Item -Path $mydocuments -Name "sap_deployment_automation.ini" -ItemType "file" -Value "[Common]`nrepo=`nsubscription=`n[$region]`nDeployer=`nLandscape=`n[$Environment]`nDeployer=`n[$combined]`nDeployer=`nSubscription=" -Force
    }

    $iniContent = Get-IniContent -Path $fileINIPath

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    
    if ($null -ne $iniContent[$region] ) {
        $iniContent[$region]["Deployer"] = $key
    }
    else {
        $Category1 = @{"Deployer" = $key }
        $iniContent += @{$region = $Category1 }
        Out-IniFile -InputObject $iniContent -Path $fileINIPath                    
    }

    if ($true -eq $Force) {
        if ($null -ne $iniContent[$combined] ) {
            $iniContent.Remove($combined)
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
            $iniContent = Get-IniContent -Path $fileINIPath
            
        }
    }

    try {
        if ($null -ne $iniContent[$combined] ) {
            $iniContent[$combined]["Deployer"] = $key
        }
        else {
            $Category1 = @{"Deployer" = $key}
            $iniContent += @{$combined = $Category1 }
            Out-IniFile -InputObject $iniContent -Path $fileINIPath                    
            $iniContent = Get-IniContent -Path $fileINIPath
            
        }
                
    }
    catch {
        
    }

    if ($null -ne $Subscription) {
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $Subscription
        Out-IniFile -InputObject $iniContent -Path $fileINIPath

        $Env:ARM_SUBSCRIPTION_ID=$Subscription

    }

    if ($null -ne $iniContent[$combined]["step"]) {
        $step = $iniContent[$combined]["step"]
    }
    else {
        $step = 0
        $iniContent[$combined]["step"] = $step
    }

    $ctx = Get-AzContext
    if ($null -eq $ctx) {
        Connect-AzAccount
    }
 
    $errors_occurred = $false
    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    $DeployerParameterPath = $fInfo.Directory.FullName
    
    if (0 -eq $step) {
    
        Set-Location -Path $DeployerParameterPath
    
        if ($true -eq $Force) {
            Remove-Item ".terraform" -ErrorAction SilentlyContinue -Recurse
            Remove-Item "terraform.tfstate" -ErrorAction SilentlyContinue
            Remove-Item "terraform.tfstate.backup" -ErrorAction SilentlyContinue
        }

        try {
            if ($Silent) {
                New-SAPDeployer -Parameterfile $fInfo.Name -Silent 
            }
            else {
                New-SAPDeployer -Parameterfile $fInfo.Name 
            }
            
            $iniContent = Get-IniContent -Path $fileINIPath
            $step = 1
            $iniContent[$combined]["step"] = $step
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
        }
        catch {
            $errors_occurred = $true
        }
        Set-Location -Path $curDir
    }

    if ($errors_occurred) {
        $Env:TF_DATA_DIR = $null
        return
    }

    # Re-read ini file
    $iniContent = Get-IniContent -Path $fileINIPath
    $vault = $iniContent[$combined]["Vault"] 

    if (1 -eq $step) {
        $bAsk = $true
        if ($null -ne $vault -and "" -ne $vault) {
            if ($null -eq (Get-AzKeyVaultSecret -VaultName $vault -Name ($Environment + "-client-id") )) {
                $bAsk = $true
                if (($null -ne $SPN_id) -and ($null -ne $SPN_password) -and ($null -ne $Tenant_id)) {
                    Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vault -SPN_id $SPN_id -SPN_password $SPN_password -Tenant_id $Tenant_id
                    $iniContent = Get-IniContent -Path $fileINIPath
                    $iniContent = Get-IniContent -Path $fileINIPath
            
                    $step = 2
                    $iniContent[$combined]["step"] = $step
                    Out-IniFile -InputObject $iniContent -Path $fileINIPath
                    $bAsk = $false
                }
            }
        }
        if ($bAsk) {
            $ans = Read-Host -Prompt "Do you want to enter the SPN secrets Y/N?"
            if ("Y" -eq $ans) {
                $vault = ""
                if ($null -ne $iniContent[$combined] ) {
                    $vault = $iniContent[$combined]["Vault"]
                }

                if (($null -eq $vault ) -or ("" -eq $vault)) {
                    $vault = Read-Host -Prompt "Please enter the vault name"
                    $iniContent[$combined]["Vault"] = $vault 
                    Out-IniFile -InputObject $iniContent -Path $fileINIPath
                }
                try {
                    Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vault 
                    $iniContent = Get-IniContent -Path $fileINIPath
            
                    $step = 2
                    $iniContent[$combined]["step"] = $step
                    Out-IniFile -InputObject $iniContent -Path $fileINIPath
    
                }
                catch {
                    $errors_occurred = $true
                }
            }
        }
        else {
            $step = 2
            $iniContent[$combined]["step"] = $step
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
        }
    }

    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $LibraryParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    if (2 -eq $step) {
        $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")
        Write-Host $Env:TF_DATA_DIR

        Set-Location -Path $fInfo.Directory.FullName
        if ($true -eq $Force) {
            Remove-Item ".terraform" -ErrorAction SilentlyContinue -Recurse
            Remove-Item "terraform.tfstate" -ErrorAction SilentlyContinue
            Remove-Item "terraform.tfstate.backup" -ErrorAction SilentlyContinue
        }

        try {
            Write-Host $$DeployerParameterPath
            if ($Silent) {
                New-SAPLibrary -Parameterfile $fInfo.Name -DeployerFolderRelativePath $DeployerParameterPath  -Silent
            }
            else {
                New-SAPLibrary -Parameterfile $fInfo.Name -DeployerFolderRelativePath $DeployerParameterPath  
            }
            $iniContent = Get-IniContent -Path $fileINIPath
            
            $step = 3
            $iniContent[$combined]["step"] = $step
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
        }
        catch {
            $errors_occurred = $true
        }

        Set-Location -Path $curDir
    }
    if ($errors_occurred) {
        $Env:TF_DATA_DIR = $null
        return
    }

    $fileDir = Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile

    [IO.FileInfo] $fInfo = $fileDir
    if (3 -eq $step) {
        Write-Host "3"
        $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

        Set-Location -Path $fInfo.Directory.FullName
        try {
            if ($Silent) {
                New-SAPSystem -Parameterfile $fInfo.Name -Type sap_deployer -Silent
            }
            else {
                New-SAPSystem -Parameterfile $fInfo.Name -Type sap_deployer 
            }
            $iniContent = Get-IniContent -Path $fileINIPath
            
            $step = 4
            $iniContent[$combined]["step"] = $step
            Out-IniFile -InputObject $iniContent -Path $fileINIPath

        }
        catch {
            Write-Error $_
            $errors_occurred = $true
        }

        Set-Location -Path $curDir
    }
    if ($errors_occurred) {
        $Env:TF_DATA_DIR = $null
        return
    }

    $fileDir = Join-Path -Path $dirInfo.ToString() -ChildPath $LibraryParameterfile
    [IO.FileInfo] $fInfo = $fileDir
    if (4 -eq $step) {

        $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

        Set-Location -Path $fInfo.Directory.FullName
        try {
            if ($Silent) {
                New-SAPSystem -Parameterfile $fInfo.Name -Type sap_library -Silent
            }
            else {
                New-SAPSystem -Parameterfile $fInfo.Name -Type sap_library 
            }
            $iniContent = Get-IniContent -Path $fileINIPath
            
            $step = 5
            $iniContent[$combined]["step"] = $step
            Out-IniFile -InputObject $iniContent -Path $fileINIPath

        }
        catch {
            $errors_occurred = $true
        }

        Set-Location -Path $curDir
    }

    # Reset the state to after bootstrap, this allows for re-running if the templates have changed
    $step = 3
    $iniContent[$combined]["step"] = $step
    Out-IniFile -InputObject $iniContent -Path $fileINIPath

    $Env:TF_DATA_DIR = $null
    return

}