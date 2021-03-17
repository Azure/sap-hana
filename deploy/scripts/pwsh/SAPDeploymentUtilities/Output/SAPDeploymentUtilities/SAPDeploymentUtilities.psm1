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
        [Parameter(Mandatory = $true)][string]$Path
    )
    $ini = @{}
    switch -regex -file $Path {
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
        [Parameter(Mandatory = $true)][string]$Path
    )

    New-Item -ItemType file -Path $Path -Force
    $outFile = $Path

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
        [Parameter(Mandatory = $true)][string]$Parameterfile
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the deployer"

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    Add-Content -Path "deployment.log" -Value "Bootstrap the deployer"
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json
    $region = $jsonData.infrastructure.region

    if ($null -ne $iniContent[$region] ) {
        $sub = $iniContent[$region]["subscription"] 
    }
    else {
        $Category1 = @{"subscription" = "" }
        $iniContent += @{$region = $Category1 }
        Out-IniFile -InputObject $iniContent -Path $filePath
    }
    
    # Subscription & repo path

    $sub = $iniContent[$region]["subscription"] 
    $repo = $iniContent["Common"]["repo"]

    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$region]["subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repository"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\bootstrap\sap_deployer"

    if (-not (Test-Path $terraform_module_directory) ) {
        Write-Host -ForegroundColor Red "The repository path: $repo is incorrect!"
        $iniContent["Common"]["repo"] = ""
        Out-IniFile -InputObject $iniContent -Path $filePath
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
        else {
            $ans = Read-Host -Prompt "The system has already been deployed, do you want to redeploy Y/N?"
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

    Write-Host -ForegroundColor green "Running plan"
    $Command = " plan -var-file " + $Parameterfile + " " + $terraform_module_directory
    
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

    if ( $planResultsPlain.Contains('Plan: 0 to add, 0 to change, 0 to destroy')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        return;
    }

    Write-Host $planResults
    
    if ($PSCmdlet.ShouldProcess($Parameterfile)) {
        Write-Host -ForegroundColor green "Running apply"

        $Command = " apply -var-file " + $Parameterfile + " " + $terraform_module_directory
        $Cmd = "terraform $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
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
        $iniContent[$region]["Vault"] = $kvName.Replace("""", "")
        Out-IniFile -InputObject $iniContent -Path $filePath

        if (Test-Path ".\backend.tf" -PathType Leaf) {
            Remove-Item -Path ".\backend.tf" -Force 
        }
    }
}
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
        $sub = $iniContent[$combined]["subscription"].Trim()  
    }
    else {
        $sub = $iniContent[$region]["subscription"].Trim()  
    }
    
    $repo = $iniContent["Common"]["repo"].Trim() 

    if ($null -eq $landscape_tfstate_key -or "" -eq $landscape_tfstate_key) {
        $landscape_tfstate_key = Read-Host -Prompt "Please enter the subscription for the deployment"
        if ($Type -eq "sap_system") {
            $iniContent[$combined]["Landscape"] = $landscape_tfstate_key.Trim()
        }
    
        $changed = $true
    }

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the deployment"
        if ($Type -eq "sap_system" -or $Type -eq "sap_landscape") {
            $iniContent[$combined]["subscription"] = $sub.Trim() 
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

    $terraform_module_directory = $repo + "\deploy\terraform\run\" + $Type

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
        if ($PSCmdlet.ShouldProcess($Parameterfile ,$Type)) {
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
        if ($PSCmdlet.ShouldProcess($Parameterfile ,$Type)) {
            $ans = Read-Host -Prompt "Do you want to continue Y/N?"
            if ("Y" -ne $ans) {
                return 
            }
        }

    }

    if ($PSCmdlet.ShouldProcess($Parameterfile ,$Type)) {

        Write-Host -ForegroundColor green "Running apply"
        $Command = " apply -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

        $Cmd = "terraform $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command: $Cmd"
        }
    }

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf"  -Force 
    }

}
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
        [Parameter(Mandatory = $true)][string]$DeployerFolderRelativePath
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Bootstrap the library"

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    Add-Content -Path "deployment.log" -Value "Bootstrap the library"
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")
    

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json
    $region = $jsonData.infrastructure.region

    # Subscription & repo path

    $sub = $iniContent[$region]["subscription"] 
    $repo = $iniContent["Common"]["repo"]

    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$region]["subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the path to the repository"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\bootstrap\sap_library"

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true " + $terraform_module_directory
    if (Test-Path ".terraform" -PathType Container) {
        $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

        if ("azurerm" -eq $jsonData.backend.type) {
            Write-Host -ForegroundColor green "State file already migrated to Azure!"
            $ans = Read-Host -Prompt "State is already migrated to Azure. Do you want to re-initialize the library Y/N?"
            if ("Y" -ne $ans) {
                return
            }
            else {
                $Command = " init -upgrade=true -reconfigure " + $terraform_module_directory
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($Parameterfile, $DeployerFolderRelativePath)) {
                $ans = Read-Host -Prompt "The system has already been deployed, do you want to redeploy Y/N?"
                if ("Y" -ne $ans) {
                    return
                }
            }
        }
    }
    
    $Cmd = "terraform $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
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

    if ( $planResultsPlain.Contains('Plan: 0 to add, 0 to change, 0 to destroy')) {
        Write-Host ""
        Write-Host -ForegroundColor Green "Infrastructure is up to date"
        Write-Host ""
        return;
    }

    Write-Host $planResults

    if ($PSCmdlet.ShouldProcess($Parameterfile, $DeployerFolderRelativePath)) {
    
        Write-Host -ForegroundColor green "Running apply"
        if ($DeployerFolderRelativePath -eq "") {
            $Command = " apply -var-file " + $Parameterfile + " " + $terraform_module_directory
        }
        else {
            $Command = " apply -var-file " + $Parameterfile + " -var deployer_statefile_foldername=" + $DeployerFolderRelativePath + " " + $terraform_module_directory
        }

        $Cmd = "terraform $Command"
        Add-Content -Path "deployment.log" -Value $Cmd
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

        if (Test-Path ".\backend.tf" -PathType Leaf) {
            Remove-Item -Path ".\backend.tf" -Force 
        }
    }

}
function New-SAPWorkloadZone {
    <#
    .SYNOPSIS
        Deploy a new SAP Workload Zone

    .DESCRIPTION
        Deploy a new SAP Workload Zone

    .PARAMETER Parameterfile
        This is the parameter file for the system

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
        #Parameter file
        [Parameter(Mandatory = $true)][string]$Parameterfile 
    )

    Write-Host -ForegroundColor green ""
    $Type = "sap_landscape"
    Write-Host -ForegroundColor green "Deploying the" $Type

    $fInfo = Get-ItemProperty -Path $Parameterfile

    if ($false -eq $fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $fileINIPath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region
    $changed = $false

    $envkey = $fInfo.Name.replace(".json", ".terraform.tfstate")

    if ($null -eq $iniContent[$region]) {
        Write-Error "The region data is not available"
        $deployer_tfstate_key = Read-Host ("Please provide the deployer state file name for the " + $region + " region")
        $Category1 = @{"Deployer" = $deployer_tfstate_key }
        $iniContent += @{$region = $Category1 }
    }
    else {
        $deployer_tfstate_key = $iniContent[$region]["Deployer"].Trim()
    }

    if ($null -ne $iniContent[$combined] ) {
        $iniContent[$combined]["Landscape"] = $envkey
        $changed = $true
    }
    else {
        $Category1 = @{"Landscape" = $envkey; "Subscription" = "" }
        $iniContent += @{$combined = $Category1 }
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $ans = Read-Host -Prompt "Do you want to enter the Workload SPN secrets Y/N?"
    if ("Y" -eq $ans) {
        $vault = $iniContent[$region]["Vault"]

        if (($null -eq $vault ) -or ("" -eq $vault)) {
            $vault = Read-Host -Prompt "Please enter the vault name"
            $iniContent[$region]["Vault"] = $vault 
            Out-IniFile -InputObject $iniContent -Path $fileINIPath
    
        }
        try {
            Set-SAPSPNSecrets -Region $region -Environment $Environment -VaultName $vault -Workload $true
            $iniContent = Get-IniContent -Path $fileINIPath
        }
        catch {
            return
        }
    }

    $rgName = $iniContent[$region]["REMOTE_STATE_RG"].Trim() 
    $saName = $iniContent[$region]["REMOTE_STATE_SA"].Trim() 
    $tfstate_resource_id = $iniContent[$region]["tfstate_resource_id"].Trim()

    # Subscription
    $sub = $iniContent[$combined]["subscription"].Trim() 
    $repo = $iniContent["Common"]["repo"].Trim()

    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$combined]["Subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter path to the repo"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\run\" + $Type

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true -backend-config ""subscription_id=$sub"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$envkey"" " + $terraform_module_directory

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

    $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
    $deployer_tfstate_key_parameter = " -var deployer_tfstate_key=" + $deployer_tfstate_key

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
        if ($PSCmdlet.ShouldProcess($Parameterfile)) {
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
        if ($PSCmdlet.ShouldProcess($Parameterfile)) {
            $ans = Read-Host -Prompt "Do you want to continue Y/N?"
            if ("Y" -ne $ans) {
                return 
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($Parameterfile)) {
        Write-Host -ForegroundColor green "Running apply"
        $Command = " apply -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

        $Cmd = "terraform $Command"
        & ([ScriptBlock]::Create($Cmd))  
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing command: $Cmd"
        }
    }
    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf"  -Force 
    }

}
function Read-KVNode {
    param(
        [Parameter(Mandatory = $true)][String]$source,
        [Parameter(Mandatory = $true)][PSCustomObject]$kv
    )

    if ($null -ne $kv.kv_spn_id) {
        Write-Host -ForegroundColor White ("SPN keyvault".PadRight(25, ' ') + $kv.kv_spn_id)
    }
    else {
        Write-Host -ForegroundColor White ("SPN keyvault".PadRight(25, ' ') + "Deployer")
    }

    if ($null -ne $kv.kv_user_id) {
        Write-Host -ForegroundColor White ("User keyvault".PadRight(25, ' ') + $kv.kv_user_id)
    }
    else {
        Write-Host -ForegroundColor White ("User keyvault".PadRight(25, ' ') + $source)
    }
    if ($null -ne $kv.kv_prvt_id) {
        Write-Host -ForegroundColor White ("Automation keyvault".PadRight(25, ' ') + $kv.kv_prvt_id)
    }
    else {
        Write-Host -ForegroundColor White ("Automation keyvault".PadRight(25, ' ') + $source)
    }
}

function Read-OSNode {
    param(
        [Parameter(Mandatory = $true)][string]$Nodename,
        [Parameter(Mandatory = $true)][PSCustomObject]$os
    )

    if ($null -ne $os.source_image_id) {
        Write-Host -ForegroundColor White (($Nodename + " Custom image:").PadRight(25, ' ') + $os.source_image_id)

        if ($null -ne $os.os_type) {
            Write-Host -ForegroundColor White (($Nodename + " Custom image os type:").PadRight(25, ' ') + $os.os_type)
        }
        else {
            Write-Error "The Operating system must be specified if custom images are used"
        }
    }
    else {
        
    
        if ($null -ne $os.publisher) {
            Write-Host -ForegroundColor White (($Nodename + " publisher:").PadRight(25, ' ') + $os.publisher)
        }
        if ($null -ne $os.offer) {
            Write-Host -ForegroundColor White (($Nodename + " offer:").PadRight(25, ' ') + $os.offer)
        }
        if ($null -ne $os.sku) {
            Write-Host -ForegroundColor White (($Nodename + " sku:").PadRight(25, ' ') + $os.sku)
        }
        if ($null -ne $os.version) {
            Write-Host -ForegroundColor White (($Nodename + " version:").PadRight(25, ' ') + $os.version)
        }
    }

}

function Read-SubnetNode {
    param(
        [Parameter(Mandatory = $true)][string]$Nodename,
        [Parameter(Mandatory = $true)][PSCustomObject]$subnet
    )
    
    if ($null -ne $subnet.arm_id) {
        Write-Host -ForegroundColor White (($Nodename + " subnet:").PadRight(25, ' ') + $subnet.arm_id)
    }
    else {
        if ($null -ne $subnet.name) {
            Write-Host -ForegroundColor White (("" + $NodeName + " subnet:").PadRight(25, ' ') + $subnet.name)
        }
        else {
            Write-Host -ForegroundColor White (("" + $NodeName + " subnet:").PadRight(25, ' ') + "(name defined by automation")
        }
        if ($null -ne $subnet.prefix) {
            Write-Host -ForegroundColor White ("  Prefix:".PadRight(25, ' ') + $subnet.prefix)
        }
        else {
            Write-Error "The address prefix for the "+ $NodeName + " subnet (infrastructure.vnets.sap.subnet_xxx) must be defined"
        }
    }
    if ($null -ne $subnet.nsg.arm_id) {
        Write-Host -ForegroundColor White (($NodeName + " subnet nsg:").PadRight(25, ' ') + $subnet.nsg.arm_id)
    }
    else {
        if ($null -ne $subnet.nsg.name) {
            Write-Host -ForegroundColor White (("" + $NodeName + " subnet nsg:").PadRight(25, ' ') + $subnet.nsg.name)
        }
        else {
            Write-Host -ForegroundColor White (("" + $NodeName + " subnet nsg:").PadRight(25, ' ') + "(name defined by automation")    
        }
        
    }


}

function Read-SAPDeploymentTemplate {
    <#
    .SYNOPSIS
        Validates a deployment template

    .DESCRIPTION
        Validates a deployment template

    .PARAMETER Parameterfile
        This is the parameter file for the system

    .PARAMETER Type
        This is the type of the system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Read-SAPDeploymemtTemplat -Parameterfile .\PROD-WEEU-SAP00-ZZZ.json -Type sap_system

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Read-SAPDeploymemtTemplat -Parameterfile .\PROD-WEEU-SAP_LIBRARY.json -Type sap_library

    
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
    Write-Host -ForegroundColor green "Validate the parameter file " $Parameterfile " " $Type

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json


    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $db_zone_count = $jsonData.databases[0].zones.Length
    $app_zone_count = $jsonData.application.app_zones.Length
    $scs_zone_count = $jsonData.application.scs_zones.Length
    $web_zone_count = $jsonData.application.web_zones.Length
    $zone_count = ($db_zone_count, $app_zone_count, $scs_zone_count, $web_zone_count | Measure-Object -Max).Maximum

    Write-Host -ForegroundColor White "Deployment information"
    Write-Host -ForegroundColor White "------------------------------------------------------------------------------------------------"
    Write-Host -ForegroundColor White ("Environment:".PadRight(25, ' ') + $Environment)
    Write-Host -ForegroundColor White ("Region:".PadRight(25, ' ') + $region)
    Write-Host "-".PadRight(120, '-')
    if ($null -ne $jsonData.infrastructure.resource_group.arm_id) {
        Write-Host -ForegroundColor White ("Resource group:".PadRight(25, ' ') + $jsonData.infrastructure.resource_group.arm_id)
    }
    else {
        if ($null -ne $jsonData.infrastructure.resource_group.name) {
            Write-Host -ForegroundColor White ("Resource group:".PadRight(25, ' ') + $jsonData.infrastructure.resource_group.name)
        }
        else {
            Write-Host -ForegroundColor White ("Resource group:".PadRight(25, ' ') + "(name defined by automation")
        }
    }
    if ( $zone_count -gt 1) {
        Write-Host -ForegroundColor White ("PPG:".PadRight(25, ' ') + "(" + $zone_count.ToString() + ") (name defined by automation")
    }
    else {
        Write-Host -ForegroundColor White ("PPG:".PadRight(25, ' ') + "(name defined by automation")
    }

    if ("sap_deployer" -eq $Type) {
        if ($null -ne $jsonData.infrastructure.vnets.management.armid) {
            Write-Host -ForegroundColor White ("Virtual Network:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.management.armid)
        }
        else {
            Write-Host -ForegroundColor White ("Virtual Network:".PadRight(25, ' ') + " (Name defined by automation")
            if ($null -ne $jsonData.infrastructure.vnets.management.address_space) {
                Write-Host -ForegroundColor White ("  Address space:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.management.address_space)
            }
            else {
                Write-Error "The address space for the virtual network (infrastructure-vnet.management.address_space) must be defined"
            }
        }
        # Management subnet
        Read-SubnetNode -Nodename "management" -subnet $jsonData.infrastructure.vnets.management.subnet_mgmt

        if ($null -ne $jsonData.infrastructure.vnets.management.subnet_fw) {
            # Web subnet
            Read-SubnetNode -Nodename "firewall" -subnet $jsonData.infrastructure.vnets.management.subnet_fw
        }

        if ($null -ne $jsonData.deployers) {
            if ($null -ne $jsonData.deployers[0].os) {
                Read-OSNode -Nodename "  Image" -os $jsonData.deployers[0].os
            }
            if ($null -ne $jsonData.deployers[0].size) {
                Write-Host -ForegroundColor White ("  sku:".PadRight(25, ' ') + $jsonData.deployers[0].size)    
            }
    
        }

        Write-Host -ForegroundColor White "Keyvault"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.key_vault) {
            Read-KVNode -source "Deployer Keyvault" -kv $jsonData.key_vault
        }

        if ($null -ne $jsonData.firewall_deployment) {
            Write-Host -ForegroundColor White ("Firewall:".PadRight(25, ' ') + $jsonData.firewall_deployment)
        }
        else {
            Write-Host -ForegroundColor White ("Firewall:".PadRight(25, ' ') + $false)
        }

    }
    if ("sap_library" -eq $Type) {
        Write-Host -ForegroundColor White "Keyvault"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.key_vault) {
            Read-KVNode -source "Library Keyvault" -kv $jsonData.key_vault
        }

    }
    if ("sap_landscape" -eq $Type) {
        if ($null -ne $jsonData.infrastructure.vnets.sap.name) {
            Write-Host -ForegroundColor White ("VNet Logical name:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.sap.name)
        }
        else {
            Write-Error "VNet Logical name (infrastructure-vnet.sap.name) must be defined"
        }
        if ($null -ne $jsonData.infrastructure.vnets.sap.armid) {
            Write-Host -ForegroundColor White ("Virtual Network:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.sap.armid)
        }
        else {
            Write-Host -ForegroundColor White ("Virtual Network:".PadRight(25, ' ') + " (Name defined by automation")
            if ($null -ne $jsonData.infrastructure.vnets.sap.address_space) {
                Write-Host -ForegroundColor White ("  Address space:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.sap.address_space)
            }
            else {
                Write-Error "The address space for the virtual network (infrastructure-vnet.sap.address_space) must be defined"
            }
        }

        Write-Host -ForegroundColor White "Keyvault"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.key_vault) {
            Read-KVNode -source "Workload keyvault" -kv $jsonData.key_vault
        }

    }
    if ("sap_system" -eq $Type) {

        Write-Host
        Write-Host -ForegroundColor White "Networking"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.infrastructure.vnets.sap.name) {
            Write-Host -ForegroundColor White ("VNet Logical name:".PadRight(25, ' ') + $jsonData.infrastructure.vnets.sap.name)
        }
        else {
            Write-Error "VNet Logical name (infrastructure-vnet.sap.name) must be defined"
        }

        # Admin subnet
        Read-SubnetNode -Nodename "admin" -subnet $jsonData.infrastructure.vnets.sap.subnet_admin
        # Database subnet
        Read-SubnetNode -Nodename "database" -subnet $jsonData.infrastructure.vnets.sap.subnet_db
        # Application subnet
        Read-SubnetNode -Nodename "database" -subnet $jsonData.infrastructure.vnets.sap.subnet_app

        if ($null -ne $jsonData.infrastructure.vnets.sap.subnet_web) {
            # Web subnet
            Read-SubnetNode -Nodename "web" -subnet $jsonData.infrastructure.vnets.sap.subnet_web
        }
        
        Write-Host
        Write-Host -ForegroundColor White "Database tier"
        Write-Host "-".PadRight(120, '-')
        Write-Host -ForegroundColor White ("Platform:".PadRight(25, ' ') + $jsonData.databases[0].platform)
        Write-Host -ForegroundColor White ("High availability:".PadRight(25, ' ') + $jsonData.databases[0].high_availability)
        Write-Host -ForegroundColor White ("Database load balancer:".PadRight(25, ' ') + "(name defined by automation")
        if ( $db_zone_count -gt 1) {
            Write-Host -ForegroundColor White ("Database availability set:".PadRight(25, ' ') + "(" + $db_zone_count.ToString() + ") (name defined by automation")
        }
        else {
            Write-Host -ForegroundColor White ("Database availability set:".PadRight(25, ' ') + "(name defined by automation")
        }
    
        Write-Host -ForegroundColor White ("Number of servers:".PadRight(25, ' ') + $jsonData.databases[0].dbnodes.Length)
        Write-Host -ForegroundColor White ("Database sizing:".PadRight(25, ' ') + $jsonData.databases[0].size)
        Read-OSNode -Nodename "Image" -os $jsonData.databases[0].os
        if ($jsonData.databases[0].zones.Length -gt 0) {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Zonal")    
            $Zones = "["
            for ($zone = 0 ; $zone -lt $jsonData.databases[0].zones.Length ; $zone++) {
                $Zones = $Zones + "" + $jsonData.databases[0].zones[$zone] + ","
            }
            $Zones = $Zones.Substring(0, $Zones.Length - 1)
            $Zones = $Zones + "]"
            Write-Host -ForegroundColor White ("  Zone:".PadRight(25, ' ') + $Zones)    
        }
        else {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Regional")    
        }
        
        if ($jsonData.databases[0].use_DHCP) {
            Write-Host -ForegroundColor White ("Networking:".PadRight(25, ' ') + "Use Azure provided IP addresses")    
        }
        else {
            Write-Host -ForegroundColor White ("Networking:".PadRight(25, ' ') + "Use Customer provided IP addresses")    
        }
        if ($jsonData.databases[0].authentication) {
            if ($jsonData.databases[0].authentication.type.ToLower() -eq "password") {
                Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "Username/password")    
            }
            else {
                Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "ssh keys")    
            }
    
        }
        else {
            Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "ssh keys")    
        }

        Write-Host
        Write-Host -ForegroundColor White "Application tier"
        Write-Host "-".PadRight(120, '-')
        if ($jsonData.application.authentication) {
            if ($jsonData.application.authentication.type.ToLower() -eq "password") {
                Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "Username/password")    
            }
            else {
                Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "key")    
            }
        }
        else {
            Write-Host -ForegroundColor White ("Authentication:".PadRight(25, ' ') + "key")    
        }

        Write-Host -ForegroundColor White "Application servers"
        if ( $app_zone_count -gt 1) {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(" + $app_zone_count.ToString() + ") (name defined by automation")
        }
        else {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(name defined by automation")
        }
        Write-Host -ForegroundColor White ("  Number of servers:".PadRight(25, ' ') + $jsonData.application.application_server_count)    
        Read-OSNode -Nodename "  Image" -os $jsonData.application.os
        if ($null -ne $jsonData.application.app_sku) {
            Write-Host -ForegroundColor White ("  sku:".PadRight(25, ' ') + $jsonData.application.app_sku)    
        }
        if ($jsonData.application.app_zones.Length -gt 0) {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Zonal")    
            $Zones = "["
            for ($zone = 0 ; $zone -lt $jsonData.application.app_zones.Length ; $zone++) {
                $Zones = $Zones + "" + $jsonData.application.app_zones[$zone] + ","
            }
            $Zones = $Zones.Substring(0, $Zones.Length - 1)
            $Zones = $Zones + "]"
            Write-Host -ForegroundColor White ("  Zone:".PadRight(25, ' ') + $Zones)    
        }
        else {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Regional")    
        }
        
        Write-Host -ForegroundColor White "Central Services"
        Write-Host -ForegroundColor White ("  Number of servers:".PadRight(25, ' ') + $jsonData.application.scs_server_count)    
        Write-Host -ForegroundColor White ("  High availability:".PadRight(25, ' ') + $jsonData.application.scs_high_availability)    
        Write-Host -ForegroundColor White ("  Load balancer:".PadRight(25, ' ') + "(name defined by automation")
        if ( $scs_zone_count -gt 1) {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(" + $scs_zone_count.ToString() + ") (name defined by automation")
        }
        else {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(name defined by automation")
        }
        if ($null -ne $jsonData.application.scs_os) {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.scs_os
        }
        else {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.os
        }
        if ($null -ne $jsonData.application.scs_sku) {
            Write-Host -ForegroundColor White ("  sku:".PadRight(25, ' ') + $jsonData.application.scs_sku)    
        }
        if ($jsonData.application.scs_zones.Length -gt 0) {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Zonal")    
            $Zones = "["
            for ($zone = 0 ; $zone -lt $jsonData.application.scs_zones.Length ; $zone++) {
                $Zones = $Zones + "" + $jsonData.application.scs_zones[$zone] + ","
            }
            $Zones = $Zones.Substring(0, $Zones.Length - 1)
            $Zones = $Zones + "]"
            Write-Host -ForegroundColor White ("  Zone:".PadRight(25, ' ') + $Zones)    
        }
        else {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Regional")    
        }
        Write-Host -ForegroundColor White "Web Dispatchers"
        Write-Host -ForegroundColor White ("  Number of servers:".PadRight(25, ' ') + $jsonData.application.webdispatcher_count)    
        Write-Host -ForegroundColor White ("  Load balancer:".PadRight(25, ' ') + "(name defined by automation")
        if ( $web_zone_count -gt 1) {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(" + $web_zone_count.ToString() + ") (name defined by automation")
        }
        else {
            Write-Host -ForegroundColor White ("  Availability set:".PadRight(25, ' ') + "(name defined by automation")
        }
        if ($null -ne $jsonData.application.web_os) {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.web_os
        }
        else {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.os
        }
        if ($null -ne $jsonData.application.web_sku) {
            Write-Host -ForegroundColor White ("  sku:".PadRight(25, ' ') + $jsonData.application.web_sku)    
        }

        if ($jsonData.application.web_zones.Length -gt 0) {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Zonal")    
            $Zones = "["
            for ($zone = 0 ; $zone -lt $jsonData.application.web_zones.Length ; $zone++) {
                $Zones = $Zones + "" + $jsonData.application.web_zones[$zone] + ","
            }
            $Zones = $Zones.Substring(0, $Zones.Length - 1)
            $Zones = $Zones + "]"
            Write-Host -ForegroundColor White ("  Zone:".PadRight(25, ' ') + $Zones)    
        }
        else {
            Write-Host -ForegroundColor White ("Deployment:".PadRight(25, ' ') + "Regional")    

        }
        Write-Host -ForegroundColor White "Keyvault"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.key_vault) {
            Read-KVNode -source "Workload keyvault" -kv $jsonData.key_vault
        }

    }


    
}
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
    Remove-System -Parameterfile .\PROD-WEEU-SAP00-ZZZ.json -Type sap_system

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

    Add-Content -Path "deployment.log" -Value ("Removing the: " + $Type)
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    Write-Host $combined

    $key = $fInfo.Name.replace(".json", ".terraform.tfstate")
    $deployer_tfstate_key = $iniContent[$region]["Deployer"]
    $landscape_tfstate_key = $iniContent[$combined]["Landscape"]

    $tfstate_resource_id = $iniContent[$region]["tfstate_resource_id"] 

    # Subscription
    $sub = $iniContent[$combined]["subscription"] 
    $repo = $iniContent["Common"]["repo"]
    $changed = $false

    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription"
        $iniContent[$combined]["Subscription"] = $sub
        $changed = $true
    }

    if ($null -eq $repo -or "" -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the subscription"
        $iniContent["Common"]["repo"] = $repo
        $changed = $true
    }

    if ($changed) {
        Out-IniFile -InputObject $iniContent -Path $filePath
    }

    $terraform_module_directory = $repo + "\deploy\terraform\run\" + $Type

    if ($Type -ne "sap_deployer") {
        $tfstate_parameter = " -var tfstate_resource_id=" + $tfstate_resource_id
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


    Write-Host -ForegroundColor green "Running destroy"
    $Command = " destroy -var-file " + $Parameterfile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter + " " + $terraform_module_directory

    $Cmd = "terraform $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        throw "Error executing command: $Cmd"
    }

    if (Test-Path ".\backend.tf" -PathType Leaf) {
        Remove-Item -Path ".\backend.tf"  -Force 
    }

}
#>
Function Set-SAPSPNSecrets {
    <#
    .SYNOPSIS
        Sets the SPN Secrets in Azure Keyvault

    .DESCRIPTION
        Sets the secrets in Azure Keyvault that are required for the deployment automation

    .PARAMETER Region
        This is the region name

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
    Set-SAPSPNSecrets -Environment PROD -VaultName <vaultname> -Client_id <appId> -Client_secret <clientsecret> -Tenant <TenantID> 

    
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
        #Region
        [Parameter(Mandatory = $true)][string]$Region,
        #Environment name
        [Parameter(Mandatory = $true)][string]$Environment,
        #Keyvault name
        [Parameter(Mandatory = $true)][string]$VaultName,
        # #SPN App ID
        [Parameter(Mandatory = $true)][string]$Client_id = "",
        #SPN App secret
        [Parameter(Mandatory = $true)][string]$Client_secret,
        #Tenant
        [Parameter(Mandatory = $true)][string]$Tenant = "",
        #Workload
        [Parameter(Mandatory = $true)][bool]$Workload = $true

    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Saving the secrets"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $combined = $Environment + $region

    if($false -eq $Workload) {
        $combined = $region
    }

    if ($null -eq $iniContent[$combined]) {
        $Category1 = @{"subscription" = "" }
        $iniContent += @{$combined = $Category1 }
    }

    $UserUPN = ([ADSI]"LDAP://<SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)>").UserPrincipalName
    If ($UserUPN) {
        $UPNAsString = $UserUPN.ToString()
        Set-AzKeyVaultAccessPolicy -VaultName $VaultName -UserPrincipalName $UPNAsString -PermissionsToSecrets Get, List, Set, Recover, Restore
    }

    # Subscription
    $sub = $iniContent[$combined]["subscription"]
    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the key vault"
        $iniContent[$combined]["subscription"] = $sub
    }

    Write-Host "Setting the secrets for " $Environment

    # Read keyvault
    $vault = $iniContent[$combined]["Vault"]

    if ("" -eq $VaultName) {
        if ($vault -eq "" -or $null -eq $vault) {
            $vault = Read-Host -Prompt 'Keyvault:'
        }
    }
    else {
        $vault = $VaultName
    }

    # Read SPN ID
    $spnid = $iniContent[$combined]["Client_id"]

    if ("" -eq $Client_id ) {
        if ($spnid -eq "" -or $null -eq $spnid) {
            $spnid = Read-Host -Prompt 'SPN App ID:'
            $iniContent[$combined]["Client_id"] = $spnid 
        }
    }
    else {
        $spnid = $Client_id
        $iniContent[$combined]["Client_id"] = $Client_id
    }

    # Read Tenant
    $t = $iniContent[$combined]["Tenant"]

    if ("" -eq $Tenant) {
        if ($t -eq "" -or $null -eq $t) {
            $t = Read-Host -Prompt 'Tenant:'
            $iniContent[$combined]["Tenant"] = $t 
        }
    }
    else {
        $t = $Tenant
        $iniContent[$combined]["Tenant"] = $Tenant
    }

    if ("" -eq $Client_secret) {
        $spnpwd = Read-Host -Prompt 'SPN Password:'
    }
    else {
        $spnpwd = $Client_secret
    }

    Out-IniFile -InputObject $iniContent -Path $filePath

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnid -AsPlainText -Force
    $Secret_name = $Environment + "-client-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $t -AsPlainText -Force
    $Secret_name = $Environment + "-tenant-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnpwd -AsPlainText -Force
    $Secret_name = $Environment + "-client-secret"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret

}

Add-Type -TypeDefinition @"
   public enum SAP_Types
   {
      sap_deployer,
      sap_landscape,
      sap_library,
      sap_system
   }
"@
