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
  vnet_mask      = tonumber(split("/", var.vnet_address_space)[1])
  subnet_newbits = var.subnet_prefix_length - local.vnet_mask
}

resource "azurerm_virtual_network" "stacklet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  tags                = local.tags
}

resource "azurerm_subnet" "stacklet_function" {
  name                 = "${var.prefix}-function-subnet"
  resource_group_name  = azurerm_resource_group.stacklet_rg.name
  virtual_network_name = azurerm_virtual_network.stacklet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, local.subnet_newbits, 1)]

  # Enable service endpoint for Storage to allow access to Storage Account
  service_endpoints = ["Microsoft.Storage"]

  # Delegate subnet to Azure Functions for VNet integration
  delegation {
    name = "function-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "stacklet_private_endpoints" {
  name                 = "${var.prefix}-pe-subnet"
  resource_group_name  = azurerm_resource_group.stacklet_rg.name
  virtual_network_name = azurerm_virtual_network.stacklet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, local.subnet_newbits, 2)]

  # Enable service endpoint for Storage
  service_endpoints = ["Microsoft.Storage"]
}
