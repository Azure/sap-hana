function New-SAPWorkloadZone {
    <#
    .SYNOPSIS
        Deploy a new SAP Workload Zone

    .DESCRIPTION
        Deploy a new SAP Workload Zone

    .PARAMETER Parameterfile
        This is the parameter file for the system

    .PARAMETER Force
        This is the parameter that forces the script to delete the local terrafrom state file artifacts

    .PARAMETER Deployerstatefile
        This is the deployer terraform state file name

    .PARAMETER DeployerEnvironment
        This is the deployer environment name

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-SAPWorkloadZone -Parameterfile .\PROD-WEEU-SAP00-infrastructure.json 

    
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
        [Parameter(Mandatory = $true)][string]$Parameterfile, 

        [Parameter(Mandatory = $false)][string]$Deployerstatefile,
        [Parameter(Mandatory = $false)][string]$Deployerenvironment,

        [Parameter(Mandatory = $false)][string]$State_subscription,
        [Parameter(Mandatory = $false)][string]$Vault,
        [Parameter(Mandatory = $false)][string]$StorageAccountName,

        [Parameter(Mandatory = $false)][string]$Subscription,
        [Parameter(Mandatory = $false)][string]$SPN_id,
        [Parameter(Mandatory = $false)][string]$SPN_password,

        [Parameter(Mandatory = $false)][string]$Tenant_id,

        [Parameter(Mandatory = $false)][Switch]$Force,
        [Parameter(Mandatory = $false)][Switch]$Silent  
    )

    if ($true -eq $Force) {
        Remove-Item ".terraform" -ErrorAction SilentlyContinue -Recurse
        Remove-Item "terraform.tfstate" -ErrorAction SilentlyContinue
        Remove-Item "terraform.tfstate.backup" -ErrorAction SilentlyContinue
    }

    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath


    Write-Host -ForegroundColor green ""
    $Type = "sap_landscape"
    Write-Host -ForegroundColor green "Deploying the" $Type
  
    Add-Content -Path "deployment.log" -Value ("Deploying the: " + $Type)
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")
  
    $fInfo = Get-ItemProperty -Path $Parameterfile
    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $DataDir = Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform"
    
    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $fileINIPath

    $Environment = ""
    $region = ""
    $saName = $StorageAccountName
    $repo = ""

    $KeyValuePairs = @{}

    if ($fInfo.Extension -eq ".tfvars") {
        $paramContent = Get-Content -Path $Parameterfile

        foreach ($param in $paramContent) {
            if ($param.Contains("=")) {
                $KeyValuePairs.Add($param.Split("=")[0].ToLower(), $param.Split("=")[1].Replace("""", ""))
            }
           
        }
        $Environment = $KeyValuePairs["environment"]
        $region = $KeyValuePairs["location"]

    }
    else {
        $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

        $Environment = $jsonData.infrastructure.environment
        $region = $jsonData.infrastructure.region
            
    }

    $combined = $Environment + $region

    if ($true -eq $Force) {
        $iniContent.Remove($combined)
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
        $iniContent = Get-IniContent -Path $fileINIPath
   
    }
    
    $changed = $false

    if ($null -eq $iniContent["Common"]) {
        $repo = Read-Host -Prompt "Please enter path to the repo"
        $Category1 = @{"repo" = $repo }
        $iniContent += @{"Common" = $Category1 }
        $changed = $true
    }
    else {
        $repo = $iniContent["Common"]["repo"]
        if ($null -eq $repo -or "" -eq $repo) {
            $repo = Read-Host -Prompt "Please enter path to the repo"
            $iniContent["Common"]["repo"] = $repo
            $changed = $true
        }
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\run\$Type"
    $Env:TF_DATA_DIR = $DataDir
    
    $changed = $false

    $landscape_tfstate_key = $fInfo.Name.replace($fInfo.Extension, ".terraform.tfstate")

    $ctx = Get-AzContext
    if ($null -eq $ctx) {
        Connect-AzAccount 
    }


    Write-Host $State_subscription
    $current_Subscription = (Get-AzContext).Subscription.Id

    if ($State_subscription.Length -gt 0) {
        if ($current_Subscription -ne $State_subscription) {
            Select-AzSubscription -SubscriptionId $State_subscription
        }

    }

    $deployercombined = $Environment + $region
    $vaultName = ""

    if ($null -eq $iniContent[$combined]) {
        if ($StorageAccountName.Length -gt 0) {
            $rID = Get-AzResource -Name $StorageAccountName -ResourceType Microsoft.Storage/storageAccounts
            $rgName = $rID.ResourceGroupName

            $tfstate_resource_id = $rID.ResourceId

            $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $StorageAccountName; "tfstate_resource_id" = $tfstate_resource_id ; "Landscape" = $landscape_tfstate_key; "Vault" = $Vault ; "STATE_SUBSCRIPTION" = $State_subscription; "Subscription" = $Subscription }
            $iniContent += @{$combined = $Category1 }
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
            $iniContent = Get-IniContent -Path $fileINIPath
     
        }
        else {
            if ($StorageAccountName.Length > 0) {

            }
            else {
                

                if ($null -ne $Deployerenvironment -and "" -ne $Deployerenvironment) {
                    $deployercombined = $Deployerenvironment + $region
                }
                else {
                    $Deployerenvironment = Read-Host -Prompt "Please specify the environment name for the deployer"
                    $deployercombined = $Deployerenvironment + $region
            
                }

                if ($null -ne $iniContent[$deployercombined]) {
                    Write-Host "Reading the state information from the deployer"
                    if ($StorageAccountName.Length -eq 0) {
                        $rgName = $iniContent[$deployercombined]["REMOTE_STATE_RG"]
                        $saName = $iniContent[$deployercombined]["REMOTE_STATE_SA"]
                        $tfstate_resource_id = $iniContent[$deployercombined]["tfstate_resource_id"] 
                        $deployer_tfstate_key = $iniContent[$deployercombined]["Deployer"]
                        $vault = $iniContent[$deployercombined]["Vault"]
                        $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $saName; "tfstate_resource_id" = $tfstate_resource_id ; "Landscape" = $landscape_tfstate_key; "Deployer" = $deployer_tfstate_key; "Vault" = $Vault; }
                        $iniContent += @{$combined = $Category1 }
                        Out-IniFile -InputObject $iniContent -Path $fileINIPath
                        $iniContent = Get-IniContent -Path $fileINIPath
                    }
         
                }
                else {
                    if ($StorageAccountName.Length -eq 0) {

                        Write-Error "The Terraform state information is not available"

                        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
                        $rID = Get-AzStorageAccount -Name $saName
                        $rgName = $rID.ResourceGroupName
    
                        $tfstate_resource_id = $rID.ResourceId
    
                        $Category1 = @{"REMOTE_STATE_RG" = $rgName; "REMOTE_STATE_SA" = $saName; "tfstate_resource_id" = $tfstate_resource_id ; "Landscape" = $landscape_tfstate_key }
                        $iniContent += @{$combined = $Category1 }
                        Out-IniFile -InputObject $iniContent -Path $fileINIPath
                        $iniContent = Get-IniContent -Path $fileINIPath
                    }
                
                }
            }


        }
    }
    else {
        $deployer_tfstate_key = $iniContent[$combined]["Deployer"]
        if ($null -eq $deployer_tfstate_key -or "" -eq $deployer_tfstate_key) {
            $deployer_tfstate_key = $Deployerstatefile
            $iniContent[$combined]["Deployer"] = $Deployerstatefile
        }
        $iniContent[$combined]["Landscape"] = $landscape_tfstate_key
        $changed = $true
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
        $iniContent = Get-IniContent -Path $fileINIPath

    
    }

    # Subscription
    $sub = $iniContent[$combined]["subscription"]

    if ($sub -ne $Subscription) {
        $sub = $Subscription
        $iniContent[$combined]["subscription"] = $Subscription
        $changed = $true
        
    }

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the deployment"
        $iniContent[$combined]["subscription"] = $sub
        $changed = $true
    }

    $vaultname = $iniContent[$combined]["Vault"] 

    if ($Vault -ne $vaultname) {
        $vaultname = $Vault
        $iniContent[$combined]["Vault"] = $vaultname
        $changed = $true
    }

    $state_subscription_id = $iniContent[$combined]["STATE_SUBSCRIPTION"]

    if ($State_subscription -ne $state_subscription_id) {
        $state_subscription_id = $State_subscription
        $iniContent[$combined]["STATE_SUBSCRIPTION"] = $state_subscription_id 
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $bAsk = $true
    if ($null -ne $vault -and "" -ne $vault) {
        if ($null -eq (Get-AzKeyVaultSecret -VaultName $vaultname -Name ($Environment + "-client-id") )) {
            $bAsk = $true
            if (($null -ne $SPN_id) -and ($null -ne $SPN_password) -and ($null -ne $Tenant_id)) {
                Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vaultname -SPN_id $SPN_id -SPN_password $SPN_password -Tenant_id $Tenant_id -Workload
                $iniContent = Get-IniContent -Path $fileINIPath
        
                $step = 2
                $iniContent[$combined]["step"] = $step
                Out-IniFile -InputObject $iniContent -Path $fileINIPath
                $bAsk = $false
            }
        }
        else {
            $bAsk = $false
        }
    }    
    if ($bAsk) {
        $ans = Read-Host -Prompt "Do you want to enter the Workload SPN secrets Y/N?"
        if ("Y" -eq $ans) {
            $vault = $iniContent[$combined]["Vault"]

            if (($null -eq $vault ) -or ("" -eq $vault)) {
                $vault = Read-Host -Prompt "Please enter the vault name"
                $iniContent[$combined]["Vault"] = $vault 
                Out-IniFile -InputObject $iniContent -Path $fileINIPath
    
            }
            try {
                Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vault -Workload 
                $iniContent = Get-IniContent -Path $fileINIPath
            }
            catch {
                return
            }
        }
    }

    if ($StorageAccountName.Length -gt 0) {
        $saName = $StorageAccountName
    }
    else {
        if ($iniContent[$combined]["REMOTE_STATE_SA"].Trim().Length -gt 0) {
            $saName = $iniContent[$combined]["REMOTE_STATE_SA"].Trim()    
        }
    }
    
    if ($null -eq $saName -or "" -eq $saName) {
        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName -ResourceType Microsoft.Storage/storageAccounts
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId

        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }


    if ($null -eq $tfstate_resource_id -or "" -eq $tfstate_resource_id) {
        if ($null -ne $saName -and "" -ne $saName) {
            $rID = Get-AzResource -Name $saName -ResourceType Microsoft.Storage/storageAccounts
            $rgName = $rID.ResourceGroupName
            $tfstate_resource_id = $rID.ResourceId
            $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
            $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
        }
    }

    Write-Host -ForegroundColor green "Initializing Terraform  New-SAPWorkloadZone"

    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\run\$Type"
    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")


    Write-Host -ForegroundColor green "Initializing Terraform  New-SAPWorkloadZone"

    $Command = " init -upgrade=true -backend-config ""subscription_id=$state_subscription_id"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$envkey"" "
    if (Test-Path ".terraform" -PathType Container) {
        if (Test-Path ".\.terraform\terraform.tfstate" -PathType Leaf) {

            $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

            if ("azurerm" -eq $jsonData.backend.type) {
                $Command = " init -upgrade=true"
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

    $deployer_tfstate_key_parameter = ""
    $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
    if ($Deployerstatefile.Length -gt 0) {
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $Deployerstatefile
    }
    else {
        if ($deployer_tfstate_key.Length -gt 0) {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key    
        }
    }

    $Command = " init -upgrade=true -backend-config ""subscription_id=$state_subscription_id"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$envkey"" "
    if (Test-Path ".terraform" -PathType Container) {
        if (Test-Path ".\.terraform\terraform.tfstate" -PathType Leaf) {

            $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

            if ("azurerm" -eq $jsonData.backend.type) {
                $Command = " init -upgrade=true"
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

    $deployer_tfstate_key_parameter = ""
    $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
    if ($Deployerstatefile.Length -gt 0) {
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $Deployerstatefile
    }
    else {
        if ($deployer_tfstate_key.Length -gt 0) {
            $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key    
        }
    }

    Write-Host -ForegroundColor green "Running refresh, please wait"
    $Command = " refresh -var-file " + $fInfo.Fullname + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    $Command = " output automation_version"

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    Write-Verbose $Cmd

    $versionLabel = & ([ScriptBlock]::Create($Cmd)) | Out-String 

    if ("" -eq $versionLabel) {
        Write-Host ""
        Write-Host -ForegroundColor red "The environment was deployed using an older version of the Terrafrom templates"
        Write-Host ""
        Write-Host -ForegroundColor red "!!! Risk for Data loss !!!"
        Write-Host ""
        Write-Host -ForegroundColor red "Please inspect the output of Terraform plan carefully before proceeding" 
        Write-Host ""
        if ($PSCmdlet.ShouldProcess($Parameterfile)) {
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
        Write-Host ""
        Write-Host -ForegroundColor green "The environment was deployed using the $versionLabel version of the Terrafrom templates"
        Write-Host ""
        Write-Host ""
    }

    Write-Host -ForegroundColor green "Running plan, please wait"
    $Command = " plan  -no-color -var-file " + $fInfo.Fullname + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter

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

    Write-Host $planResults
    if (-not $planResultsPlain.Contains('0 to change, 0 to destroy') ) {
        Write-Host ""
        Write-Host -ForegroundColor red "!!! Risk for Data loss !!!"
        Write-Host ""
        Write-Host -ForegroundColor red "Please inspect the output of Terraform plan carefully before proceeding" 
        Write-Host ""
        if ($PSCmdlet.ShouldProcess($Parameterfile)) {
            $ans = Read-Host -Prompt "Do you want to continue Y/N?"
            if ("Y" -ne $ans) {
                $Env:TF_DATA_DIR = $null
                return 
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($Parameterfile)) {
        Write-Host -ForegroundColor green "Running apply"
        if ($Silent) {
            $Command = " apply --auto-approve -var-file " + $fInfo.Fullname + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter
        }
        else {
            $Command = " apply -var-file " + $fInfo.Fullname + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter
        }
        
        Add-Content -Path "deployment.log" -Value $Cmd
        Write-Verbose $Cmd

        $Cmd = "terraform -chdir=$terraform_module_directory $Command"
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            $Env:TF_DATA_DIR = $null
            throw "Error executing command: $Cmd"
        }
    
    }

    $Env:TF_DATA_DIR = $null
}

