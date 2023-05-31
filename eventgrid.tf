locals {
  event_grid_topic = var.event_grid_topic_name != null ? data.azurerm_eventgrid_system_topic.azure_rm_events[0] : azurerm_eventgrid_system_topic.azure_rm_events[0]

  event_grid_topic_name           = local.event_grid_topic.name
  event_grid_topic_resource_group = local.event_grid_topic.resource_group_name
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
}

resource "azurerm_eventgrid_system_topic_event_subscription" "azure_rm_event_subscription" {
  name                  = "${var.prefix}-azure-rm-subscription"
  system_topic          = local.event_grid_topic_name
  resource_group_name   = local.event_grid_topic_resource_group
  event_delivery_schema = "CloudEventSchemaV1_0"

  storage_queue_endpoint {
    storage_account_id = azurerm_storage_account.stacklet.id
    queue_name         = azurerm_storage_queue.stacklet.name
  }

  included_event_types = var.event_names
}
