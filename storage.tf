resource "azurerm_storage_account" "stacklet" {
  name                     = "${var.prefix}storageaccount"
  resource_group_name      = azurerm_resource_group.stacklet_rg.name
  location                 = azurerm_resource_group.stacklet_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "stacklet" {
  name                 = "${var.prefix}-queue"
  storage_account_name = azurerm_storage_account.stacklet.name
}
