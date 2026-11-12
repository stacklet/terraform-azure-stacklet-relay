# terraform-azure-stacklet-relay

Azure event relay for Stacklet customers.

This module forwards Azure resource events to Stacklet's platform in AWS, so
that policies act on changes in your subscription as they happen. It captures
subscription-level events with Event Grid, queues them, and runs an Azure
Function that forwards them to an EventBridge bus in Stacklet's account.

## Overview

This module creates the following in a single subscription:

* a Resource Group holding everything below
* an Event Grid system topic for subscription-level events, or an attachment to
  one you already have
* a Storage Account and queue, holding events until the function reads them
* a Virtual Network and private endpoints, keeping the function's traffic off
  the public internet
* a Linux Function App running the Python relay, with Application Insights
* a user-assigned identity for the function app
* an Entra ID application and service principal for the cross-cloud
  authentication, unless you pass an existing one through
  `azuread_application`. Azure wants a single application per tenant, so a
  second subscription reuses the first one's

Apply it once for each subscription whose events you want in Stacklet.

## Prerequisites

**Owner on the subscription**, or Contributor paired with User Access
Administrator. The module assigns roles on the Storage Account it creates, which
Contributor alone cannot do.

**Write access to your own system topic**, if you set `event_grid_topic_name` to
supply one. The module adds a managed identity to that topic. See
[Bring your own system topic](#bring-your-own-system-topic).

**`azurerm` and `azapi` providers configured by the calling module**, with the
target subscription set on each. This module declares no provider configuration
of its own. The `azuread` provider configures itself from your Azure
credentials.

Credentials come from the standard Azure authentication chain. For local use,
run `az login`. For automated deployments, set `ARM_CLIENT_ID`,
`ARM_CLIENT_SECRET` and `ARM_TENANT_ID`, or set `client_id`, `client_secret` and
`tenant_id` on the provider blocks.

## Usage

The module is published to the
[Terraform Registry](https://registry.terraform.io/modules/stacklet/stacklet-relay/azure).
Set `source` to the registry address and pin `version` to a release, then fill
in the inputs. See [Versioning](#versioning) for the constraint to pin with.

### Standalone deployment

The common case, deploying the relay directly into a single subscription:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "your-subscription-id"
}

provider "azapi" {
  subscription_id = "your-subscription-id"
}

module "azure_relay" {
  source  = "stacklet/stacklet-relay/azure"
  version = "~> 0.1.0"

  prefix               = "your-prefix"
  aws_target_account   = "123456789012"
  aws_target_region    = "us-east-1"
  aws_target_role_name = "your-prefix-azure-relay"
  aws_target_event_bus = "your-prefix-azure-relay"
  aws_target_prefix    = "your-prefix"
}
```

### Embedded in a larger root module

If your root module manages multiple Azure subscriptions simultaneously
(e.g. a management subscription and a workload subscription), use provider
aliases and pass them explicitly via `providers`:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "management-subscription-id"
}

provider "azurerm" {
  alias           = "workload"
  features {}
  subscription_id = "workload-subscription-id"
}

provider "azapi" {
  alias           = "workload"
  subscription_id = "workload-subscription-id"
}

module "azure_relay" {
  source  = "stacklet/stacklet-relay/azure"
  version = "~> 0.1.0"

  providers = {
    azurerm = azurerm.workload
    azuread = azuread
    azapi   = azapi.workload
  }

  prefix               = "your-prefix"
  aws_target_account   = "123456789012"
  aws_target_region    = "us-east-1"
  aws_target_role_name = "your-prefix-azure-relay"
  aws_target_event_bus = "your-prefix-azure-relay"
  aws_target_prefix    = "your-prefix"
}
```

### Bring your own system topic

Azure allows one system topic per subscription for subscription-level events, so
a subscription that already has one must pass it to the module through
`event_grid_topic_name` and `event_grid_topic_resource_group`. Running against a
supplied topic needs credentials that can write to it, on top of the permissions
under [Prerequisites](#prerequisites).

The module adds a system-assigned identity to your topic. That identity is the
only field it changes: any user-assigned identities already on the topic stay,
and other event subscriptions on the topic keep the authentication they had.

A later `terraform destroy` leaves that identity behind, because Terraform cannot
remove a field from a resource it does not own. Remove it by hand if you want the
topic exactly as it was.

**If you manage the supplied topic in your own Terraform, add the
system-assigned identity there too.** Otherwise the two configurations take
turns adding and removing it, and event delivery stops whenever yours wins.

## Versioning

`version` takes the usual constraint syntax. This module is pre-1.0, and on a
0.x line a minor release is where it ships breaking changes, so pin at the
patch level: `~> 0.1.0` accepts `0.1.1` and later patches and holds at `0.2.0`.
Read the release notes before moving to a new minor.

## Upgrade notes

### Upgrading to 0.1.1

Version 0.1.1 moved Event Grid's queue delivery onto a managed identity. One
`terraform apply` upgrades a running deployment, and the event subscription does
not need recreating.

If you supply your own system topic, the apply now writes to that topic rather
than only reading it, so your credentials need write access to it. That is the
only permission this release adds. See [Prerequisites](#prerequisites).

Your plan will add a system-assigned identity to the system topic, create an
`azurerm_role_assignment`, and add `delivery_identity` to the event
subscription. Delivery moves onto the identity within a few minutes of the apply
returning. See
[Confirming that Event Grid delivers under the identity](#confirming-that-event-grid-delivers-under-the-identity).

### Provider configuration changes

The following breaking changes were made to align with Terraform's
recommended practice of not declaring provider configurations in reusable
modules:

- `subscription_id` input variable removed: set `subscription_id` directly
  on your `azurerm` and `azapi` provider blocks instead
- `force_delete_resource_group` input variable removed: to allow deletion
  of a non-empty resource group, set
  `prevent_deletion_if_contains_resources = false` in the `features {}` block
  of your `azurerm` provider

Those changes need nothing from your deployed infrastructure. On your next
`terraform plan` after moving `source` to the registry address and setting
`version`, you should see 0 resource changes from them.

## Troubleshooting

### Event delivery stops, and nothing reports a failure

Something in your tenant has most likely removed one of the two settings that
Event Grid needs to reach the queue: the trusted-services exception on the
Storage Account, which lets it onto the network, or the
`Storage Queue Data Message Sender` assignment on the relay's system topic
identity, which lets it write. Losing either one stops delivery the same way.
Terraform still applies and the function app still reports healthy. The signals
are the queue that stops filling and Event Grid's delivery-failure count, which
climbs as it retries.

Run `terraform apply` again. It restores both. A policy that keeps stripping
either one strips it again after each apply, so fix the policy rather than
re-applying.

### A failed apply leaves the Storage Account open to the internet

An apply opens the account briefly so the function app can upload its code, then
closes it again at the end of a successful run. A run that fails in between
leaves it open. Apply again, and confirm that the account is closed.

### Confirming that Event Grid delivers under the identity

Read the Storage Account's `Transactions` metric split by the `Authentication`
dimension. `OAuth` means the managed identity carries delivery. `SAS` means the
trusted-service path still does.

```
$ az monitor metrics list --resource "<storage-account-id>/queueServices/default" \
    --metrics Transactions --filter "Authentication eq '*' and ApiName eq '*'" \
    --aggregation Total --interval PT1M -o table
```

## How it works

Event Grid captures the subscription-level events named in `event_names` and
writes them to the Storage Queue in CloudEvents 1.0 format. The Function App,
running Python on a Linux App Service Plan, triggers on that queue. For each
event it exchanges its managed identity token for AWS credentials through
`AssumeRoleWithWebIdentity`, then puts the event on the EventBridge bus in
Stacklet's account.

### Reaching the queue

The function app reads the queue over a private endpoint. Event Grid cannot use
one, so it delivers over Azure's trusted-services exception. That exception is
Azure's blanket setting for the whole trusted-services list, so any resource of
a trusted type in your tenant can reach the account's public endpoint. Reaching
it is not using it: every request still needs a valid credential or role
assignment.

Event Grid signs each queue write with a system-assigned managed identity on the
system topic, which holds the `Storage Queue Data Message Sender` role on the
Storage Account. The account records those writes as `OAuth`. The exception
opens the network, and the identity and its role decide whether Azure allows the
write.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.0, < 2.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.7.1, < 3.0.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.8.0, < 3.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 3.7.0, < 4.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.56.0, < 5.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.6.2, < 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.8.1, < 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.7.1, < 3.0.0 |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 2.8.0, < 3.0.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 3.7.0, < 4.0.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.56.0, < 5.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.6.2, < 3.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.8.1, < 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.stacklet_queue](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_update_resource.event_grid_topic_identity](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.stacklet_function_network](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azapi_update_resource.stacklet_storage_network](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azuread_app_role_assignment.stacklet_app_role_assignment](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application.stacklet_application](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_service_principal.stacklet_sp](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_application_insights.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_eventgrid_system_topic.azure_rm_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic) | resource |
| [azurerm_eventgrid_system_topic_event_subscription.azure_rm_event_subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic_event_subscription) | resource |
| [azurerm_linux_function_app.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_private_dns_zone.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone.storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.stacklet_storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.stacklet_storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.stacklet_storage_table](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.stacklet_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.event_grid_queue_sender](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.function_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.function_storage_blob](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.function_storage_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_service_plan.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.stacklet_function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.stacklet_private_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.stacklet_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [local_file.function_app_versioned](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.function_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.host_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.storage_account_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_uuid.app_role_uuid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [archive_file.function_app](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [azuread_application.stacklet_application](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application) | data source |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_service_principal.stacklet_sp](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_eventgrid_system_topic.azure_rm_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/eventgrid_system_topic) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_target_account"></a> [aws\_target\_account](#input\_aws\_target\_account) | AWS Target account for relay, to be provided by Stacklet. | `string` | n/a | yes |
| <a name="input_aws_target_event_bus"></a> [aws\_target\_event\_bus](#input\_aws\_target\_event\_bus) | AWS Target event bus for relay, to be provided by Stacklet. | `string` | n/a | yes |
| <a name="input_aws_target_partition"></a> [aws\_target\_partition](#input\_aws\_target\_partition) | AWS Target partition for relay, to be provided by Stacklet. | `string` | `"aws"` | no |
| <a name="input_aws_target_prefix"></a> [aws\_target\_prefix](#input\_aws\_target\_prefix) | Deployment prefix for the target Stacklet instance, to be provided by Stacklet. | `string` | n/a | yes |
| <a name="input_aws_target_region"></a> [aws\_target\_region](#input\_aws\_target\_region) | AWS Target region for relay, to be provided by Stacklet. | `string` | n/a | yes |
| <a name="input_aws_target_role_name"></a> [aws\_target\_role\_name](#input\_aws\_target\_role\_name) | AWS Target role name for relay, to be provided by Stacklet. | `string` | n/a | yes |
| <a name="input_azuread_application"></a> [azuread\_application](#input\_azuread\_application) | Azure AD Application. One per tenant. | `string` | `null` | no |
| <a name="input_event_grid_topic_name"></a> [event\_grid\_topic\_name](#input\_event\_grid\_topic\_name) | Name of an existing Subscription System Topic to attach to. Omit it to have the module create one. Must be set together with event\_grid\_topic\_resource\_group. | `string` | `null` | no |
| <a name="input_event_grid_topic_resource_group"></a> [event\_grid\_topic\_resource\_group](#input\_event\_grid\_topic\_resource\_group) | Name of the resource group containing event\_grid\_topic\_name. Required when event\_grid\_topic\_name is set, and must be omitted otherwise. | `string` | `null` | no |
| <a name="input_event_names"></a> [event\_names](#input\_event\_names) | Event Names to filter | `list(string)` | <pre>[<br/>  "Microsoft.Resources.ResourceWriteSuccess",<br/>  "Microsoft.Resources.ResourceActionSuccess",<br/>  "Microsoft.Resources.ResourceDeleteSuccess"<br/>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A Prefix for all of the generated resources | `string` | n/a | yes |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | Resource Group location for generated resources | `string` | `"East US"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group name for generated resources | `string` | `null` | no |
| <a name="input_subnet_prefix_length"></a> [subnet\_prefix\_length](#input\_subnet\_prefix\_length) | The network prefix size used for virtual network subnets | `string` | `24` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(any)` | `{}` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space for the relay's virtual network | `string` | `"10.0.0.0/16"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
