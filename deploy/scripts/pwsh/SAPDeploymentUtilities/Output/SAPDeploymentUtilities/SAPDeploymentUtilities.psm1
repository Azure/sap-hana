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

    $ParamFullFile = (Get-ItemProperty -Path $Parameterfile -Name Fullname).Fullname

    $envkey = $fInfo.Name.replace(".json", ".terraform.tfstate")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $fileINIPath

    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
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

    $changed = $false

    $landscape_tfstate_key = $fInfo.Name.replace(".json", ".terraform.tfstate")

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
            $rID = Get-AzResource -Name $StorageAccountName
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
                else {
                    if ($null -eq $StorageAccountName -or "" -eq $StorageAccountName) {

                        Write-Error "The Terraform state information is not available"

                        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
                        $rID = Get-AzResource -Name $saName 
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

    if ($StorageAccountName.Length -eq 0) {
        $saName = $StorageAccountName
    }
    else {
        $saName = $iniContent[$combined]["REMOTE_STATE_SA"].Trim()    
    }
    
    if ($null -eq $saName -or "" -eq $saName) {
        $saName = Read-Host -Prompt "Please specify the storage account name for the terraform storage account"
        $rID = Get-AzResource -Name $saName
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId

        $iniContent[$combined]["REMOTE_STATE_SA"] = $saName
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    else {
        $rgName = $iniContent[$combined]["REMOTE_STATE_RG"].Trim()
        $tfstate_resource_id = $iniContent[$combined]["tfstate_resource_id"].Trim()
    }

    if ($null -eq $tfstate_resource_id -or "" -eq $tfstate_resource_id) {
        $rID = Get-AzResource -Name $saName 
        $rgName = $rID.ResourceGroupName
        $tfstate_resource_id = $rID.ResourceId
        $iniContent[$combined]["REMOTE_STATE_RG"] = $rgName
        $iniContent[$combined]["tfstate_resource_id"] = $tfstate_resource_id
        Out-IniFile -InputObject $iniContent -Path $fileINIPath
    }

    $sub = $tfstate_resource_id.Split("/")[2]
    
    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\run\$Type"
    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Initializing Terraform"

    $Command = " init -upgrade=true -backend-config ""subscription_id=$state_subscription_id"" -backend-config ""resource_group_name=$rgName"" -backend-config ""storage_account_name=$saName"" -backend-config ""container_name=tfstate"" -backend-config ""key=$envkey"" "
    if (Test-Path ".terraform" -PathType Container) {
        if (Test-Path ".\.terraform\terraform.tfstate" -PathType Leaf) {

            $jsonData = Get-Content -Path .\.terraform\terraform.tfstate | ConvertFrom-Json

            if ("azurerm" -eq $jsonData.backend.type) {
                $Command = " init -upgrade=true"

                $ans = Read-Host -Prompt ".terraform already exists, do you want to continue Y/N?"
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
    $Command = " plan  -no-color -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter

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
            $Command = " apply --auto-approve -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter
        }
        else {
            $Command = " apply -var-file " + $ParamFullFile + $tfstate_parameter + $landscape_tfstate_key_parameter + $deployer_tfstate_key_parameter
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
function Read-KVNode {
    param(
        [Parameter(Mandatory = $true)][String]$source,
        [Parameter(Mandatory = $true)][PSCustomObject]$kv,
        [Parameter(Mandatory = $false)][bool]$CheckIDs = $false
    )

    if ($null -ne $kv.kv_spn_id) {
        Write-Host -ForegroundColor White ("SPN keyvault".PadRight(25, ' ') + $kv.kv_spn_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $kv.kv_spn_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $kv.kv_spn_id "does not exist"
            }
        }

    }
    else {
        Write-Host -ForegroundColor White ("SPN keyvault".PadRight(25, ' ') + "Deployer")
    }

    if ($null -ne $kv.kv_user_id) {
        Write-Host -ForegroundColor White ("User keyvault".PadRight(25, ' ') + $kv.kv_user_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $kv.kv_user_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $kv.kv_user_id "does not exist"
            }
        }
    }
    else {
        Write-Host -ForegroundColor White ("User keyvault".PadRight(25, ' ') + $source)
    }
    if ($null -ne $kv.kv_prvt_id) {
        Write-Host -ForegroundColor White ("Automation keyvault".PadRight(25, ' ') + $kv.kv_prvt_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $kv.kv_prvt_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $kv.kv_prvt_id "does not exist"
            }
        }

    }
    else {
        Write-Host -ForegroundColor White ("Automation keyvault".PadRight(25, ' ') + $source)
    }
}

function Read-OSNode {
    param(
        [Parameter(Mandatory = $true)][string]$Nodename,
        [Parameter(Mandatory = $true)][PSCustomObject]$os,
        [Parameter(Mandatory = $false)][bool]$CheckIDs = $false
    )

    if ($null -ne $os.source_image_id) {
        Write-Host -ForegroundColor White (($Nodename + " Custom image:").PadRight(25, ' ') + $os.source_image_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $os.source_image_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $os.source_image_id "does not exist"
            }
        }

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
        [Parameter(Mandatory = $true)][PSCustomObject]$subnet,
        [Parameter(Mandatory = $false)][bool]$CheckIDs = $false
    )
    
    if ($null -ne $subnet.arm_id) {
        Write-Host -ForegroundColor White (($Nodename + " subnet:").PadRight(25, ' ') + $subnet.arm_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $subnet.arm_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $subnet.arm_id "does not exist"
            }
        }
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
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $subnet.nsg.arm_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $subnet.nsg.arm_id "does not exist"
            }
        }
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

    .PARAMETER CheckIDs
        Boolean flag indicating if the ARM Ids should be validated

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Read-SAPDeploymemtTemplat -Parameterfile .\PROD-WEEU-SAP00-X00.json -Type sap_system

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
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $false)][bool]$CheckIDs = $false
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
    $db_zone_count = 0
    $app_zone_count = 0
    $scs_zone_count = 0
    $web_zone_count = 0

    if ("sap_system" -eq $Type) {
        $db_zone_count = $jsonData.databases[0].zones.Length
        $app_zone_count = $jsonData.application.app_zones.Length
        $scs_zone_count = $jsonData.application.scs_zones.Length
        $web_zone_count = $jsonData.application.web_zones.Length
    }
    $zone_count = ($db_zone_count, $app_zone_count, $scs_zone_count, $web_zone_count | Measure-Object -Max).Maximum

    Write-Host -ForegroundColor White "Deployment information"
    Write-Host -ForegroundColor White "------------------------------------------------------------------------------------------------"
    Write-Host -ForegroundColor White ("Environment:".PadRight(25, ' ') + $Environment)
    Write-Host -ForegroundColor White ("Region:".PadRight(25, ' ') + $region)
    Write-Host "-".PadRight(120, '-')
    if ($null -ne $jsonData.infrastructure.resource_group.arm_id) {
        Write-Host -ForegroundColor White ("Resource group:".PadRight(25, ' ') + $jsonData.infrastructure.resource_group.arm_id)
        if($CheckIDs) {
            $res = Get-AzResource -ResourceId $jsonData.infrastructure.resource_group.arm_id -ErrorAction SilentlyContinue
            if($null -eq $res){
                Write-Error "The resource" $jsonData.infrastructure.resource_group.arm_id "does not exist"
            }
        }
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
            if($CheckIDs) {
                $res = Get-AzResource -ResourceId $jsonData.infrastructure.vnets.management.armid -ErrorAction SilentlyContinue
                if($null -eq $res){
                    Write-Error "The resource" $jsonData.infrastructure.vnets.management.armid "does not exist"
                }
            }
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
        Read-SubnetNode -Nodename "management" -subnet $jsonData.infrastructure.vnets.management.subnet_mgmt -CheckIDs $CheckIDs

        if ($null -ne $jsonData.infrastructure.vnets.management.subnet_fw) {
            # Web subnet
            Read-SubnetNode -Nodename "firewall" -subnet $jsonData.infrastructure.vnets.management.subnet_fw -CheckIDs $CheckIDs
        }

        if ($null -ne $jsonData.deployers) {
            if ($null -ne $jsonData.deployers[0].os) {
                Read-OSNode -Nodename "  Image" -os $jsonData.deployers[0].os -CheckIDs $CheckIDs
            }
            if ($null -ne $jsonData.deployers[0].size) {
                Write-Host -ForegroundColor White ("  sku:".PadRight(25, ' ') + $jsonData.deployers[0].size)    
            }
    
        }

        Write-Host -ForegroundColor White "Keyvault"
        Write-Host "-".PadRight(120, '-')
        if ($null -ne $jsonData.key_vault) {
            Read-KVNode -source "Deployer Keyvault" -kv $jsonData.key_vault -CheckIDs $CheckIDs
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
            Read-KVNode -source "Library Keyvault" -kv $jsonData.key_vault -CheckIDs $CheckIDs
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
            if($CheckIDs) {
                $res = Get-AzResource -ResourceId $jsonData.infrastructure.vnets.sap.armid -ErrorAction SilentlyContinue
                if($null -eq $res){
                    Write-Error "The resource" $jsonData.infrastructure.vnets.sap.armid "does not exist"
                }
            }

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
            Read-KVNode -source "Workload keyvault" -kv $jsonData.key_vault -CheckIDs $CheckIDs
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
        Read-SubnetNode -Nodename "admin" -subnet $jsonData.infrastructure.vnets.sap.subnet_admin -CheckIDs $CheckIDs
        # Database subnet
        Read-SubnetNode -Nodename "database" -subnet $jsonData.infrastructure.vnets.sap.subnet_db -CheckIDs $CheckIDs
        # Application subnet
        Read-SubnetNode -Nodename "database" -subnet $jsonData.infrastructure.vnets.sap.subnet_app -CheckIDs $CheckIDs

        if ($null -ne $jsonData.infrastructure.vnets.sap.subnet_web) {
            # Web subnet
            Read-SubnetNode -Nodename "web" -subnet $jsonData.infrastructure.vnets.sap.subnet_web -CheckIDs $CheckIDs
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
        Read-OSNode -Nodename "Image" -os $jsonData.databases[0].os -CheckIDs $CheckIDs
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
        Read-OSNode -Nodename "  Image" -os $jsonData.application.os -CheckIDs $CheckIDs
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
            Read-OSNode -Nodename "  Image" -os $jsonData.application.scs_os -CheckIDs $CheckIDs
        }
        else {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.os -CheckIDs $CheckIDs
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
            Read-OSNode -Nodename "  Image" -os $jsonData.application.web_os -CheckIDs $CheckIDs
        }
        else {
            Read-OSNode -Nodename "  Image" -os $jsonData.application.os -CheckIDs $CheckIDs
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
            Read-KVNode -source "Workload keyvault" -kv $jsonData.key_vault -CheckIDs $CheckIDs
        }
    }
}
function Remove-SAPAutomationRegion {
    <#
    .SYNOPSIS
        Removes a new SAP Environment (Deployer, Library)

    .DESCRIPTION
        Removes a new SAP Environment (Deployer, Library)

    .PARAMETER DeployerParameterfile
        This is the parameter file for the Deployer

    .PARAMETER LibraryParameterfile
        This is the parameter file for the library


    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"

    Remove-SAPAutomationRegion -DeployerParameterfile .\DEPLOYER\PROD-WEEU-DEP00-INFRASTRUCTURE\PROD-WEEU-DEP00-INFRASTRUCTURE.json 
     -LibraryParameterfile .\LIBRARY\PROD-WEEU-SAP_LIBRARY\PROD-WEEU-SAP_LIBRARY.json 
    
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
    Write-Host -ForegroundColor green "Removes the deployer and library"

    $Parameterfile = $DeployerParameterfile

    $fInfo = Get-ItemProperty -Path $Parameterfile
    if (!$fInfo.Exists ) {
        Write-Error ("File " + $Parameterfile + " does not exist")
        return
    }

    $DeployerParamFullFile = (Get-ItemProperty -Path $DeployerParameterfile -Name Fullname).Fullname
    $LibraryParamFullFile = (Get-ItemProperty -Path $LibraryParameterfile -Name Fullname).Fullname

    $CachePath = (Join-Path -Path $Env:APPDATA -ChildPath "terraform.d\plugin-cache")
    if ( -not (Test-Path -Path $CachePath)) {
        New-Item -Path $CachePath -ItemType Directory
    }
    $env:TF_PLUGIN_CACHE_DIR = $CachePath
    $curDir = (Get-Location)
    [IO.DirectoryInfo] $dirInfo = $curDir.ToString()

    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")
 
    Add-Content -Path "deployment.log" -Value ("Removing")
    Add-Content -Path "deployment.log" -Value (Get-Date -Format "yyyy-MM-dd HH:mm")

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $filePath

    $repo = $iniContent["Common"]["repo"]


    $jsonData = Get-Content -Path $Parameterfile | ConvertFrom-Json

    $Environment = $jsonData.infrastructure.environment
    $region = $jsonData.infrastructure.region
    $combined = $Environment + $region

    $ctx = Get-AzContext
    if ($null -eq $ctx) {
        Connect-AzAccount  
    }

    #////////////////////////////////////////////////////////////////////////////////////
    #//
    #//              Reinitializing the deployer to get the state file local
    #//
    #////////////////////////////////////////////////////////////////////////////////////
    
    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_deployer"
    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Running init"

    $statefile = (Join-Path -Path $fInfo.Directory.FullName -ChildPath "terraform.tfstate")
    $Command = " init -upgrade=true -force-copy -backend-config ""path=$statefile"""

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }


    #////////////////////////////////////////////////////////////////////////////////////
    #//
    #//              Reinitializing the library to get the state file local
    #//
    #////////////////////////////////////////////////////////////////////////////////////


    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_library"
    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $LibraryParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Running init"

    $statefile = (Join-Path -Path $fInfo.Directory.FullName -ChildPath "terraform.tfstate")
    $Command = " init -upgrade=true -force-copy -backend-config ""path=$statefile"""

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    #////////////////////////////////////////////////////////////////////////////////////
    #//
    #//              Removing the library
    #//
    #////////////////////////////////////////////////////////////////////////////////////

    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_library"
    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $LibraryParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Running destroy of the library"
    $Command = " destroy -var-file " + $LibraryParamFullFile 

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }

    #////////////////////////////////////////////////////////////////////////////////////
    #//
    #//              Removing the deployer
    #//
    #////////////////////////////////////////////////////////////////////////////////////



    $terraform_module_directory = Join-Path -Path $repo -ChildPath "\deploy\terraform\bootstrap\sap_deployer"
    $fileDir = (Join-Path -Path $dirInfo.ToString() -ChildPath $DeployerParameterfile)
    [IO.FileInfo] $fInfo = $fileDir

    $Env:TF_DATA_DIR = (Join-Path -Path $fInfo.Directory.FullName -ChildPath ".terraform")

    Write-Host -ForegroundColor green "Running destroy of the deployer"
    $Command = " destroy -var-file " + $DeployerParamFullFile 

    $Cmd = "terraform -chdir=$terraform_module_directory $Command"
    Add-Content -Path "deployment.log" -Value $Cmd
    & ([ScriptBlock]::Create($Cmd))  
    if ($LASTEXITCODE -ne 0) {
        $Env:TF_DATA_DIR = $null
        throw "Error executing command: $Cmd"
    }


    $iniContent[$combined]["REMOTE_STATE_RG"] = ""
    $iniContent[$combined]["REMOTE_STATE_SA"] = ""
    $iniContent[$combined]["tfstate_resource_id"] = ""
    $iniContent[$combined]["STATE_SUBSCRIPTION"] = ""
    $iniContent[$combined]["Deployer"] = ""
    $iniContent[$combined]["STATE_SUBSCRIPTION"] = ""
    $iniContent[$combined]["step"] = 0
    Out-IniFile -InputObject $iniContent -Path $filePath
    $Env:TF_DATA_DIR = $null
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

    .PARAMETER VaultName
        This is the name of the keyvault

    .PARAMETER SPN_id
        This is the SPN Application ID

    .PARAMETER SPN_password
        This is the SAP Application password

    .PARAMETER Tenant_id
        This is the Tenant_id ID for the SPN
        

    .EXAMPLE 

    #
    #
    # Import the module
    Import-Module "SAPDeploymentUtilities.psd1"
    Set-SAPSPNSecrets -Environment PROD -VaultName <vaultname> -SPN_id <appId> -SPN_password <clientsecret> -Tenant_id <Tenant_idID> 

    
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
        [Parameter(Mandatory = $true)][string]$SPN_id,
        #SPN App secret
        [Parameter(Mandatory = $true)][string]$SPN_password,
        #Tenant_id
        [Parameter(Mandatory = $true)][string]$Tenant_id,
        #Workload
        [Parameter(Mandatory = $false )][Switch]$Workload


    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Saving the secrets"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $fileINIPath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent -Path $fileINIPath

    $combined = $Environment + $region

    if ($null -eq $iniContent[$combined]) {
        $Category1 = @{"subscription" = "" }
        $iniContent += @{$combined = $Category1 }
    }

    if($Workload) {
        Write-Host ("Setting SPN for workload" + "("+ $combined +")")
        $sub = $iniContent[$combined]["subscription"]
    }
    else {
        $sub = $iniContent[$combined]["STATE_SUBSCRIPTION"]
        Write-Host ("Setting SPN for deployer" + "("+ $combined +")")
    }

    # Subscription
    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the SPN"
        if($Workload) {
            $iniContent[$combined]["subscription"] = $sub
        }
        else {
            $iniContent[$combined]["STATE_SUBSCRIPTION"] = $sub
        }
    }

    $ctx= Get-AzContext
    if($null -eq $ctx) {
        Connect-AzAccount -Subscription $sub
    }
 
    $UserUPN = ([ADSI]"LDAP://<SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)>").UserPrincipalName
    If ($UserUPN) {
        $UPNAsString = $UserUPN.ToString()
        Set-AzKeyVaultAccessPolicy -VaultName $VaultName -UserPrincipalName $UPNAsString -PermissionsToSecrets Get, List, Set, Recover, Restore
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
    $spnid = $iniContent[$combined]["SPN_id"]

    if ("" -eq $SPN_id ) {
        if ($spnid -eq "" -or $null -eq $spnid) {
            $spnid = Read-Host -Prompt 'SPN App ID:'
            $iniContent[$combined]["SPN_id"] = $spnid 
        }
    }
    else {
        $spnid = $SPN_id
        $iniContent[$combined]["SPN_id"] = $SPN_id
    }

    # Read Tenant_id
    $t = $iniContent[$combined]["Tenant_id"]

    if ("" -eq $Tenant_id) {
        if ($t -eq "" -or $null -eq $t) {
            $t = Read-Host -Prompt 'Tenant_id:'
            $iniContent[$combined]["Tenant_id"] = $t 
        }
    }
    else {
        $t = $Tenant_id
        $iniContent[$combined]["Tenant_id"] = $Tenant_id
    }

    if ("" -eq $SPN_password) {
        $spnpwd = Read-Host -Prompt 'SPN Password:'
    }
    else {
        $spnpwd = $SPN_password
    }

    Out-IniFile -InputObject $iniContent -Path $fileINIPath

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret -ErrorAction SilentlyContinue -ErrorVariable err
    
    $Secret = ConvertTo-SecureString -String $spnid -AsPlainText -Force
    $Secret_name = $Environment + "-client-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret -ErrorAction SilentlyContinue -ErrorVariable err
    
    $Secret = ConvertTo-SecureString -String $t -AsPlainText -Force
    $Secret_name = $Environment + "-tenant-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret -ErrorAction SilentlyContinue -ErrorVariable err
    
    $Secret = ConvertTo-SecureString -String $spnpwd -AsPlainText -Force
    $Secret_name = $Environment + "-client-secret"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret -ErrorAction SilentlyContinue -ErrorVariable err
    
    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription"
    Write-Host "Setting the secret "$Secret_name " in vault " $vault
    Set-AzKeyVaultSecret -VaultName $vault -Name $Secret_name -SecretValue $Secret -ErrorAction SilentlyContinue -ErrorVariable err

    if ($null -eq (Get-AzKeyVaultSecret -VaultName $vault -Name $Secret_name )) {
        throw "Could not set the secrets"
    }



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
