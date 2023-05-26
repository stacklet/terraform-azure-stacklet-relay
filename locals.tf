locals {
  object_id   = azurerm_user_assigned_identity.stacklet_identity.principal_id
  app_role_id = random_uuid.app_role_uuid.id
  resource_id = azuread_service_principal.stacklet_sp.id

  audience = "api://stacklet${var.prefix}"
}
