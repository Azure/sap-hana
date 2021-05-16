function Remove-SAPSystem {
    <#
    .SYNOPSIS
        Removes a deployment

    .DESCRIPTION
        Removes a deployment

    .PARAMETER Parameterfile
        This is the parameter file for the system

    .PARAMETER Type
        This is the type of the system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Remove-System -Parameterfile .\PROD-WEEU-SAP00-X00.json -Type sap_system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Remove-System -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -Type sap_library

    
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
        [Parameter(Mandatory = $true)][string]$Parameterfile ,
        [Parameter(Mandatory = $true)][string]$Type
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Remove the" $Type

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $ParamFullFile = (Get-ItemProperty -Path $Parameterfile -Name Fullname).Fullname


    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath
    $curDir = (Get-Location)
 
    $extra_vars = " "
    if (  (Test-Path -Path "terraform.tfvars")) {
        $extra_vars = " -var-file=" + (Join-Path -Path $curDir -ChildPath "terraform.tfvars")
    }

 
    Add-Content -Path "deployment.log" -Value ("Removing the: " + $Type)
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")

    if ($null -eq $iniContent[$combined]) {
        Write-Error "The Terraform state information is not available"

        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName

        $tfstate_resource_id = $rID.ResourceId
        $sub = $tfstate_resource_id.Split("/")[2]

        $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $saName; "tfstate_resource_id" = $tfstate_resource_id; STATE_SUBSCRIPTION = $sub }
        $iniContent += @{$combined = $Category1 }
        $changed = $true
    }
    else {
        $deployer_tfstate_key = $iniContent[$combined]["Deployer"]
        $landscape_tfstate_key = $iniContent[$combined]["Landscape"]
    
        $tfstate_resource_id = $iniContent[$combined]["tfstate_resource_id"] 
        $rgName = $iniContent[$combined]["REMOTE_STATE_RG"] 
        $saName = $iniContent[$combined]["REMOTE_STATE_SA"] 
        $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"] 

            
    }

    $ctx= Get-AzContext
    if($null -eq $ctx) {
        Connect-AzAccount  
    }
    
     # Subscription
     $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"]

     if ($null -ne $sub -and "" -ne $sub) {
        Select-AzSubscription -SubscriptionId $sub
     }
     else {
        $sub = $env:ARM_SUBSCRIPTION_ID
     }

     if ($null -eq $saName -or "" -eq $saName) {
        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName.Trim()  -ResourceType Microsoft.Storage/storageAccounts
        Write-Host $rID
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId
        $sub = $tfstate_resource_id.Split("/")[2]

        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub.Trim() 
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        $changed = $true
        if ($changed) {
            Out-IniFile -InputObject $iniContent -Path $filePath
        }
        $changed = $false

    }
    else {
        $rgName = $iniContent[$combined]["REMOTE_STATE_RG"]
        $tfstate_resource_id = $iniContent[$combined]["tfstate_resource_id"]
    }

    if ($null -eq $tfstate_resource_id -or "" -eq $tfstate_resource_id) {
        
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId
        $sub = $tfstate_resource_id.Split("/")[2]

        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub.Trim() 
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        $changed = $true
        if ($changed) {
            Out-IniFile -InputObject $iniContent -Path $filePath
        }
        $changed = $false

    }


    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the subscription"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    $sub = $tfstate_resource_id.Split("/")[2]
    
    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\run\$Type"
    $Env:TF_DATA_DIR = (Join-Path -Path $curDir -ChildPath ".terraform")

    if ($Type -ne "sap_deployer") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
    }

    if ($Type -eq "sap_landscape") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        if ($deployer_tfstate_key.Length -gt 0) {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
        }
        else {
            $deployer_tfstate_key_parameter = " "
        }
    }

    if ($Type -eq "sap_library") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
    }

    if ($Type -eq "sap_system") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        if ($deployer_tfstate_key.Length -gt 0) {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
        }
        else {
            $deployer_tfstate_key_parameter = " "
        }
        $landscape_tfstate_key_parameter = " -var landscape_tfstate_key=" + $landscape_tfstate_key
    }

    Write-Host -ForegroundColor green "Running refresh"
    $Command = " init -upgrade=true -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$key"""
    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    Write-Host -ForegroundColor green "Running refresh"
    $Command = " refresh -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + $extra_vars

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }


    Write-Host -ForegroundColor green "Running destroy"
    $Command = " destroy -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + $extra_vars

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    if ($Type -eq "sap_library") {
        $iniContent[$combined]["REMOTE_STATE_RG"] = "[DELETED]"
        $iniContent[$combined]["REMOTE_STATE_SA"] = "[DELETED]"
        $iniContent[$combined]["tfstate_resource_id"] = "[DELETED]"
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = "[DELETED]"
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    if ($Type -eq "sap_landscape") {
        $iniContent[$combined]["Landscape"] = "[DELETED]"
        Out-IniFile -InputObject $iniContent -Path $filePath
    }
    if ($Type -eq "sap_deployer") {
        $iniContent[$combined]["Deployer"] = "[DELETED]"
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = "[DELETED]"
    }
    $Env:TF_DATA_DIR = $null
}