
function New-SAPDeployer {
    <#
    .SYNOPSIS
        Bootstrap a new deployer

    .DESCRIPTION
        Bootstrap a new deployer

    .PARAMETER Parameterfile
        This is the parameter file for the deployer

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPDeployer -Parameterfile .\PROD-WEEU-MGMT00-INFRASTRUCTURE.json

    
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
        [Parameter(Mandatory = $false)][Switch]$Silent

    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the deployer"

    $curDir = Get-Location 

    $autoApprove=""
    
    if($Silent) {
        $autoApprove=" --auto-approve "
    }

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

    Add-Content -Path "deployment.log" -Value "Bootstrap the deployer"
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $fileINIPath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json
    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region

    Write-Host "Region:"$region
    Write-Host "Environment:"$Environment

    $combined = $Environment + $region

    if ($null -ne $iniContent[$combined] ) {
        $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"] 
    }
    else {
        $Category1 = @{"subscription" = "" }
        $iniContent += @{$combined = $Category1 }
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }
    
    # Subscription & repo path

    $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"] 
    $repo = $iniContent["Common"]["repo"]

    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        if ($null -ne $env:ARM_SUBSCRIPTION_ID) {
            $sub = $env:ARM_SUBSCRIPTION_ID
        }
        else {
            $sub = Read-Host -Prompt "Please enter the subscription"    
        }
        
        $iniContent[$combined]["subscription"] = $sub
        $changed = $true
    }

    $Cmd = "az account set --sub $sub"
    Add-Content -Path "deployment.log" -Value $Cmd

    & ([ScriptBlock]::Create($Cmd)) 

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repository"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_deployer"
    if (-not (Test-Path $terraform_module_directory) ) {
        Write-Host -ForegroundColor Red "The repository path: $repo is incorrect!"
        $iniContent["Common"]["repo"] = ""
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
        throw "The repository path: $repo is incorrect!"
        return

    }

    $Env:TF_DATA_DIR = (Join-Path -Path $curDir -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Initializing Terraform"

    $statefile = (Join-Path -Path $curDir -ChildPath "terraform.tfstate")
    $Command = " init -upgrade=true  -backend-config ""path=$statefile"""
    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

        if ("azurerm" -eq $jsonData.backend.type) {
            Write-Host -ForegroundColor green "State file already migrated to Azure!"
            $ans = Read-Host -Prompt "State is already migrated to Azure. Do you want to re-initialize the deployer Y/N?"
            if ("Y" -ne $ans) {
                $Env:TF_DATA_DIR = $null
                return
            }
            else {
                $Command = " init -upgrade=true -reconfigure "
            }
        }
        else {
            $ans = Read-Host -Prompt "The system has already been deployed, do you want to redeploy Y/N?"
            if ("Y" -ne $ans) {
                $Env:TF_DATA_DIR = $null
                return
            }
        }
    }

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running plan"
    $Command = " plan -var-file " + $ParamFullFile 
    
    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
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
    
    if ($PSCmdlet.ShouldProcess($Parameterfile)) {
        Write-Host -ForegroundColor green "Running apply"

        $Command = " apply " +$autoApprove +" -var-file " + $ParamFullFile 
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
        & ([ScriptBlock]::Create($Cmd)) 
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }

        $Command = " output deployer_kv_user_name"

        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        $kvName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
        Write-Host ("SPN Keyvault: " + $kvName)

        $iniContent[$combined]["Vault"] = $kvName.Replace("""", "")
        Out-IniFile -InputObject $iniContent -Path $fileINIPath

        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }
    }

    $Env:TF_DATA_DIR = $null
}
