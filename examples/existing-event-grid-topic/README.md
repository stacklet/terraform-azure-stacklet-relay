# Existing Event Grid system topic

For a subscription that already has an Event Grid Subscription System Topic.
Azure allows one per subscription for subscription-level events, so wherever one
already exists, whatever created it, the module attaches to it rather than
creating a second.

`event_grid_topic_name` and `event_grid_topic_resource_group` are required
together, and both values in `main.tf` are placeholders. Replace them with the
name of the topic the subscription already has and the resource group holding
it. Omit both instead and the module creates the topic, which is the
[default example](../default). Supplying a topic needs credentials that can
write to it, because the module adds a system-assigned identity, and a later
`terraform destroy` leaves that identity behind. If you manage the topic in your
own Terraform, add the identity there too. See
[Bring your own system topic](../../README.md#bring-your-own-system-topic) for
the full set of consequences.

Everything else matches the [default example](../default), including the two
ways this file differs from what a customer applies.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.56 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_relay"></a> [azure\_relay](#module\_azure\_relay) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
