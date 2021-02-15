# Implementing custom naming for the SAP on Azure Automation solution #

Although the SAP Automation provides a naming convention designed for enterprise usage it is possible for customers to implement their own naming logic and still use the automation to deploy the Azure resources.

## Overview of the naming module ##

All the names for the resources deployed by the automation are defined in a module called **sap\_namegenerator**. This allows for a central management of all the resource names and makes it easier to change naming conventions.

The module has files for:

- Virtual machine and computer names (../../../deploy/terraform/terraform-units/modules/sap_namegenerator/vm.tf)
- Resource groups (resourcegroup.tf)
- Keyvaults (keyvault.tf)
- Resource suffixes for the different Azure resources (variables\_local.tf)

The input to the module is shown below, the naming module uses these parameters to construct the names.

```ruby
module "sap_namegenerator" {
  source           = "../../terraform-units/modules/sap_namegenerator"
  environment      = var.infrastructure.environment
  location         = var.infrastructure.region
  codename         = lower(try(var.infrastructure.codename, ""))
  random_id        = module.common_infrastructure.random_id
  sap_vnet_name    = local.vnet_sap_name_part
  sap_sid          = local.sap_sid
  db_sid           = local.db_sid
  app_ostype       = local.app_ostype
  anchor_ostype    = local.anchor_ostype
  db_ostype        = local.db_ostype
  db_server_count  = local.db_server_count
  app_server_count = local.app_server_count
  web_server_count = local.webdispatcher_count
  scs_server_count = local.scs_server_count
  app_zones        = local.app_zones
  scs_zones        = local.scs_zones
  web_zones        = local.web_zones
  db_zones         = local.db_zones
  resource_offset  = try(var.options.resource_offset, 0)
}
```

## Naming structure ##

The naming module is used by the 4 deployment types in the automation. 

1. the resources prefixed with **deployer\_** are the names used by the sap\_deployer deployments
2. the resources prefixed with **library\_** are the names used by the sap\_library deployments
3. the resources prefixed with **vnet\_** are the names used by the sap\_landscape deployments
4. the resources prefixed with **sdu**  are the names used by the sap\_system deployments

## Output ##

The output from the module is a data structure containing all the names that will be passed in to the other Terraform modules.

```ruby
output naming {
  value = {
    prefix = {
      DEPLOYER = local.deployer_name
      SDU      = length(var.custom_prefix) > 0 ? var.custom_prefix : local.sdu_name
      VNET     = local.landscape_name
      LIBRARY  = local.library_name
    }
    storageaccount_names = {
      DEPLOYER = local.deployer_storageaccount_name
      SDU      = local.sdu_storageaccount_name
      VNET     = local.landscape_storageaccount_name
      LIBRARY = {
        library_storageaccount_name        = local.library_storageaccount_name
        terraformstate_storageaccount_name = local.terraformstate_storageaccount_name
      }
    }
    keyvault_names = {
      DEPLOYER = {
        private_access = local.deployer_private_keyvault_name
        user_access    = local.deployer_user_keyvault_name
      }
      LIBRARY = {
        private_access = local.library_private_keyvault_name
        user_access    = local.library_user_keyvault_name
      }
      SDU = {
        private_access = local.sdu_private_keyvault_name
        user_access    = local.sdu_user_keyvault_name
      }
      VNET = {
        private_access = local.landscape_private_keyvault_name
        user_access    = local.landscape_user_keyvault_name
      }
    }
    virtualmachine_names = {
      APP_COMPUTERNAME         = local.app_computer_names
      APP_SECONDARY_DNSNAME    = local.app_secondary_dnsnames
      APP_VMNAME               = local.app_server_vm_names
      ANCHOR_COMPUTERNAME      = local.anchor_computer_names
      ANCHOR_SECONDARY_DNSNAME = local.anchor_secondary_dnsnames
      ANCHOR_VMNAME            = local.anchor_vm_names
      ANYDB_COMPUTERNAME       = concat(local.anydb_computer_names, local.anydb_computer_names_ha)
      ANYDB_SECONDARY_DNSNAME  = concat(local.anydb_secondary_dnsnames, local.anydb_secondary_dnsnames_ha)
      ANYDB_VMNAME             = concat(local.anydb_vm_names, local.anydb_vm_names_ha)
      DEPLOYER                 = local.deployer_vm_names
      HANA_COMPUTERNAME        = concat(local.hana_computer_names, local.hana_computer_names_ha)
      HANA_SECONDARY_DNSNAME   = concat(local.hana_secondary_dnsnames, local.hana_secondary_dnsnames_ha)
      HANA_VMNAME              = concat(local.hana_server_vm_names, local.hana_server_vm_names_ha)
      ISCSI_COMPUTERNAME       = local.iscsi_server_names
      OBSERVER_COMPUTERNAME    = local.observer_computer_names
      OBSERVER_VMNAME          = local.observer_vm_names
      SCS_COMPUTERNAME         = local.scs_computer_names
      SCS_SECONDARY_DNSNAME    = local.scs_secondary_dnsnames
      SCS_VMNAME               = local.scs_server_vm_names
      WEB_COMPUTERNAME         = local.web_computer_names
      WEB_SECONDARY_DNSNAME    = local.web_secondary_dnsnames
      WEB_VMNAME               = local.web_server_vm_names
    }

    resource_suffixes = var.resource_suffixes

    separator = local.separator
  }
}
```

