# Copyright 2024 Stacklet
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

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
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "stacklet_identity" {
  location            = azurerm_resource_group.stacklet_rg.location
  name                = "${var.prefix}-identity"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  tags                = local.tags
}

resource "azuread_application" "stacklet_application" {
  count           = var.azuread_application == null ? 1 : 0
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

data "azuread_application" "stacklet_application" {
  count        = var.azuread_application == null ? 0 : 1
  display_name = var.azuread_application
}

resource "azuread_service_principal" "stacklet_sp" {
  count                        = var.azuread_application == null ? 1 : 0
  client_id                    = local.azuread_application.client_id
  app_role_assignment_required = true
  owners = [
    data.azuread_client_config.current.object_id,
  ]

  feature_tags {
    enterprise = true
  }
}

data "azuread_service_principal" "stacklet_sp" {
  count        = var.azuread_application == null ? 0 : 1
  display_name = var.azuread_application
}

resource "azuread_app_role_assignment" "stacklet_app_role_assignment" {
  principal_object_id = azurerm_user_assigned_identity.stacklet_identity.principal_id
  resource_object_id  = local.azuread_service_principal.object_id
  app_role_id         = local.app_role_id
}
