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

resource "azurerm_application_insights" "stacklet" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  application_type    = "web"
  tags                = local.tags
  retention_in_days   = 90
}

resource "azurerm_service_plan" "stacklet" {
  name                = "${var.prefix}-app-service-plan"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

# Generate the function.json with queue name
resource "local_file" "function_json" {
  content = jsonencode({
    scriptFile = "__init__.py"
    bindings = [
      {
        name       = "msg"
        type       = "queueTrigger"
        direction  = "in"
        queueName  = azurerm_storage_queue.stacklet.name
        connection = "AzureWebJobsStorage"
      }
    ]
  })
  filename = "${path.module}/function-app-v1/ProviderRelay/function.json"
}

# Create host.json with enhanced logging configuration
resource "local_file" "host_json" {
  content = jsonencode({
    version = "2.0"
    logging = {
      applicationInsights = {
        samplingSettings = {
          isEnabled     = true
          excludedTypes = "Request"
        }
      }
      logLevel = {
        default           = "Information"
        "ProviderRelay"   = "Information"
        "azure.functions" = "Warning"
        "azure.storage"   = "Warning"
      }
    }
    functions = ["ProviderRelay"]
    extensionBundle = {
      id      = "Microsoft.Azure.Functions.ExtensionBundle"
      version = "[4.*, 5.0.0)"
    }
  })
  filename = "${path.module}/function-app-v1/host.json"
}

# Create the function app deployment package
data "archive_file" "function_app" {
  depends_on = [local_file.function_json, local_file.host_json]

  type        = "zip"
  source_dir  = "${path.module}/function-app-v1"
  output_path = "${path.module}/function-app.zip"
}

resource "azurerm_linux_function_app" "stacklet" {
  name                = "${var.prefix}-relay-app"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location
  service_plan_id     = azurerm_service_plan.stacklet.id

  storage_account_name       = azurerm_storage_account.stacklet.name
  storage_account_access_key = azurerm_storage_account.stacklet.primary_access_key
  # storage_uses_managed_identity = true
  # After the function has been deployed, this value can be turned on, and
  # the storage_account_access_key removed. However, doing this also stops
  # future redeployment of the function code from working as the azure cli
  # looks for the `AzureWebJobsStorage` application setting. When using the
  # managed identity, this value is not set, and instead
  # `AzureWebJobsStorage__accountKey` is set. This causes the azure cli to
  # fail to deploy the function code.

  # Enforce HTTPS and private access
  https_only                    = true
  client_certificate_enabled    = false
  public_network_access_enabled = false

  site_config {
    application_insights_key               = azurerm_application_insights.stacklet.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.stacklet.connection_string

    application_stack {
      python_version = "3.12"
    }

    # Security hardening
    http2_enabled = true # Enable HTTP/2 - however this function never has direct HTTP access, so this setting is fairly meaningless, but ticks boxes.
    # minimum_tls_version = "1.3"
  }

  app_settings = {
    # Build and deployment settings
    SCM_DO_BUILD_DURING_DEPLOYMENT = true

    # Application configuration
    AZURE_CLIENT_ID          = azurerm_user_assigned_identity.stacklet_identity.client_id
    AZURE_AUDIENCE           = local.audience
    AZURE_STORAGE_QUEUE_NAME = azurerm_storage_queue.stacklet.name
    AWS_TARGET_ACCOUNT       = var.aws_target_account
    AWS_TARGET_REGION        = var.aws_target_region
    AWS_TARGET_ROLE_NAME     = var.aws_target_role_name
    AWS_TARGET_PARTITION     = var.aws_target_partition
    AWS_TARGET_EVENT_BUS     = var.aws_target_event_bus
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.stacklet_identity.id]
  }

  tags = local.tags
}

# In order to get the underlying function in the application to be redeployed
# when the zip hash changes, we need use fork out to the azure cli.
# We also need to temporarily enable public access to allow the zip file to be deployed.
resource "null_resource" "deploy_function_app" {
  depends_on = [azurerm_linux_function_app.stacklet]

  provisioner "local-exec" {
    command = <<-EOT
      # Temporarily enable public access
      az functionapp update \
        --name ${azurerm_linux_function_app.stacklet.name} \
        --resource-group ${azurerm_resource_group.stacklet_rg.name} \
        --set publicNetworkAccess=Enabled

      # Deploy the code
      az functionapp deployment source config-zip \
        --name ${azurerm_linux_function_app.stacklet.name} \
        --resource-group ${azurerm_resource_group.stacklet_rg.name} \
        --src ${data.archive_file.function_app.output_path} \
        --build-remote true

      # Disable public access again
      az functionapp update \
        --name ${azurerm_linux_function_app.stacklet.name} \
        --resource-group ${azurerm_resource_group.stacklet_rg.name} \
        --set publicNetworkAccess=Disabled
    EOT
  }

  triggers = {
    build_hash = data.archive_file.function_app.output_sha256
  }
}
