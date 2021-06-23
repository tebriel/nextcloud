resource "azurerm_storage_account" "virtualmachines" {
  name                     = "froduxvirtualmachines"
  resource_group_name      = azurerm_resource_group.nextcloud.name
  location                 = azurerm_resource_group.nextcloud.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
