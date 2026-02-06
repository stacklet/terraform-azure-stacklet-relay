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
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.56.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=2.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.6.2"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=3.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.8.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">=2.7.1"
    }
  }
  required_version = "~> 1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = !var.force_delete_resource_group
    }
  }

  subscription_id = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}
