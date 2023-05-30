resource "random_string" "storage_account_suffix" {
  special = false
  length  = 24
  lower   = true
  upper   = false
}

resource "azurerm_storage_account" "stacklet" {
  # there is a global uniquness constraing on storage account names, as well as a length requirement of 3-24 characters
  name                     = substr("${var.prefix}${random_string.storage_account_suffix.result}", 0, 23)
  resource_group_name      = azurerm_resource_group.stacklet_rg.name
  location                 = azurerm_resource_group.stacklet_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_queue" "stacklet" {
  name                 = "${azurerm_storage_account.stacklet.name}-queue"
  storage_account_name = azurerm_storage_account.stacklet.name
}
