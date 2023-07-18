locals {
  object_id   = azurerm_user_assigned_identity.stacklet_identity.principal_id
  app_role_id = random_uuid.app_role_uuid.id
  resource_id = local.azuread_service_principal.id

  audience = "api://stacklet/provider/azure/${var.prefix}"

  _tags = {
    "stacklet:app" : "Azure Relay"
  }

  tags = merge(local._tags, var.tags)

  azuread_application = var.azuread_application == null ? azuread_application.stacklet_application[0] : data.azuread_application.stacklet_application[0]
  azuread_service_principal = var.azuread_application == null ? azuread_service_principal.stacklet_sp[0] : data.azuread_service_principal.stacklet_sp[0]
}
