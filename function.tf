resource "azurerm_application_insights" "stacklet" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.stacklet_rg.location
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  application_type    = "web"
  tags                = local.tags
}

resource "azurerm_service_plan" "stacklet" {
  name                = "${var.prefix}-app-service-plan"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

resource "azurerm_linux_function_app" "stacklet" {
  name                = "${var.prefix}-function-app"
  resource_group_name = azurerm_resource_group.stacklet_rg.name
  location            = azurerm_resource_group.stacklet_rg.location

  storage_account_name       = azurerm_storage_account.stacklet.name
  storage_account_access_key = azurerm_storage_account.stacklet.primary_access_key
  service_plan_id            = azurerm_service_plan.stacklet.id

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = true
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.stacklet.instrumentation_key
    AZURE_CLIENT_ID                = azurerm_user_assigned_identity.stacklet_identity.client_id
    AZURE_AUDIENCE                 = local.audience
    AZURE_STORAGE_QUEUE_NAME       = azurerm_storage_queue.stacklet.name
    AZURE_SUBSCRIPTION_ID          = data.azurerm_subscription.current.subscription_id
    AWS_TARGET_ACCOUNT             = var.aws_target_account
    AWS_TARGET_REGION              = var.aws_target_region
    AWS_TARGET_ROLE_NAME           = var.aws_target_role_name
    AWS_TARGET_PARTITION           = var.aws_target_partition
    AWS_TARGET_EVENT_BUS           = var.aws_target_event_bus
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.stacklet_identity.id]
  }
  tags = local.tags
}

resource "local_file" "function_json" {
  content = templatefile(
  "${path.module}/function-app-v1/ProviderRelay/function.json.tmpl", { queue_name = azurerm_storage_queue.stacklet.name })
  filename = "${path.module}/function-app-v1/ProviderRelay/function.json"
}


resource "null_resource" "function_deploy" {
  depends_on = [azurerm_linux_function_app.stacklet, local_file.function_json]
  # ensures that publish always runs
  triggers = {
    build_number = "${timestamp()}"
  }

  # initial deployment of the function-app could race with provisioning, so sleep 10 seconds
  provisioner "local-exec" {
    command = <<EOF
    cd ${path.module}/function-app-v1
    sleep 10
    func azure functionapp publish ${azurerm_linux_function_app.stacklet.name} --python
    EOF
  }
}
