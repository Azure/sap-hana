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

