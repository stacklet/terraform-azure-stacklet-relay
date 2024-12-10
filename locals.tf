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

locals {
  object_id   = azurerm_user_assigned_identity.stacklet_identity.principal_id
  app_role_id = var.azuread_application == null ? random_uuid.app_role_uuid.id : data.azuread_application.stacklet_application[0].app_role_ids.AssumeRoleWithWebIdentity
  resource_id = local.azuread_service_principal.object_id

  audience = "api://stacklet/provider/azure/${var.aws_target_prefix}"

  _tags = {
    "stacklet:app" : "Azure Relay"
  }

  tags = merge(local._tags, var.tags)

  azuread_application       = var.azuread_application == null ? azuread_application.stacklet_application[0] : data.azuread_application.stacklet_application[0]
  azuread_service_principal = var.azuread_application == null ? azuread_service_principal.stacklet_sp[0] : data.azuread_service_principal.stacklet_sp[0]
}
