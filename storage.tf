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
  network_rules {
    default_action = "Allow"
    bypass = null
  }

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

# Update storage account network settings to make it private after function app is deployed.
# This ensures the function app code can be uploaded to the storage account before we lock it
# down, and then the actual function run can still occur due to the bypass setting.
resource "azapi_update_resource" "stacklet_storage_network" {
  type        = "Microsoft.Storage/storageAccounts@2023-01-01"
  resource_id = azurerm_storage_account.stacklet.id

  body = {
    properties = {
      # Disable public network access - only private endpoints allowed
      publicNetworkAccess = "Disabled"
      # Network rules to control access
      networkAcls = {
        defaultAction = "Deny"
        # Allow Azure services (like Function Apps) to access
        bypass = "AzureServices"
      }
    }
  }

  depends_on = [azurerm_linux_function_app.stacklet]

  # Ensure that the update is applied if the public network access is enabled again (which will
  # happen on every update because the azurerm_storage_account resource will always make it
  # public to allow the function app to upload any new function code).
  lifecycle {
    replace_triggered_by = [
      azurerm_storage_account.stacklet.public_network_access_enabled
    ]
  }
}
