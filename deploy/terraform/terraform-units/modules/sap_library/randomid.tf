# Generates random text for boot diagnostics storage account name
resource "random_id"  "post_fix" {
  keepers = {
    // Generate a new id only when a new resource group is defined
    resource_group = local.rg_exists ? data.azurerm_resource_group.library[0].name : azurerm_resource_group.library[0].name
  }
  byte_length = 4
}
 