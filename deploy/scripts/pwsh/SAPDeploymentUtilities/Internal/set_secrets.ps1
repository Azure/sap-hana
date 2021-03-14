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
        [Parameter(Mandatory = $true)][string]$Tenant = ""
    )

    Write-Host -ForegroundColor green ""
    Write-Host -ForegroundColor green "Saving the secrets"

    $mydocuments = [environment]::getfolderpath("mydocuments")
    $filePath = $mydocuments + "\sap_deployment_automation.ini"
    $iniContent = Get-IniContent $filePath

    $combined = $Environment + $region

    $UserUPN = ([ADSI]"LDAP://<SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)>").UserPrincipalName
    If ($UserUPN) {
        Set-AzKeyVaultAccessPolicy -VaultName $VaultName -UserPrincipalName $UserUPN -PermissionsToSecrets Get,List,Set,Recover,Restore
    }

    # Subscription
    $sub = $iniContent[$combined]["subscription"]
    if ($null -eq $sub -or "" -eq $sub) {
        $sub = Read-Host -Prompt "Please enter the subscription for the key vault"
        $iniContent[$combined]["subscription"] = $sub
        $changed = $true
    }


    Write-Host "Setting the secrets for " $Environment

    # Read keyvault
    $v = $iniContent[$combined]["Vault"]

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
    $spnid = $iniContent[$combined]["Client_id"]

    if ($Client_id -eq "") {
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

    if ($Tenant -eq "") {
        if ($t -eq "" -or $null -eq $t) {
            $t = Read-Host -Prompt 'Tenant:'
            $iniContent[$combined]["Tenant"] = $t 
        }
    }
    else {
        $t = $Tenant
        $iniContent[$combined]["Tenant"] = $Tenant
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
    Write-Host "Setting the secret "$Secret_name " in vault " $v
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnid -AsPlainText -Force
    $Secret_name = $Environment + "-client-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $v
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret


    $Secret = ConvertTo-SecureString -String $t -AsPlainText -Force
    $Secret_name = $Environment + "-tenant-id"
    Write-Host "Setting the secret "$Secret_name " in vault " $v
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $spnpwd -AsPlainText -Force
    $Secret_name = $Environment + "-client-secret"
    Write-Host "Setting the secret "$Secret_name " in vault " $v
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

    $Secret = ConvertTo-SecureString -String $sub -AsPlainText -Force
    $Secret_name = $Environment + "-subscription"
    Write-Host "Setting the secret "$Secret_name + " in vault " + $v
    Set-AzKeyVaultSecret -VaultName $v -Name $Secret_name -SecretValue $Secret

}

