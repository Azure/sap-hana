resource "azuread_application" "workload" {
  provider        = azuread.fencing
  count           = var.create_spn ? 1 : 0
  display_name    = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_spn)
  identifier_uris = [format("api://%s%s%s-application", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_spn)]

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Admins can manage roles and perform all task actions"
    display_name         = "Admin"
    is_enabled           = true
    value                = "admin"
  }


  web {
    homepage_url  = format("https://%s%s%s.net", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_spn)
    logout_url    = format("https://%s%s%s.net/logout", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_spn)
    redirect_uris = [format("https://%s%s%s.net/account", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_spn)]

    implicit_grant {
      access_token_issuance_enabled = true
    }
  }
}


resource "azuread_service_principal" "workload" {
  provider                     = azuread.fencing
  count                        = var.create_spn ? 1 : 0
  application_id               = azuread_application.workload[0].application_id
  app_role_assignment_required = false
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "workload" {
  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

resource "azuread_application_password" "workload" {
  provider              = azuread.fencing
  count                 = var.create_spn ? 1 : 0
  application_object_id = azuread_application.workload[0].object_id
  value                 = random_password.workload.result
}

resource "azurerm_role_assignment" "workload" {
  count                = var.create_spn ? 1 : 0
  provider             = azurerm.fencing
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = azurerm_role_definition.fencing_role[0].name
  principal_id         = azuread_service_principal.workload[0].id
}

data "azurerm_subscription" "primary" {
  provider = azurerm.fencing

}

resource "azurerm_role_definition" "fencing_role" {
  count       = var.create_spn ? 1 : 0
  provider    = azurerm.fencing
  name        = format("Linux Fence Agent Role %s", local.prefix)
  description = "Allows to power-off and start virtual machines"
  scope       = data.azurerm_subscription.primary.id

  permissions {
    actions = ["Microsoft.Compute/*/read",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]

}

## Fencing agent

resource "azurerm_key_vault_secret" "fencing_spn_id" {
  count        = var.create_spn ? 1 : 0
  provider     = azurerm.fencing
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_id), "/[^A-Za-z0-9-]/", "")
  value        = azuread_service_principal.workload[0].id
  key_vault_id = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "fencing_agent_pwd" {
  count        = var.create_spn ? 1 : 0
  provider     = azurerm.fencing
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_pwd), "/[^A-Za-z0-9-]/", "")
  value        = random_password.workload.result
  key_vault_id = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "fencing_agent_tenant" {
  provider     = azurerm.fencing
  count        = var.create_spn ? 1 : 0
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_tenant), "/[^A-Za-z0-9-]/", "")
  value        = data.azurerm_subscription.primary.tenant_id
  key_vault_id = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "fencing_agent_sub" {
  count        = var.create_spn ? 1 : 0
  provider     = azurerm.fencing
  content_type = ""
  name         = replace(format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.fencing_agent_sub), "/[^A-Za-z0-9-]/", "")
  value        = data.azurerm_subscription.primary.id
  key_vault_id = local.user_kv_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}
