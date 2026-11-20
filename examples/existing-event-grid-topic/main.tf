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

# For a subscription that already has an Event Grid Subscription System Topic.
# Azure allows one per subscription for subscription-level events, so wherever
# one already exists, whatever created it, the module attaches to it rather
# than creating a second.
#
# event_grid_topic_name and event_grid_topic_resource_group below are required
# together. Omit both and the module creates the topic, which is the default
# example. Supplying one needs credentials that can write to it, because the
# module adds a system-assigned identity, and a later destroy leaves that
# identity behind. See "Bring your own system topic" in the module README.
#
# The values under "Stacklet provided values" come from the Stacklet deployment
# the relay sends events to. A real deployment hands them to the customer in a
# generated copy of this file.

# The caller declares the Terraform and provider versions, as a real caller
# would, matching what the module supports. Terraform intersects these with the
# module's own constraints, so a module change that moves azurerm to a new major
# conflicts here rather than reaching a caller who copied this file. An in-major
# floor raise still resolves, so this is a backstop, not a tripwire.
terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.56"
    }
  }
}

provider "azurerm" {
  features {}

  # subscription_id is omitted so this reads ARM_SUBSCRIPTION_ID. Set it here
  # instead to pin this to one subscription.
}

# azapi is not declared here: like azurerm above, it reads ARM_SUBSCRIPTION_ID
# from the environment, and the module's own required_providers governs its
# version. Declare it explicitly when you pin subscriptions or use provider
# aliases, as the module README's usage shows.

module "azure_relay" {
  # Relative so this repo's own lint validates against the working tree. A real
  # caller sets source = "stacklet/stacklet-relay/azure" and pins version; see
  # Versioning in the module README.
  source = "../.."

  prefix                  = "example"
  resource_group_location = "East US"

  event_grid_topic_name           = "example-topic"
  event_grid_topic_resource_group = "example-topic-rg"

  # Stacklet provided values
  aws_target_partition = "aws"
  aws_target_account   = "123456789012"
  aws_target_region    = "us-east-1"
  aws_target_role_name = "example-azure-relay"
  aws_target_event_bus = "example-azure-relay"
  aws_target_prefix    = "example"
}
