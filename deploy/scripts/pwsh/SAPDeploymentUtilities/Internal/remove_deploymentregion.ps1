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