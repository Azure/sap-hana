/*
  Description:
  Setup sap library
*/
module "sap_library" {
  source                  = "../../terraform-units/modules/sap_library"
  infrastructure          = var.infrastructure
  storage_account_sapbits = var.storage_account_sapbits
  storage_account_tfstate = var.storage_account_tfstate
  naming                  = module.sap_namegenerator.naming

}

module "sap_namegenerator" {
  source      = "../../terraform-units/modules/sap_namegenerator"
  environment = lower(try(var.infrastructure.landscape, ""))
  location    = try(var.infrastructure.region, "")
  random_id   = random_id.lib-random-id.hex

  //These are not needed for the library
  codename             = ""
  management_vnet_name = ""
  sap_vnet_name        = ""
  sap_sid              = ""
  db_sid               = ""
}

