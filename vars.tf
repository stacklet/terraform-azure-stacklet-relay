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

variable "prefix" {
  type        = string
  description = "A Prefix for all of the generated resources"
  validation {
    condition     = can(regex("^[a-z](-?[a-z0-9]+)*$", var.prefix))
    error_message = "Prefix must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "resource_group_location" {
  type        = string
  description = "Resource Group location for generated resources"
  default     = "East US"
}

variable "event_grid_topic_name" {
  type        = string
  description = "System Topic Name for subscription events if it already exists"
  default     = null
}

variable "event_grid_topic_resource_group" {
  type        = string
  description = "System Topic resource group name for subscription events if it already exists"
  default     = null
}

variable "aws_target_account" {
  type        = string
  description = "AWS Target account for relay, to be provided by Stacklet."
}

variable "aws_target_region" {
  type        = string
  description = "AWS Target region for relay, to be provided by Stacklet."
}

variable "aws_target_role_name" {
  type        = string
  description = "AWS Target role name for relay, to be provided by Stacklet."
}

variable "aws_target_partition" {
  type        = string
  description = "AWS Target partition for relay, to be provided by Stacklet."
  default     = "aws"
}

variable "aws_target_event_bus" {
  type        = string
  description = "AWS Target event bus for relay, to be provided by Stacklet."
}

variable "aws_target_prefix" {
  type        = string
  description = "Deployment prefix for the target Stacklet instance, to be provided by Stacklet."
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources"
  default     = {}
}

variable "event_names" {
  type        = list(string)
  description = "Event Names to filter"
  default = [
    "Microsoft.Resources.ResourceWriteSuccess",
    "Microsoft.Resources.ResourceActionSuccess",
    "Microsoft.Resources.ResourceDeleteSuccess",
  ]
}

variable "azuread_application" {
  type        = string
  description = "Azure AD Application. One per tenant."
  default     = null
}
