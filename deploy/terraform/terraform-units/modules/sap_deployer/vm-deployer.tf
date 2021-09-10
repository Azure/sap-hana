/*
Description:

  The deployer will be used to run Terraform and Ansible tasks to create the SAP environments

  Define 0..n Deployer(s).
*/

data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

// Public IP addresse and nic for Deployer
resource "azurerm_public_ip" "deployer" {
  count               = local.enable_deployer_public_ip ? length(local.deployers) : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.deployers[count.index].name, local.resource_suffixes.pip)
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "deployer" {
  count               = length(local.deployers)
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, local.deployers[count.index].name, local.resource_suffixes.nic)
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = (local.enable_deployers && !local.sub_mgmt_exists) ? azurerm_subnet.subnet_mgmt[0].id : data.azurerm_subnet.subnet_mgmt[0].id
    private_ip_address            = local.deployers[count.index].use_DHCP ? "" : local.deployers[count.index].private_ip_address
    private_ip_address_allocation = local.deployers[count.index].use_DHCP ? "Dynamic" : "Static"
    public_ip_address_id          = local.enable_deployer_public_ip ? azurerm_public_ip.deployer[count.index].id : ""
  }
}

// User defined identity for all Deployer, assign contributor to the current subscription
resource "azurerm_user_assigned_identity" "deployer" {
  resource_group_name = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  name                = format("%s%s", local.prefix, local.resource_suffixes.msi)
}

# // Add role to be able to deploy resources
resource "azurerm_role_assignment" "sub_contributor" {
  count                = var.assign_subscription_permissions ? 1 : 0
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deployer.principal_id
}

// Linux Virtual Machine for Deployer
resource "azurerm_linux_virtual_machine" "deployer" {
  count                           = length(local.deployers)
  name                            = format("%s%s%s%s", local.prefix, var.naming.separator, local.deployers[count.index].name, local.resource_suffixes.vm)
  computer_name                   = local.deployers[count.index].name
  resource_group_name             = local.rg_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                        = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  network_interface_ids           = [azurerm_network_interface.deployer[count.index].id]
  size                            = local.deployers[count.index].size
  admin_username                  = local.deployers[count.index].authentication.username
  admin_password                  = lookup(local.deployers[count.index].authentication, "password", null)
  disable_password_authentication = local.deployers[count.index].authentication.type != "password" ? true : false

  os_disk {
    name                   = format("%s%s%s%s", local.prefix, var.naming.separator, local.deployers[count.index].name, local.resource_suffixes.osdisk)
    caching                = "ReadWrite"
    storage_account_type   = local.deployers[count.index].disk_type
    disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
  }

  source_image_id = local.deployers[count.index].os.source_image_id != "" ? local.deployers[count.index].os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.deployers[count.index].os.source_image_id == "" ? 1 : 0)
    content {
      publisher = local.deployers[count.index].os.publisher
      offer     = local.deployers[count.index].os.offer
      sku       = local.deployers[count.index].os.sku
      version   = local.deployers[count.index].os.version
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.deployer.id]
  }

  dynamic "admin_ssh_key" {
    for_each = range(local.deployers[count.index].authentication.sshkey.public_key == null ? 0 : 1)
    content {
      username   = local.deployers[count.index].authentication.username
      public_key = local.deployers[count.index].authentication.sshkey.public_key
    }
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.deployer[0].primary_blob_endpoint
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.deployers[count.index].authentication.username
    private_key = local.deployers[count.index].authentication.type == "key" ? local.deployers[count.index].authentication.sshkey.private_key : null
    password    = lookup(local.deployers[count.index].authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  tags = local.tags
}
