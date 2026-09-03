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

# Note: Unlike AWS provider, Azure provider (azurerm) does not support
# default_tags configuration. We use local.tags instead to achieve
# consistent tagging across all resources.
# Providers are constrained to the majors this module is known to work against.
# In particular, azurerm 5.x renames or removes arguments used here on
# azurerm_eventgrid_system_topic, azurerm_subnet and
# azurerm_private_dns_zone_virtual_network_link, so the module does not even
# validate against it. Do not widen these without testing the new major.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.56"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.8"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
  required_version = ">= 1.9.0, < 2.0.0"
}


