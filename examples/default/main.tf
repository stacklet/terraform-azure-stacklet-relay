# The onboarding path Stacklet documents: the module creates an Event Grid
# Subscription System Topic for the subscription it runs against.
#
# The values under "Stacklet provided values" come from the Stacklet deployment
# the relay sends events to. A real deployment hands them to the customer in a
# generated copy of this file.

# The caller declares the Terraform and provider versions, so these match what
# the module supports. A module change that raises either floor past these
# conflicts here rather than reaching a caller who copied this file.
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

  # Omitted so this reads from ARM_SUBSCRIPTION_ID. Set it here instead to pin
  # the example to one subscription.
}

module "azure-relay" {
  source = "../.."

  prefix                  = "example"
  resource_group_location = "East US"

  # Stacklet provided values
  aws_target_partition = "aws"
  aws_target_account   = "123456789012"
  aws_target_region    = "us-east-1"
  aws_target_role_name = "example-azure-relay"
  aws_target_event_bus = "example-azure-relay"
  aws_target_prefix    = "example"
}
