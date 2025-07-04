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

# azurerm_linux_function_app's zip_deploy_file will only redeploy the function
# when the path changes, so copy the zip to a versioned filename.
resource "local_file" "function_app_versioned" {
  filename = "${path.module}/function-app-${data.archive_file.function_app.output_sha256}.zip"
  source = "${path.module}/function-app.zip"
}

resource "azurerm_linux_function_app" "stacklet" {
  name                = "${var.prefix}-relay-app"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location
  service_plan_id     = azurerm_service_plan.stacklet.id

  storage_account_name       = azurerm_storage_account.stacklet.name
  storage_account_access_key = azurerm_storage_account.stacklet.primary_access_key
  # replaces storage_account_access_key
  # storage_uses_managed_identity = true # Use managed identity instead of access keys

  # Enforce HTTPS on the HTTP endpoint even though the data plane aspect of it
  # is unused, to avoid showing up in security checks.
  https_only                    = true
  client_certificate_enabled    = false
  public_network_access_enabled = false

  # Deploy from zip file
  zip_deploy_file = local_file.function_app_versioned.filename

  site_config {
    application_insights_key = azurerm_application_insights.stacklet.instrumentation_key

    application_stack {
      python_version = "3.12"
    }

    # More somewhat pointless HTTP security; the HTTP data plane is unused.
    ftps_state               = "Disabled" # Disable FTP/FTPS
    http2_enabled            = true       # Enable HTTP/2
    minimum_tls_version      = "1.3"
    remote_debugging_enabled = false      # Disable remote debugging
    scm_minimum_tls_version  = "1.2"      # SCM also uses TLS 1.2+
    websockets_enabled       = false      # Disable WebSockets
  }

  app_settings = {
    # Build and deployment settings
    SCM_DO_BUILD_DURING_DEPLOYMENT = true

    # Since we don't actually publish any HTTP content, also disable the
    # default "Your Functions 4.0 app is up and running" page.
    AzureWebJobsDisableHomepage = true

    # # Storage connection using managed identity
    # AzureWebJobsStorage__accountName = azurerm_storage_account.stacklet.name
    # AzureWebJobsStorage__credential  = "managedidentity"

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

  # # Authentication disabled since no HTTP access
  # auth_settings {
  #   enabled = false
  # }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.stacklet_identity.id]
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}
