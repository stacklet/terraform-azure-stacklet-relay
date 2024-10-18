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

resource "random_string" "storage_account_suffix" {
  special = false
  length  = 24
  lower   = true
  upper   = false
}

resource "azurerm_storage_account" "stacklet" {
  # there is a global uniquness constraing on storage account names, as well as a length requirement of 3-24 characters
  name                     = substr("${var.prefix}${random_string.storage_account_suffix.result}", 0, 23)
  resource_group_name      = azurerm_resource_group.stacklet_rg.name
  location                 = azurerm_resource_group.stacklet_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_queue" "stacklet" {
  name                 = "${azurerm_storage_account.stacklet.name}-queue"
  storage_account_name = azurerm_storage_account.stacklet.name
}
