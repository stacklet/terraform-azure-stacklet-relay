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
  event_grid_topic = var.event_grid_topic_name != null ? data.azurerm_eventgrid_system_topic.azure_rm_events[0] : azurerm_eventgrid_system_topic.azure_rm_events[0]

  event_grid_topic_name           = local.event_grid_topic.name
  event_grid_topic_resource_group = local.event_grid_topic.resource_group_name

  # A supplied topic may already carry user-assigned identities that another
  # event subscription delivers under. Adding "SystemAssigned" to the type
  # string replaces it, so carry any existing ones through the patch.
  supplied_topic_identity_ids = try(data.azurerm_eventgrid_system_topic.azure_rm_events[0].identity[0].identity_ids, [])

  event_grid_topic_principal_id = (
    var.event_grid_topic_name != null
    ? azapi_update_resource.event_grid_topic_identity[0].output.principal_id
    : azurerm_eventgrid_system_topic.azure_rm_events[0].identity[0].principal_id
  )
}

data "azurerm_eventgrid_system_topic" "azure_rm_events" {
  count               = var.event_grid_topic_name != null ? 1 : 0
  name                = var.event_grid_topic_name
  resource_group_name = var.event_grid_topic_resource_group
}

resource "azurerm_eventgrid_system_topic" "azure_rm_events" {
  count                  = var.event_grid_topic_name == null ? 1 : 0
  name                   = "${var.prefix}-azure-rm-events"
  resource_group_name    = azurerm_resource_group.stacklet_rg.name
  location               = "Global"
  source_arm_resource_id = data.azurerm_subscription.current.id
  topic_type             = "Microsoft.Resources.Subscriptions"
  tags                   = local.tags

  # Event Grid signs its queue writes with this identity. It must be
  # system-assigned: Azure rejects a user-assigned identity for delivery to a
  # storage queue.
  identity {
    type = "SystemAssigned"
  }
}

# A supplied topic is a data source, which cannot grow an identity, so patch one
# onto it. The module does not own the topic, and this is the one field it
# changes. Delivery authentication is a per-subscription setting, so every other
# event subscription on the topic keeps whatever it had.
resource "azapi_update_resource" "event_grid_topic_identity" {
  count       = var.event_grid_topic_name != null ? 1 : 0
  type        = "Microsoft.EventGrid/systemTopics@2025-02-15"
  resource_id = data.azurerm_eventgrid_system_topic.azure_rm_events[0].id

  body = {
    identity = merge(
      {
        type = length(local.supplied_topic_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
      },
      length(local.supplied_topic_identity_ids) > 0 ? {
        userAssignedIdentities = { for id in local.supplied_topic_identity_ids : id => {} }
      } : {},
    )
  }

  response_export_values = {
    principal_id = "identity.principalId"
  }
}

resource "azurerm_role_assignment" "event_grid_queue_sender" {
  scope                = azurerm_storage_account.stacklet.id
  role_definition_name = "Storage Queue Data Message Sender"
  principal_id         = local.event_grid_topic_principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "azure_rm_event_subscription" {
  name                  = "${var.prefix}-azure-rm-subscription"
  system_topic          = local.event_grid_topic_name
  resource_group_name   = local.event_grid_topic_resource_group
  event_delivery_schema = "CloudEventSchemaV1_0"

  delivery_identity {
    type = "SystemAssigned"
  }

  storage_queue_endpoint {
    storage_account_id = azurerm_storage_account.stacklet.id
    queue_name         = azapi_resource.stacklet_queue.name
  }

  included_event_types = var.event_names

  # ARM accepts the subscription without checking that the identity can write to
  # the queue, so an ordering gap here does not fail the apply, it just drops
  # events. Entra can still take a few minutes to publish the grant after
  # Terraform returns, which the subscription's default retry policy covers: 30
  # attempts over 24 hours.
  depends_on = [azurerm_role_assignment.event_grid_queue_sender]
}
