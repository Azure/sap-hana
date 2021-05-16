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

