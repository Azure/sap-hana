# Style note: Use fuller module/variable names for internal implementation

module "resource_group_name" {
  source   = "gsoft-inc/naming/azurerm//modules/networking/load_balancer"
  name     = local.net
  prefixes = [local.env, local.loc]
  suffixes = ["INFRASTRUCTURE"]
}

module "load_balancer_name" {
  source   = "gsoft-inc/naming/azurerm//modules/networking/load_balancer"
  name     = local.short_name
  prefixes = [local.env, local.loc, local.net, local.cnm, local.trk, local.sid]
  suffixes = ["alb"]
}
