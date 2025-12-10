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

  # Disable public network access - only private endpoints allowed
  public_network_access_enabled = false

  # Network rules to control access
  network_rules {
    default_action = "Deny"
    # Allow Azure services (like Function Apps) to access
    bypass = ["AzureServices"]
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
