data "azurerm_dns_zone" "nextcloud" {
  name                = "nextcloud.frodux.in"
  resource_group_name = azurerm_resource_group.nextcloud.name
}

resource "azurerm_dns_a_record" "next-dev" {
  name                = "dev"
  zone_name           = data.azurerm_dns_zone.nextcloud.name
  resource_group_name = azurerm_resource_group.nextcloud.name
  ttl                 = 60
  target_resource_id  = azurerm_public_ip.dev-ip.id
}

resource "azurerm_virtual_network" "vnet" {
  name                = "nextcloud-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name
}

resource "azurerm_subnet" "dev-subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.nextcloud.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_network_interface" "dev-nic" {
  name                = "dev-nic"
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev-ip.id
  }
}

resource "azurerm_network_security_group" "dev" {
  name                = "frodux-netxcloud-dev-nsg"
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "dev-ip" {
  name                = "frodux-nextcloud-dev-ip"
  location            = azurerm_resource_group.nextcloud.location
  resource_group_name = azurerm_resource_group.nextcloud.name
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "dev" {
  name                            = "frodux-nextcloud-dev"
  location                        = azurerm_resource_group.nextcloud.location
  resource_group_name             = azurerm_resource_group.nextcloud.name
  size                            = "Standard_D2s_v3"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.dev-nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa-azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
