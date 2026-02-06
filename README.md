## Overview

This Terraform module implements an **event forwarding system** that captures Azure resource events and relays them to Stacklet's AWS-based platform for real-time policy execution and governance. It creates a cross-cloud event bridge that enables Stacklet's governance capabilities to extend from AWS into Azure environments.

## Architecture

The system works through a four-step process:

### 1. Event Capture (Azure EventGrid)
- Sets up an **Azure EventGrid System Topic** to capture subscription-level events
- By default monitors these resource events:
  - `Microsoft.Resources.ResourceWriteSuccess` (resource creation/updates)
  - `Microsoft.Resources.ResourceActionSuccess` (resource actions)
  - `Microsoft.Resources.ResourceDeleteSuccess` (resource deletions)

### 2. Event Storage (Azure Storage Queue)
- Events are queued in a private **Azure Storage Queue** for reliable processing
- Uses CloudEvent schema v1.0 format for standardized event structure

### 3. Event Processing (Azure Function)
- **Python-based Azure Function** processes events from the storage queue
- Uses **queue trigger** to automatically process incoming events
- Runs on Linux App Service Plan with Python 3.10

### 4. Cross-Cloud Authentication & Event Forwarding
- Uses **Azure Managed Identity** to get an identity token
- Performs **AssumeRoleWithWebIdentity** to obtain AWS credentials
- Forwards events to **AWS EventBridge** in the target Stacklet account

## Key Components Deployed

1. **Azure Resource Group** - Contains all module resources
2. **Azure EventGrid System Topic** - Captures subscription-level events
3. **Azure Virtual Network** - Keeps all network traffic private
4. **Azure Storage Account & Queue** - Provides reliable event storage
5. **Azure Function App** - Handles event processing and forwarding
6. **Azure Application Insights** - Enables monitoring and logging
7. **Azure AD Application & Service Principal** - Manages cross-cloud authentication
8. **User Assigned Identity** - Provides managed identity for the function

## Benefits

This system enables:
- **Event-driven policy execution** - Real-time response to Azure resource changes
- **Real-time compliance monitoring** - Immediate visibility into compliance status
- **Automated governance actions** - Automated remediation and policy enforcement
- **Cross-cloud resource visibility** - Unified governance across Azure and AWS

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >=2.7.1 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >=2.8.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >=3.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=4.56.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >=2.6.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.8.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >=2.7.1 |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >=2.8.0 |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >=3.7.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=4.56.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >=2.6.2 |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.8.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.stacklet_queue](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
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
| <a name="input_event_grid_topic_name"></a> [event\_grid\_topic\_name](#input\_event\_grid\_topic\_name) | System Topic Name for subscription events if it already exists | `string` | `null` | no |
| <a name="input_event_grid_topic_resource_group"></a> [event\_grid\_topic\_resource\_group](#input\_event\_grid\_topic\_resource\_group) | System Topic resource group name for subscription events if it already exists | `string` | `null` | no |
| <a name="input_event_names"></a> [event\_names](#input\_event\_names) | Event Names to filter | `list(string)` | <pre>[<br/>  "Microsoft.Resources.ResourceWriteSuccess",<br/>  "Microsoft.Resources.ResourceActionSuccess",<br/>  "Microsoft.Resources.ResourceDeleteSuccess"<br/>]</pre> | no |
| <a name="input_force_delete_resource_group"></a> [force\_delete\_resource\_group](#input\_force\_delete\_resource\_group) | Force delete the resource group when terraform destroy is run | `bool` | `false` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A Prefix for all of the generated resources | `string` | n/a | yes |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | Resource Group location for generated resources | `string` | `"East US"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group name for generated resources | `string` | `null` | no |
| <a name="input_subnet_prefix_length"></a> [subnet\_prefix\_length](#input\_subnet\_prefix\_length) | The network prefix size used for virtual network subnets | `string` | `24` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID. This could also be set using the ARM\_SUBSCRIPTION\_ID environment variable. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(any)` | `{}` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space for the relay's virtual network | `string` | `"10.0.0.0/16"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
