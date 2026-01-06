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
  # Storage account name must be 3-24 characters and cannot contain hyphens.
  prefix_no_hyphens = replace(var.prefix, "-", "")
}

resource "random_string" "storage_account_suffix" {
  special = false
  length  = 24
  lower   = true
  upper   = false
}

resource "azurerm_storage_account" "stacklet" {
  # there is a global uniqueness constraint on storage account names, as well as a length requirement of 3-24 characters
  name                     = substr("${local.prefix_no_hyphens}${random_string.storage_account_suffix.result}", 0, 23)
  resource_group_name      = azurerm_resource_group.stacklet_rg.name
  location                 = azurerm_resource_group.stacklet_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable public network access temporarily to allow the function app to upload the function code.
  # Note: This will always trigger a change on update because the azapi_update_resource will set it to false
  # after the function app is deployed, but we need to set it to true again temporarily to allow the function
  # app to upload any new function code.
  public_network_access_enabled = true

  tags = local.tags
}


# Using azapi provider to create storage queue via ARM API (control plane)
# This avoids the need for Terraform to access storage data plane APIs
resource "azapi_resource" "stacklet_queue" {
  type      = "Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01"
  name      = "${azurerm_storage_account.stacklet.name}-queue"
  parent_id = "${azurerm_storage_account.stacklet.id}/queueServices/default"

  body = {
    properties = {
      metadata = {}
    }
  }

  depends_on = [azurerm_storage_account.stacklet]
}

# Create private endpoint for storage queue service
resource "azurerm_private_endpoint" "stacklet_storage_queue" {
  name                = "${var.prefix}-storage-queue-pe"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  subnet_id           = azurerm_subnet.stacklet_private_endpoints.id

  private_service_connection {
    name                           = "${var.prefix}-storage-queue-psc"
    private_connection_resource_id = azurerm_storage_account.stacklet.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_queue.id]
  }

  depends_on = [azurerm_linux_function_app.stacklet]
  tags       = local.tags
}

# Create private endpoint for storage blob service
resource "azurerm_private_endpoint" "stacklet_storage_blob" {
  name                = "${var.prefix}-storage-blob-pe"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  subnet_id           = azurerm_subnet.stacklet_private_endpoints.id

  private_service_connection {
    name                           = "${var.prefix}-storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.stacklet.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  depends_on = [azurerm_linux_function_app.stacklet]
  tags       = local.tags
}

# Create private endpoint for storage table service
resource "azurerm_private_endpoint" "stacklet_storage_table" {
  name                = "${var.prefix}-storage-table-pe"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  subnet_id           = azurerm_subnet.stacklet_private_endpoints.id

  private_service_connection {
    name                           = "${var.prefix}-storage-table-psc"
    private_connection_resource_id = azurerm_storage_account.stacklet.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_table.id]
  }

  depends_on = [azurerm_linux_function_app.stacklet]
  tags       = local.tags
}

# Create private DNS zones for storage services
resource "azurerm_private_dns_zone" "storage_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "storage_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  tags                = local.tags
}

# Link private DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_queue" {
  name                  = "${var.prefix}-storage-queue-dns-link"
  resource_group_name   = azurerm_resource_group.stacklet_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_queue.name
  virtual_network_id    = azurerm_virtual_network.stacklet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "${var.prefix}-storage-blob-dns-link"
  resource_group_name   = azurerm_resource_group.stacklet_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.stacklet.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_table" {
  name                  = "${var.prefix}-storage-table-dns-link"
  resource_group_name   = azurerm_resource_group.stacklet_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_table.name
  virtual_network_id    = azurerm_virtual_network.stacklet.id
  registration_enabled  = false
  tags                  = local.tags
}

# Grant Storage Queue Data Contributor role to the function app's managed identity
resource "azurerm_role_assignment" "function_storage_queue" {
  scope                = azurerm_storage_account.stacklet.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.stacklet_identity.principal_id
}

# Grant Storage Blob Data Contributor role for function runtime files and packages
resource "azurerm_role_assignment" "function_storage_blob" {
  scope                = azurerm_storage_account.stacklet.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.stacklet_identity.principal_id
}

# Grant Storage Account Contributor role for general storage operations
resource "azurerm_role_assignment" "function_storage_account" {
  scope                = azurerm_storage_account.stacklet.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.stacklet_identity.principal_id
}

# Update storage account network settings to make it private after function app is deployed.
# This ensures the function app code can be uploaded to the storage account before we lock it
# down, and then the actual function can access it via the vnet.
resource "azapi_update_resource" "stacklet_storage_network" {
  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = azurerm_storage_account.stacklet.id

  body = {
    properties = {
      # Disable public network access - only private endpoints allowed
      publicNetworkAccess = "Disabled"
      networkAcls = {
        defaultAction = "Deny"
      }
    }
  }

  depends_on = [
    azurerm_linux_function_app.stacklet,
    azurerm_private_endpoint.stacklet_storage_queue,
    azurerm_private_endpoint.stacklet_storage_blob,
    azurerm_private_endpoint.stacklet_storage_table
  ]

  # Ensure that the update is applied if the public network access is enabled again (which will
  # happen on every update because the azurerm_storage_account resource will always make it
  # public to allow the function app to upload any new function code).
  lifecycle {
    replace_triggered_by = [
      azurerm_storage_account.stacklet.public_network_access_enabled
    ]
  }
}
