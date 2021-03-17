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
