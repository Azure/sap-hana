function Get-IniContent {
    <#
    .SYNOPSIS
        Get-IniContent

    
.LINK
    https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/

    #>
    <#
#>
    [cmdletbinding()]
    param(
        #Parameter file
        [Parameter(Mandatory = $true)][string]$FilePath
    )
    $ini = @{}
    switch -regex -file $FilePath {
        "^\[(.+)\]" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^\s(0,)(;.*)$" {
            # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" {
            # Key
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

function Out-IniFile {
    <#
        .SYNOPSIS
            Out-IniContent
    
        
    .LINK
        https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
    
        #>
    <#
    #>
    [cmdletbinding()]
    param(
        # Object
        [Parameter(Mandatory = $true)]$InputObject,
        #Ini file
        [Parameter(Mandatory = $true)][string]$FilePath
    )
    
    $outFile = New-Item -ItemType file -Path $FilePath -Force
    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq "Hashtable")) {
            #No Sections
            Add-Content -Path $outFile -Value "$i=$($InputObject[$i])"
        }
        else {
            #Sections
            Add-Content -Path $outFile -Value "[$i]"
            Foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                if ($j -match "^Comment[\d]+") {
                    Add-Content -Path $outFile -Value "$($InputObject[$i][$j])"
                }
                else {
                    Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])"
                }

            }
            Add-Content -Path $outFile -Value ""
        }
    }
}

