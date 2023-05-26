data "archive_file" "function_app" {
  type        = "zip"
  source_dir  = "function-app"
  output_path = "function-app.zip"
}

resource "azurerm_application_insights" "stacklet" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  application_type    = "web"
}

resource "azurerm_service_plan" "stacklet" {
  name                = "${var.prefix}-app-service-plan"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "stacklet" {
  name                = "${var.prefix}-function-app"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location

  storage_account_name       = azurerm_storage_account.stacklet.name
  storage_account_access_key = azurerm_storage_account.stacklet.primary_access_key
  service_plan_id            = azurerm_service_plan.stacklet.id
  zip_deploy_file            = data.archive_file.function_app.output_path

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = true
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.stacklet.instrumentation_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.stacklet_identity.id]
  }
}

resource "azurerm_function_app_function" "stacklet" {
  name            = "provider-relay"
  function_app_id = azurerm_linux_function_app.stacklet.id
  language        = "Python"

  file {
    name    = "relay.py"
    content = file("${path.module}/function/relay.py")
  }

  config_json = jsonencode({
    "scriptFile" : "relay.py",
    "bindings" : [
      {
        "direction" : "in",
        "type" : "queueTrigger",
        "connection" : "AzureWebJobsStorage",
        "name" : "msg",
        "queueName" : "${azurerm_storage_queue.stacklet.name}"
      }
    ]
  })
}
