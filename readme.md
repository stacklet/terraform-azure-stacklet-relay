# terraform-azure-stacklet-relay

This module will deploy the necessary infrastructure to forward events from your Azure Subscription into
Stacklet Platform. These events are used to enable event-driven policy execution to ensure real time
policy execution within your subscription.

<!-- BEGIN_TF_DOCS -->
## Requirements

[Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) must be installed.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.stacklet_application](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_service_principal.stacklet_sp](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azurerm_application_insights.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_eventgrid_system_topic.azure_rm_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic) | resource |
| [azurerm_eventgrid_system_topic_event_subscription.azure_rm_event_subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic_event_subscription) | resource |
| [azurerm_linux_function_app.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.stacklet_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_queue.stacklet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_queue) | resource |
| [azurerm_user_assigned_identity.stacklet_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [local_file.function_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.function_deploy](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.stacklet](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.storage_account_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_uuid.app_role_uuid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [azuread_application.stacklet_application](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application) | data source |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_service_principal.stacklet_sp](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_eventgrid_system_topic.azure_rm_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/eventgrid_system_topic) | data source |
| [azurerm_role_definition.builtin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
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
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A Prefix for all of the generated resources | `string` | n/a | yes |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | Resource Group location for generated resoruces | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
