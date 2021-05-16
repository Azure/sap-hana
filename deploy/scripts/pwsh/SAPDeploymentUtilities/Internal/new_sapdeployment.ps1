function New-SAPSystem {
    <#
    .SYNOPSIS
        Deploy a new system

    .DESCRIPTION
        Deploy a new system

    .PARAMETER Parameterfile
        This is the parameter file for the system

    .PARAMETER Type

        This is the type of the system, valid values are sap_deployer, sap_library, sap_landscape, sap_system

    .PARAMETER DeployerStateFileKeyName

        This is the optional Deployer state file name

    .PARAMETER LandscapeStateFileKeyName

        This is the optional Landscape state file name

    .PARAMETER StorageAccountName

        This is the optional terraform state file storage account name


    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPSystem -Parameterfile .\DEV-WEEU-SAP00-X00.json -Type sap_system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPSystem -Parameterfile .\DEV-WEEU-SAP00-X00.json -Type sap_system -DeployerStateFileKeyName MGMT-WEEU-DEP00-INFRASTRUCTURE.terraform.tfstate -LandscapeStateFileKeyName DEV-WEEU-SAP01-INFRASTRUCTURE.terraform.tfstate

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPSystem -Parameterfile .\MGMT-WEEU-SAP_LIBRARY.json -Type sap_library

    
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
        [Parameter(Mandatory = $true)][SAP_Types]$Type,
        [Parameter(Mandatory = $false)][string]$DeployerStateFileKeyName,
        [Parameter(Mandatory = $false)][string]$LandscapeStateFileKeyName,
        [Parameter(Mandatory = $false)][string]$StorageAccountName,
        [Parameter(Mandatory = $false)][Switch]$Force,
        [Parameter(Mandatory = $false)][Switch]$Silent
        
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Deploying the" $Type

    if ($true -eq $Force) {
        Remove-Item ".terraform" -ErrorAction SilentlyContinue -Recurse
        Remove-Item "terraform.tfstate" -ErrorAction SilentlyContinue
        Remove-Item "terraform.tfstate.backup" -ErrorAction SilentlyContinue
    }

    $autoApprove = ""
    
    if ($Silent) {
        $autoApprove = " --auto-approve "
    }


    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath

    $curDir = (Get-Location)

    Add-Content -Path "deployment.log" -Value ("Deploying the: " + $Type)
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $fInfo = Get-ItemProperty -Path $Parameterfile

    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        Add-Content -Path "deployment.log" -Value ("File " + $Parameterfile + " does not exist")
        return
    }

    $ParamFullFile = (Get-ItemProperty -Path $Parameterfile -Name Fullname).Fullname

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath
    $changed = $false

    if ($Parameterfile.StartsWith(".\")) {
        if ($Parameterfile.Substring(2).Contains("\")) {
            Write-Error "Please execute the script from the folder containing the json file and not from a parent folder"
            Add-Content -Path "deployment.log" -Value "Please execute the script from the folder containing the json file and not from a parent folder"
            return;
        }
    }

    $extra_vars = " "
    if (  (Test-Path -Path "terraform.tfvars")) {
        $extra_vars = " -var-file=" + (Join-Path -Path $curDir -ChildPath "terraform.tfvars")
    }

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    $landscapeKey = ""
    if ($Type -eq "sap_landscape") {
        $landscapeKey = $key
    }

    $ctx = Get-AzContext
    if ($null -eq $ctx) {
        Connect-AzAccount 
    }

    $sub = $env:ARM_SUBSCRIPTION_ID
    
    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region
    
    $spn_kvSpecified = $jsonData.key_vault.kv_spn_id.Length -gt 0

    $changed = $false

    if ($null -eq $iniContent[$combined]) {
        Select-AzSubscription -SubscriptionId $env:ARM_SUBSCRIPTION_ID
    
        Write-Error "The Terraform state information is not available"

        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName

        $tfstate_resource_id = $rID.ResourceId

        if ($Type -eq "sap_system") {
            if ($null -ne $LandscapeStateFileKeyName) {
                $landscape_tfstate_key = $LandscapeStateFileKeyName
            }
            else {

                $landscape_tfstate_key = Read-Host -Prompt "Please enter the landscape statefile for the deployment"
            }
            if ($Type -eq "sap_landscape") {
                $iniContent[$combined].Landscape = $landscapeKey
            }
            $changed = $true
        }
        else {
            $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $saName; "tfstate_resource_id" = $tfstate_resource_id }
            $iniContent += @{$combined = $Category1 }
            if ($Type -eq "sap_landscape") {
                $iniContent[$combined].Landscape = $landscapeKey
            }
            $changed = $true
                
        }
    }
    else {
        $tfstate_resource_id = $iniContent[$combined]["tfstate_resource_id"]
        $saName = $iniContent[$combined]["REMOTE_STATE_SA"] 
        $rgName = $iniContent[$combined]["REMOTE_STATE_RG"] 
        $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"]
        
        if ($Type -eq "sap_system") {
            if ($null -ne $LandscapeStateFileKeyName -and "" -ne $LandscapeStateFileKeyName) {
                $landscape_tfstate_key = $LandscapeStateFileKeyName
                $iniContent[$combined].Landscape = $LandscapeStateFileKeyName
                $changed = $true
            }
            else {
                $landscape_tfstate_key = $iniContent[$combined].Landscape
            }
        }
    }

    if ($null -ne $sub -and "" -ne $sub) {
        if ( $sub -ne $env:ARM_SUBSCRIPTION_ID) {
            Select-AzSubscription -SubscriptionId $sub
        }
        
    }
    else {
        $sub = $env:ARM_SUBSCRIPTION_ID
    }

    if ("sap_deployer" -eq $Type) {
        $iniContent[$combined]["Deployer"] = $key.Trim()
        $deployer_tfstate_key = $key
        $changed = $true
    }
    else {
        if ($null -ne $DeployerStateFileKeyName -and "" -ne $DeployerStateFileKeyName) {
            $deployer_tfstate_key = $DeployerStateFileKeyName
            $iniContent[$combined]["Deployer"] = $deployer_tfstate_key.Trim()
            $changed = $true
        }
        else {
            $deployer_tfstate_key = $iniContent[$combined]["Deployer"]
        }
    }

    if ($null -ne $StorageAccountName -and "" -ne $StorageAccountName) {
        $saName = $StorageAccountName
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId

        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        $changed = $true

    }
    else {
        $saName = $iniContent[$combined]["REMOTE_STATE_SA"].trim()
        $rgName = $iniContent[$combined]["REMOTE_STATE_RG"]
        $tfstate_resource_id = $iniContent[$combined]["tfstate_resource_id"]
    }
    
    if ($null -eq $saName -or "" -eq $saName) {
        Select-AzSubscription -SubscriptionId $env:ARM_SUBSCRIPTION_ID
    
        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId
        if ($null -ne $tfstate_resource_id) {
            $sub = $tfstate_resource_id.Split("/")[2]
        }

        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub
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
        if ($null -ne $tfstate_resource_id) {
            $sub = $tfstate_resource_id.Split("/")[2]
        }

        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub
        $changed = $true

        if ($changed) {
            Out-IniFile -InputObject $iniContent -Path $filePath
        }
        $changed = $false

    }
    else {
        if ($null -ne $tfstate_resource_id) {
            $sub = $tfstate_resource_id.Split("/")[2]
        }
    }

    
    $repo = $iniContent["Common"]["repo"]

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
        $sub = $tfstate_resource_id.Split("/")[2]
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub.Trim() 
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
    $Env:TF_DATA_DIR = (Join-Path -Path $curDir -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Initializing Terraform"

    if ($tfstate_resource_id.Length -gt 0) {
        $sub = $tfstate_resource_id.Split("/")[2]
    }
    
    $Command = " init -upgrade=true -force-copy -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$key"""

    $bRunRefresh = $false

    $deployment_parameter = " "
    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json
        if ("azurerm" -eq $jsonData.backend.type) {
            $Command = " init -upgrade=true -force-copy -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$key"""

            if ($false -eq $Silent) {

                $ans = Read-Host -Prompt "The system has already been deployed and the statefile is in Azure, do you want to redeploy Y/N?"
                if ("Y" -ne $ans) {
                    $Env:TF_DATA_DIR = $null

                    return
                }

                $bRunRefresh = $true
            }
        }
    } 
    else {
        $deployment_parameter = " -var deployment=new "

    }

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

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
            if ($deployer_tfstate_key.Length -gt 0) {
                $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key    
            }
            else {
                $deployer_tfstate_key_parameter = ""
            }
            
        }
    }

    if ($Type -eq "sap_system") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
        
        if ($deployer_tfstate_key.Length -gt 0) {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key    
        }
        else {
            $deployer_tfstate_key_parameter = ""
        }
        $landscape_tfstate_key_parameter = " -var landscape_tfstate_key=" + $landscape_tfstate_key
    }

    if ($bRunRefresh) {
        Write-Host -ForegroundColor green "Running refresh, please wait"
        $Command = " refresh -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + $extra_vars + $version_parameter + $deployment_parameter 
        
    
        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        Write-Verbose $Cmd
        Add-Content -Path "deployment.log" -Value $Cmd
        
        $planResultsPlain = & ([ScriptBlock]::Create($Cmd)) | Out-String 
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command: $Cmd"
        }
    
    }

    $Command = " output -no-color automation_version"

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"

    Write-Verbose $Cmd

    $versionLabel = & ([ScriptBlock]::Create($Cmd)) | Out-String 


    $version_parameter = " "
    
    if ($versionLabel.Contains("Warning: No outputs found")) {
        $deployment_parameter = " -var deployment=new "
    }
    else {

        Write-Host $versionLabel
    
        if ($versionLabel.Length -eq 0 ) {
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
                    $Env:TF_DATA_DIR = $null
                    return 
                }        
            }
        }
        else {
            $version_parameter = " -var terraform_template_version=" + $versionLabel
            Write-Host ""
            Write-Host -ForegroundColor green "The environment was deployed using the $versionLabel version of the Terrafrom templates"
            Write-Host ""
            Write-Host ""
        }
    }

    Write-Host -ForegroundColor green "Running plan, please wait"
    if ($deployer_tfstate_key_parameter.Length -gt 0) {
        $Command = " plan  -no-color -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + $extra_vars + $version_parameter + $deployment_parameter
    }
    else {
        $Command = " plan  -no-color -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $extra_vars + $version_parameter + $deployment_parameter
    }

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    $planResultsPlain = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    if ( $planResultsPlain.Contains('No changes')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        $Env:TF_DATA_DIR = $null
        return;
    }

    if ( $planResultsPlain.Contains('0 to add, 0 to change, 0 to destroy')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        $Env:TF_DATA_DIR = $null
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
                $Env:TF_DATA_DIR = $null
                return 
            }
        }

    }

    if ($PSCmdlet.ShouldProcess($Parameterfile , $Type)) {

        Write-Host -ForegroundColor green "Running apply"
        
        $Command = " apply " + $autoApprove + " -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + $extra_vars + $version_parameter + $deployment_parameter

        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
        Write-Verbose $Cmd
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command: $Cmd"
        }

        if ($Type -eq "sap_library") {

            $Command = " output remote_state_resource_group_name"
            $Cmd = "terraform -chdir=$terraform_module_directory $Command"
            $rgName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName.Replace("""", "")
    
            $Command = " output remote_state_storage_account_name"
            $Cmd = "terraform -chdir=$terraform_module_directory $Command"
            $saName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$combined]["REMOTE_STATE_SA"] = $saName.Replace("""", "")
    
            $Command = " output tfstate_resource_id"
            $Cmd = "terraform -chdir=$terraform_module_directory $Command"
            $tfstate_resource_id = & ([ScriptBlock]::Create($Cmd)) | Out-String 
            if ($LASTEXITCODE -ne 0) {
                throw "Error executing command: $Cmd"
            }
            $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
    
            Out-IniFile -InputObject $iniContent -Path $filePath
        }
    
    }
    $Env:TF_DATA_DIR = $null
}