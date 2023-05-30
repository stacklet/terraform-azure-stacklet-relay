variable "prefix" {
  type        = string
  description = "A Prefix for all of the generated resources"
}

variable "resource_group_location" {
  type        = string
  description = "Resource Group location for generated resoruces"
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

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources"
  default     = {}
}

variable "event_names" {
  type = list(string)
  description = "Event Names to filter"
  default = [
    "Microsoft.Resources.ResourceWriteSuccess",
    "Microsoft.Resources.ResourceActionSuccess",
    "Microsoft.Resources.ResourceDeleteSuccess",
  ]
}