function New-System {
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
    New-System -Parameterfile .\PROD-WEEU-SAP00-ZZZ.json -Type sap_system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    New-System -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -Type sap_library

    
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
    Write-Host -ForegroundColor green "Deploying the" $Type

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath

    [IO.FileInfo] $fInfo = $Parameterfile
    $environmentname = ($fInfo.Name -split "-")[0]
    $region = ($fInfo.Name -split "-")[1]
    $combined = $environmentname + $region

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    $deployer_tfstate_key = $iniContent[$combined]["Deployer"]
    $landscape_tfstate_key = $iniContent[$combined]["Landscape"]

    $rgName = $iniContent[$environmentname]["REMOTE_STATE_RG"] 
    $saName = $iniContent[$environmentname]["REMOTE_STATE_SA"] 
    $tfstate_resource_id = $iniContent[$environmentname]["tfstate_resource_id"] 

    # Subscription
    $sub = $iniContent[$environmentname]["subscription"] 
    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$environmentname]["Subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the subscription"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -FilePath $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\run\" + $Type

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true -force-copy -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$key"" " +  $terraform_module_directory

    if (Test-Path ".terraform" -PathType Container) {

        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

        if ("azurerm" -eq $jsonData.backend.type) {
            $Command = " init -upgrade=true"

            $ans = Read-Host -Prompt ".terraform already exists, do you want to continue Y/N?"
            if ("Y" -ne $ans) {
                return
            }
        }
    } 

    $Cmd = "terraform $Command"
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
        $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key
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
        $ans = Read-Host -Prompt "Do you want to continue Y/N?"
        if ("Y" -eq $ans) {
    
        }
        else {
            return 
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
        $ans = Read-Host -Prompt "Do you want to continue Y/N?"
        if ("Y" -ne $ans) {
            return 
        }

    }

    Write-Host -ForegroundColor green "Running apply"
    $Command = " apply -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf"  -Force 
    }

}

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
function New-Library {
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
    New-Library -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -DeployerFolderRelativePath ..\..\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\

    
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
        [Parameter(Mandatory = $true)][string]$Parameterfile,
        #Deployer parameterfile
        [Parameter(Mandatory = $true)][string]$DeployerFolderRelativePath
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the library"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath

    [IO.FileInfo] $fInfo = $Parameterfile
    $environmentname = ($fInfo.Name -split "-")[0]

    # Subscription
    $sub = $iniContent[$environmentname]["subscription"] 
    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$environmentname]["subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the sap-hana repository path"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -FilePath $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\bootstrap\sap_library"

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
    if ($DeployerFolderRelativePath -eq "") {
        $Command = " plan -var-file " + $Parameterfile + " " + $terraform_module_directory
    }
    else {
        $Command = " plan -var-file " + $Parameterfile + " -var deployer_statefile_foldername=" + $DeployerFolderRelativePath + " " + $terraform_module_directory
    }

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
    if ($DeployerFolderRelativePath -eq "") {
        $Command = " apply -var-file " + $Parameterfile + " " + $terraform_module_directory
    }
    else {
        $Command = " apply -var-file " + $Parameterfile + " -var deployer_statefile_foldername=" + $DeployerFolderRelativePath + " " + $terraform_module_directory
    }

    $Cmd = "terraform $Command"
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    New-Item -Path . -Name "backend.tf" -ItemType "file" -Value "terraform {`n  backend ""local"" {}`n}" -Force

    $Command = " output remote_state_resource_group_name"
    $Cmd = "terraform $Command"
    $rgName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }
    $iniContent[$environmentname]["REMOTE_STATE_RG"] = $rgName.Replace("""","")

    $Command = " output remote_state_storage_account_name"
    $Cmd = "terraform $Command"
    $saName = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }
    $iniContent[$environmentname]["REMOTE_STATE_SA"] = $saName.Replace("""","")

    $Command = " output tfstate_resource_id"
    $Cmd = "terraform $Command"
    $tfstate_resource_id = & ([ScriptBlock]::Create($Cmd)) | Out-String 
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }
    $iniContent[$environmentname]["tfstate_resource_id"] = $tfstate_resource_id


    Out-IniFile -InputObject $iniContent -FilePath $filePath

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf" -Force 
    }

}
#>
Function Set-Secrets {
    <#
    .SYNOPSIS
        Sets the Secrets in Azure Keyvault

    .DESCRIPTION
        Sets the secrets in Azure Keyvault that are required for the deployment automation

    .PARAMETER Environment
        This is the name of the environment.

    .PARAMETER VAultNAme
        This is the name of the keyvault

    .PARAMETER Client_id
        This is the SPN Application ID

    .PARAMETER Client_secret
        This is the SAP Application password

    .PARAMETER Tenant
        This is the Tenant ID for the SPN
        

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Set-Secrets -Environment PROD -VaultName <vaultname> -Client_id <appId> -Client_secret <clientsecret> -Tenant <TenantID> 

    
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
        #Environment name
        [Parameter(Mandatory = $true)][string]$Environment,
        #Keyvault name
        [Parameter(Mandatory = $true)][string]$VaultName,
        # #SPN App ID
        [Parameter(Mandatory = $true)][string]$Client_id="",
        #SPN App secret
        [Parameter(Mandatory = $true)][string]$Client_secret,
        #Tenant
        [Parameter(Mandatory = $true)][string]$Tenant=""
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Saving the secrets"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath

    # Subscription
    $sub = $iniContent[$Environment]["Subscription"]

    Write-Host "Setting the secrets for " $Environment

    # Read keyvault
    $v = $iniContent[$Environment]["Vault"]

    Write-Host $v


    if ($VaultName -eq "") {
        if ($v -eq "" -or $null -eq $v) {
            $v = Read-Host -Prompt 'Keyvault:'
        }
    }
    else {
        $v = $VaultName
    }

    # Read SPN ID
    $spnid = $iniContent[$Environment]["Client_id"]

    if ($Client_id -eq "") {
        if ($spnid -eq "" -or $null -eq $spnid) {
            $spnid = Read-Host -Prompt 'SPN App ID:'
            $iniContent[$Environment]["Client_id"]=$spnid 
        }
    }
    else {
        $spnid = $Client_id
        $iniContent[$Environment]["Client_id"]=$Client_id
    }

    # Read Tenant
    $t = $iniContent[$Environment]["Tenant"]

    if ($Tenant -eq "") {
        if ($t -eq "" -or $null -eq $t) {
            $t = Read-Host -Prompt 'Tenant:'
            $iniContent[$Environment]["Tenant"] = $t 
        }
    }
    else {
        $t = $Tenant
        $iniContent[$Environment]["Tenant"] = $Tenant
    }

    if ($Client_secret -eq "") {
        $spnpwd = Read-Host -Prompt 'SPN Password:'
    }
    else {
        $spnpwd = $Client_secret
    }

    Out-IniFile -InputObject $iniContent -FilePath $filePath

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription-id"
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnid -AsPlainText -Force
    $Secret_name = $Environment + "-client-id"
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret


    $Secret = ConvertTo-SecureString -String $t -AsPlainText -Force
    $Secret_name = $Environment + "-tenant-id"
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnpwd -AsPlainText -Force
    $Secret_name = $Environment + "-client-secret"
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription"
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

}

