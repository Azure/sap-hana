function New-SAPSystem {
    <#
    .SYNOPSIS
        Deploy a new system

    .DESCRIPTION
        Deploy a new system

    .PARAMETER Parameterfile
        This is the parameter file for the system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPSystem -Parameterfile .\PROD-WEEU-SAP00-ZZZ.json -Type sap_system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPSystem -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -Type sap_library

    
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
        [Parameter(Mandatory = $true)][string]$Parameterfile ,
        [Parameter(Mandatory = $true)][SAP_Types]$Type
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Deploying the" $Type

    $fInfo = Get-ItemProperty -Path $Parameterfile

    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    Add-Content -Path "deployment.log" -Value ("Deploying the: " + $Type)
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")
    
    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath
    $changed = $false

    if ($Parameterfile.StartsWith(".\")) {
        if ($Parameterfile.Substring(2).Contains("\")) {
            Write-Error "Please execute the script from the folder containing the json file and not from a parent folder"
            return;
        }
    }

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    $landscapeKey = ""
    if ($Type -eq "sap_landscape") {
        $landscapeKey = $key
    }
  
    
    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    if ($null -eq $iniContent[$region]) {
        Write-Error "The region data is not available"

        $rgName = Read-Host -Prompt "Please specify the resource group name for the terraform storage account"
        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"

        $tfstate_resource_id = Read-Host -Prompt "Please specify the storage account resource ID for the terraform storage account"
        
        $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $saName; "tfstate_resource_id" = $tfstate_resource_id }
        $iniContent += @{$region = $Category1 }
        Out-IniFile -InputObject $iniContent -Path $filePath

    }

    if ($null -eq $iniContent[$combined]) {
        $Category1 = @{"Landscape" = $landscapeKey; "Subscription" = "" }
        $iniContent += @{$combined = $Category1 }
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    
    if ("sap_deployer" -eq $Type) {
        $iniContent[$region]["Deployer"] = $key.Trim()
        Out-IniFile -InputObject $iniContent -Path $filePath
        $iniContent = Get-IniContent -Path $filePath
    }
    else {
        $deployer_tfstate_key = $iniContent[$region]["Deployer"].Trim()    
    }

    if ($Type -eq "sap_system") {
        if ($null -ne $iniContent[$combined] ) {
            $landscape_tfstate_key = $iniContent[$combined]["Landscape"].Trim()
        }
        else {
            Write-Host -ForegroundColor Red "The workload zone for " $environment "in " $region " is not deployed"
        }
    }

    $rgName = $iniContent[$region]["REMOTE_STATE_RG"].Trim() 
    $saName = $iniContent[$region]["REMOTE_STATE_SA"].Trim()  
    $tfstate_resource_id = $iniContent[$region]["tfstate_resource_id"].Trim() 

    # Subscription
    if ($Type -eq "sap_system" -or $Type -eq "sap_landscape") {
        $sub = $iniContent[$environment]["subscription"].Trim()  
    }
    else {
        $sub = $iniContent[$region]["subscription"].Trim()  
    }
    
    $repo = $iniContent["Common"]["repo"].Trim() 
    if ($Type -eq "sap_system") {
        if ($null -eq $landscape_tfstate_key -or "" -eq $landscape_tfstate_key) {
            $landscape_tfstate_key = Read-Host -Prompt "Please enter the landscape statefile for the deployment"
            if ($Type -eq "sap_system") {
                $iniContent[$combined]["Landscape"] = $landscape_tfstate_key.Trim()
            }
    
            $changed = $true
        }
    }

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the deployment"
        if ($Type -eq "sap_system" -or $Type -eq "sap_landscape") {
            $iniContent[$environment]["subscription"] = $sub.Trim() 
        }
        else {
            $iniContent[$region]["subscription"] = $sub.Trim()  
        }
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repo"
        $iniContent["Common"]["repo"] = $repo.Trim() 
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    
    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\run\$Type"

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true -force-copy -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$key"" " + $terraform_module_directory

    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json
        if ("azurerm" -eq $jsonData.backend.type) {
            $Command = " init -upgrade=true"

            $ans = Read-Host -Prompt "The system has already been deployed and the statefile is in Azure, do you want to redeploy Y/N?"
            if ("Y" -ne $ans) {
                return
            }
        }
    } 

    $Cmd = "terraform $Command"
    Add-Content -Path "deployment.log" -Value $Cmd

    & ([ScriptBlock]::Create($Cmd)) 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    if ($Type -ne "sap_deployer") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
    }
    else {
        # Removing the bootsrap shell script
        if (Test-Path ".\post_deployment.sh" -PathType Leaf) {
            Remove-Item -Path ".\post_deployment.sh"  -Force 
        }
    }

    if ($Type -eq "sap_landscape") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
    }

    if ($Type -eq "sap_library") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        if ($false -eq $jsonData.deployer.use) {
            $deployer_tfstate_key_parameter = ""
        }
        else {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key    
        }
    
            
    }

    if ($Type -eq "sap_system") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
        $landscape_tfstate_key_parameter = " -var landscape_tfstate_key=" + $landscape_tfstate_key
    }

    New-Item -Path . -Name "backend.tf" -ItemType "file" -Value "terraform {`n  backend ""azurerm"" {}`n}" -Force

    $Command = " output automation_version"

    $Cmd = "terraform $Command"
    $versionLabel = & ([ScriptBlock]::Create($Cmd)) | Out-String 

    Write-Host $versionLabel
    if ("" -eq $versionLabel) {
        Write-Host ""
        Write-Host -ForegroundColor red "The environment was deployed using an older version of the Terrafrom templates"
        Write-Host ""
        Write-Host -ForegroundColor red "!!! Risk for Data loss !!!"
        Write-Host ""
        Write-Host -ForegroundColor red "Please inspect the output of Terraform plan carefully before proceeding" 
        Write-Host ""
        if ($PSCmdlet.ShouldProcess($Parameterfile , $Type)) {
            $ans = Read-Host -Prompt "Do you want to continue Y/N?"
            if ("Y" -eq $ans) {
    
            }
            else {
                return 
            }        
        }
    }
    else {
        Write-Host ""
        Write-Host -ForegroundColor green "The environment was deployed using the $versionLabel version of the Terrafrom templates"
        Write-Host ""
        Write-Host ""
    }

    Write-Host -ForegroundColor green "Running plan, please wait"
    $Command = " plan -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
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

    Write-Host $planResults
    if (-not $planResultsPlain.Contains('0 to change, 0 to destroy') ) {
        Write-Host ""
        Write-Host -ForegroundColor red "!!! Risk for Data loss !!!"
        Write-Host ""
        Write-Host -ForegroundColor red "Please inspect the output of Terraform plan carefully before proceeding" 
        Write-Host ""
        if ($PSCmdlet.ShouldProcess($Parameterfile , $Type)) {
            $ans = Read-Host -Prompt "Do you want to continue Y/N?"
            if ("Y" -ne $ans) {
                return 
            }
        }

    }

    if ($PSCmdlet.ShouldProcess($Parameterfile , $Type)) {

        Write-Host -ForegroundColor green "Running apply"
        $Command = " apply -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

        $Cmd = "terraform $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command: $Cmd"
        }

        if ($Type -eq "sap_library") {
            New-Item -Path . -Name "backend.tf" -ItemType "file" -Value "terraform {`n  backend ""azurerm"" {}`n}" -Force 

            $Command = " output remote_state_resource_group_name"
            $Cmd = "terraform $Command"
            $rgName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$region]["REMOTE_STATE_RG"] = $rgName.Replace("""", "")
    
            $Command = " output remote_state_storage_account_name"
            $Cmd = "terraform $Command"
            $saName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$region]["REMOTE_STATE_SA"] = $saName.Replace("""", "")
    
            $Command = " output tfstate_resource_id"
            $Cmd = "terraform $Command"
            $tfstate_resource_id = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$region]["tfstate_resource_id"] = $tfstate_resource_id
    
            Out-IniFile -InputObject $iniContent -Path $filePath
        }
    
    }

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf"  -Force 
    }

}