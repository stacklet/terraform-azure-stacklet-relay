# Default

The onboarding path Stacklet documents. The module creates an Event Grid
Subscription System Topic for the subscription it runs against, along with
everything else listed under Overview in the
[module README](../../README.md).

The values under "Stacklet provided values" in `main.tf` identify the Stacklet
deployment the relay sends events to. A real deployment hands them to the
customer in a generated copy of that file.

`main.tf` differs from the file a customer applies in two ways, both explained
in comments where they occur. Its `source` is a relative path rather than the
registry address with a pinned `version`, which
[Versioning](../../README.md#versioning) covers. Its providers set no
`subscription_id`, so they read `ARM_SUBSCRIPTION_ID` from the environment.

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