## Preparing the Terraform environment ##

1. Create a root folder in your environment, for instance Azure_Deployment
2. Create a folder "Workspaces" under the root folder.
3. Navigate to the sap-hana folder and clone the repository (<https://github.com/Azure/sap-hana>) into it, a folder named sap-hana should be created.
4. Navigate to the folder and checkout the appropriate branch branch
5. Navigate to the ”deploy\terraform\terraform-units\modules” folder
6. Copy the sap_namegenerator folder to a new folder e.g. Contoso_naming, the folder should be created in the workspaces folder.
7. Change the module file(s) to point to the new folder

Open the **deploy\terraform\run\sap\_system\module.tf** file and change the source property for the sap\_namegenerator folder to point to your folder

module "sap\_namegenerator" {
    source        = "../../terraform-units/modules/sap\_namegenerator"

becomes

module "sap\_namegenerator" {
    source        = "../../../../workspaces/Contoso_naming"

Repeat this for the following files

   1. deploy\terraform\bootstrap\sap\_deployer\module.tf
   2. deploy\terraform\bootstrap\sap\_library\module.tf
   3. deploy\terraform\run\sap\_library\module.tf
   4. deploy\terraform\run\sap\_deployer\module.tf

## Changing the Resource group naming logic ##

Open the resourcegroup.tf file in the Contoso_naming folder

```ruby
locals {

  // Resource group naming
  sdu_name = length(var.codename) > 0 ? (
    upper(format("%s-%s-%s_%s-%s", local.env_verified, local.location_short, local.sap_vnet_verified, var.codename, var.sap_sid))) : (
    upper(format("%s-%s-%s-%s", local.env_verified, local.location_short, local.sap_vnet_verified, var.sap_sid))
  )

  deployer_name  = upper(format("%s-%s-%s", local.deployer_env_verified, local.deployer_location_short, local.dep_vnet_verified))
  landscape_name = upper(format("%s-%s-%s", local.landscape_env_verified, local.location_short, local.sap_vnet_verified))
  library_name   = upper(format("%s-%s", local.library_env_verified, local.location_short))

  // Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only. The name must be unique.
  deployer_storageaccount_name       = substr(replace(lower(format("%s%s%sdiag%s", local.deployer_env_verified, local.deployer_location_short, local.dep_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  landscape_storageaccount_name      = substr(replace(lower(format("%s%s%sdiag%s", local.landscape_env_verified, local.location_short, local.sap_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  library_storageaccount_name        = substr(replace(lower(format("%s%ssaplib%s", local.library_env_verified, local.location_short, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  sdu_storageaccount_name            = substr(replace(lower(format("%s%s%sdiag%s", local.env_verified, local.location_short, local.sap_vnet_verified, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)
  terraformstate_storageaccount_name = substr(replace(lower(format("%s%stfstate%s", local.library_env_verified, local.location_short, local.random_id_verified)), "/[^a-z0-9]/", ""), 0, var.azlimits.stgaccnt)

}
```

and implement your naming logic

## Changing the resource suffixes ##

The resource suffixes are implemented in a map in the variables\_local.tf file

```ruby
variable resource_suffixes {
  type        = map(string)
  description = "Extension of resource name"

  default = {
    "admin_nic"           = "-admin-nic"
    "admin_subnet"        = "admin-subnet"
    "admin_subnet_nsg"    = "adminSubnet-nsg"
    "app_alb"             = "app-alb"
    "app_avset"           = "app-avset"
    "app_subnet"          = "app-subnet"
    "app_subnet_nsg"      = "appSubnet-nsg"
    "db_alb"              = "db-alb"
    "db_alb_bepool"       = "dbAlb-bePool"
    "db_alb_feip"         = "dbAlb-feip"
    "db_alb_hp"           = "dbAlb-hp"
    "db_alb_rule"         = "dbAlb-rule_"
    "db_avset"            = "db-avset"
    "db_nic"              = "-db-nic"
    "db_subnet"           = "db-subnet"
    "db_subnet_nsg"       = "dbSubnet-nsg"
    "deployer_rg"         = "-INFRASTRUCTURE"
    "deployer_state"      = "_DEPLOYER.terraform.tfstate"
    "deployer_subnet"     = "_deployment-subnet"
    "deployer_subnet_nsg" = "_deployment-nsg"
    "iscsi_subnet"        = "iscsi-subnet"
    "iscsi_subnet_nsg"    = "iscsiSubnet-nsg"
    "library_rg"          = "-SAP_LIBRARY"
    "library_state"       = "_SAP-LIBRARY.terraform.tfstate"
    "kv"                  = ""
    "msi"                 = "-msi"
    "nic"                 = "-nic"
    "osdisk"              = "-OsDisk"
    "pip"                 = "-pip"
    "ppg"                 = "-ppg"
    "sapbits"             = "sapbits"
    "storage_nic"         = "-storage-nic"
    "storage_subnet"      = "_storage-subnet"
    "storage_subnet_nsg"  = "_storageSubnet-nsg"
    "scs_alb"             = "scs-alb"
    "scs_alb_bepool"      = "scsAlb-bePool"
    "scs_alb_feip"        = "scsAlb-feip"
    "scs_alb_hp"          = "scsAlb-hp"
    "scs_alb_rule"        = "scsAlb-rule_"
    "scs_avset"           = "scs-avset"
    "scs_ers_feip"        = "scsErs-feip"
    "scs_ers_hp"          = "scsErs-hp"
    "scs_ers_rule"        = "scsErs-rule_"
    "scs_scs_rule"        = "scsScs-rule_"
    "sdu_rg"              = ""
    "tfstate"             = "tfstate"
    "vm"                  = ""
    "vnet"                = "-vnet"
    "vnet_rg"             = "-INFRASTRUCTURE"
    "web_alb"             = "web-alb"
    "web_alb_bepool"      = "webAlb-bePool"
    "web_alb_feip"        = "webAlb-feip"
    "web_alb_hp"          = "webAlb-hp"
    "web_alb_inrule"      = "webAlb-inRule"
    "web_avset"           = "web-avset"
    "web_subnet"          = "web-subnet"
    "web_subnet_nsg"      = "webSubnet-nsg"

  }
}

```

Do **not** change the key in the map as it is used by the terraform code, only change the values in the map, for instance if you want to rename the admin nic 

"admin-nic"           = "-admin-nic"

becomes

"admin-nic"           = "YourNicName"

