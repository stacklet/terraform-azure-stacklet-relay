data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

data "azurerm_subscription" "current" {}


data "azurerm_role_definition" "builtin" {
  name = "Contributor"
}

resource "random_uuid" "app_role_uuid" {}

resource "azurerm_resource_group" "stacklet_rg" {
  name     = var.prefix
  location = var.resource_group_location
}

resource "azurerm_user_assigned_identity" "stacklet_identity" {
  location            = azurerm_resource_group.stacklet_rg.location
  name                = "${var.prefix}-identity"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
}

resource "azuread_application" "stacklet_application" {
  display_name    = "${var.prefix}-application"
  identifier_uris = [local.audience]
  owners = [
    data.azuread_client_config.current.object_id,
  ]

  app_role {
    allowed_member_types = ["Application"]
    description          = "AssumeRoleWithWebIdentity is the claim that will be sent in token"
    display_name         = "AssumeRole"
    enabled              = true
    id                   = random_uuid.app_role_uuid.result
    value                = "AssumeRoleWithWebIdentity"
  }

  feature_tags {
    enterprise = true
  }
}

resource "azuread_service_principal" "stacklet_sp" {
  application_id               = azuread_application.stacklet_application.application_id
  app_role_assignment_required = true
  owners = [
    data.azuread_client_config.current.object_id,
  ]

  feature_tags {
    enterprise = true
  }
}

resource "azurerm_role_assignment" "stacklet" {
  count = 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = var.role
  principal_id         = azuread_application.stacklet_application.object_id
}

resource "null_resource" "stacklet" {
  depends_on = [azuread_application.stacklet_application, azuread_service_principal.stacklet_sp]
  provisioner "local-exec" {
    command = <<EOF
      az rest \
        --method POST \
        --uri https://graph.microsoft.com/v1.0/servicePrincipals/${local.object_id}/appRoleAssignments \
        --headers 'Content-Type=application/json' \
        --body '{"principalId": "${local.object_id}", "resourceId": "${local.resource_id}", "appRoleId": "${local.app_role_id}"}'
    EOF
  }
}
