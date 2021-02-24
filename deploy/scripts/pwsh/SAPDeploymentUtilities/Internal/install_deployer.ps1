
function New-Deployer {
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
    New-Deployer -Parameterfile .\PROD-WEEU-MGMT00-INFRASTRUCTURE.json

    
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
        [Parameter(Mandatory = $true)][string]$Parameterfile
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the deployer"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath

    [IO.FileInfo] $fInfo = $Parameterfile
    $Environment = ($fInfo.Name -split "-")[0]

    # Subscription
    $sub = $iniContent[$Environment]["subscription"] 
    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$Environment]["subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repository"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
         Out-IniFile -InputObject $iniContent -FilePath $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\bootstrap\sap_deployer"

    if (-not (Test-Path $terraform_module_directory) )
    {
        Write-Host -ForegroundColor Red "The repository path: $repo is incorrect!"
        $iniContent["Common"]["repo"] =""
        Out-IniFile -InputObject $iniContent -FilePath $filePath
        throw "The repository path: $repo is incorrect!"
        return

    }

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true " + $terraform_module_directory
    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

        if ("azurerm" -eq $jsonData.backend.type) {
            Write-Host -ForegroundColor green "State file already migrated to Azure!"
            $ans = Read-Host -Prompt "State is already migrated to Azure. Do you want to re-initialize the deployer Y/N?"
            if ("Y" -ne $ans) {
                return
            }
            else {
                $Command = " init -upgrade=true -reconfigure " + $terraform_module_directory
            }
        }
    }

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running plan"
    $Command = " plan -var-file " + $Parameterfile + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    $planResults = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    $planResultsPlain = $planResults -replace '\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]', ''

    if ( $planResultsPlain.Contains('Infrastructure is up-to-date')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        return;
    }

    if ( $planResultsPlain.Contains('Plan: 0 to add, 0 to change, 0 to destroy')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        return;
    }

    Write-Host $planResults
    
    Write-Host -ForegroundColor green "Running apply"

    $Command = " apply -var-file " + $Parameterfile + " " + $terraform_module_directory
    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    New-Item -Path . -Name "backend.tf" -ItemType "file" -Value "terraform {`n  backend ""local"" {}`n}" -Force

    $Command = " output deployer_kv_user_name"

    $Cmd = "terraform $Command"
    $kvName = & ([ScriptBlock]::Create($Cmd)) | Out-String 

    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    Write-Host $kvName.Replace("""", "")
    $iniContent[$Environment]["Vault"] = $kvName.Replace("""", "")
    Out-IniFile -InputObject $iniContent -FilePath $filePath

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf" -Force 
    }


}


