function New-SAPLibrary {
    <#
    .SYNOPSIS
        Bootstrap a new SAP Library

    .DESCRIPTION
        Bootstrap a new SAP Library

    .PARAMETER Parameterfile
        This is the parameter file for the library

    .PARAMETER DeployerFolderRelativePath
        This is the relative folder path to the folder containing the deployerparameter terraform.tfstate file


    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPLibrary -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -DeployerFolderRelativePath ..\..\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\

    
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
    [cmdletbinding(SupportsShouldProcess)]
    param(
        #Parameter file
        [Parameter(Mandatory = $true)][string]$Parameterfile,
        #Deployer parameterfile
        [Parameter(Mandatory = $false)][string]$DeployerFolderRelativePath,
        [Parameter(Mandatory = $false)][Switch]$Silent
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the library"
    $curDir = Get-Location 

    $autoApprove=""
    
    if($Silent) {
        $autoApprove=" --auto-approve "
    }

    Write-Host "Using the Deployer state file:"  $DeployerFolderRelativePath

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath

    $ParamFullFile = (Get-ItemProperty -Path $Parameterfile -Name Fullname).Fullname

    Add-Content -Path "deployment.log" -Value "Bootstrap the library"
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")
    
    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath


    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json
    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    # Subscription & repo path

    $sub = $env:ARM_SUBSCRIPTION_ID
    if ($null -ne $iniContent[$combined]) {
        $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"]
    }

    $ctx = Get-AzContext
    if ($null -eq $ctx) {
        Connect-AzAccount 
    }

    $repo = $iniContent["Common"]["repo"]

    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$combined]["subscription"] = $sub
        $changed = $true
    }

    Select-AzSubscription -SubscriptionId $sub
    $Cmd = "az account set --sub $sub"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    & ([ScriptBlock]::Create($Cmd)) 

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repository"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    Write-Host $terraform_module_directory
    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_library"

    $Env:TF_DATA_DIR = (Join-Path -Path $curDir -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Initializing Terraform"

    $statefile=(Join-Path -Path $curDir -ChildPath "terraform.tfstate")
    $Command = " init -upgrade=true -backend-config ""path=$statefile"""
    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

        if ("azurerm" -eq $jsonData.backend.type) {
            Write-Host -ForegroundColor green "State file already migrated to Azure!"
            $ans = Read-Host -Prompt "State is already migrated to Azure. Do you want to re-initialize the library Y/N?"
            if ("Y" -ne $ans) {
                $Env:TF_DATA_DIR = $null
                return
            }
            else {
                $Command = " init -upgrade=trueF -reconfigure -backend-config ""path=$statefile""" 
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($Parameterfile, $DeployerFolderRelativePath)) {
                $ans = Read-Host -Prompt "The system has already been deployed, do you want to redeploy Y/N?"
                if ("Y" -ne $ans) {
                    $Env:TF_DATA_DIR = $null
                    return
                }
            }
        }
    }
    
    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running plan"
    if ($DeployerFolderRelativePath -eq "") {
        $Command = " plan -no-color -var-file " + $ParamFullFile
    }
    else {
        $Command = " plan -no-color -var-file " + $ParamFullFile + " -var deployer_statefile_foldername=" + $DeployerFolderRelativePath
    }
    
    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    $planResults = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    $planResultsPlain = $planResults -replace '\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]', ''

    if ( $planResultsPlain.Contains('Infrastructure is up-to-date')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        $Env:TF_DATA_DIR = $null
        return;
    }

    if ( $planResultsPlain.Contains('Plan: 0 to add, 0 to change, 0 to destroy')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        $Env:TF_DATA_DIR = $null
        return;
    }

    Write-Host $planResults

    if ($PSCmdlet.ShouldProcess($Parameterfile, $DeployerFolderRelativePath)) {
    
        Write-Host -ForegroundColor green "Running apply"
        if ($DeployerFolderRelativePath -eq "") {
            $Command = " apply " +$autoApprove +" -var-file " + $ParamFullFile
        }
        else {
            $Command = " apply " +$autoApprove +" -var-file " + $ParamFullFile + " -var deployer_statefile_foldername=" + $DeployerFolderRelativePath
        }
        
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
        Write-Verbose $Cmd
        
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }

        if ($null -eq $iniContent[$combined] ) {
            $Category1 = @{"subscription" = "" }
            $iniContent += @{$combined = $Category1 }
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
        }
        
        $Command = " output remote_state_resource_group_name"
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        $rgName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName.Replace("""", "")

        $Command = " output remote_state_storage_account_name"
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        $saName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }
        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName.Replace("""", "")

        $Command = " output tfstate_resource_id"
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        $tfstate_resource_id = & ([ScriptBlock]::Create($Cmd)) | Out-String 
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id

        Out-IniFile -InputObject $iniContent -Path $filePath
    }
    $Env:TF_DATA_DIR = $null
}
