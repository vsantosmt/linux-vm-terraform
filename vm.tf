resource "azurerm_resource_group" "rg-devops" {
  name     = "rg-${var.suffix}"
  location = var.location
}

# Defina a rede virtual (VNet) e sub-rede
resource "azurerm_virtual_network" "vnet-devops" {
  name                = "vnet-${var.suffix}"
  location            = azurerm_resource_group.rg-devops.location
  resource_group_name = azurerm_resource_group.rg-devops.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet-devops" {
  name                 = "snet-${var.suffix}"
  resource_group_name  = azurerm_resource_group.rg-devops.name
  virtual_network_name = azurerm_virtual_network.vnet-devops.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Defina a interface de rede
resource "azurerm_network_interface" "nic-devops" {
  name                = "nic-${var.suffix}"
  location            = azurerm_resource_group.rg-devops.location
  resource_group_name = azurerm_resource_group.rg-devops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-devops.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Defina a máquina virtual
resource "azurerm_linux_virtual_machine" "vm-devops" {
  # count                 = var.vm_count
  name                  = "vm-${var.suffix}"
  resource_group_name   = azurerm_resource_group.rg-devops.name
  location              = azurerm_resource_group.rg-devops.location
  size                  = "Standard_D2s_v3"
  admin_username        = "oci"
  network_interface_ids = [azurerm_network_interface.nic-devops.id]
  admin_ssh_key {
    username   = "oci"
    public_key = file("C:\\projects\\key-pars\\oci-portfolio-manual\\ssh-key-2024-10-31.key.pub")
  }

  os_disk {
    name                 = "my-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "ubuntu-pro" # Ou a versão de sua preferência
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.rg-devops.name
  location            = azurerm_resource_group.rg-devops.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg-devops" {
  name                = "nsg-${var.suffix}"
  location            = azurerm_resource_group.rg-devops.location
  resource_group_name = azurerm_resource_group.rg-devops.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-devops" {
  subnet_id                 = azurerm_subnet.snet-devops.id
  network_security_group_id = azurerm_network_security_group.nsg-devops.id
}

