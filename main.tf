resource "azurerm_resource_group" "serdar-sadikoglu-rg" {
  name     = "serdar-sadikoglu-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "serdar-network" {
  name                = "serdar-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.serdar-sadikoglu-rg.name
  virtual_network_name = azurerm_virtual_network.serdar-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

################## PRIVATE KEY ######################
resource "tls_private_key" "serdar_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}





/*
# We want to save the private key to our machine
# We can then use this key to connect to our Linux VM

resource "local_file" "serdarkey" {
  filename = "serdarkey.pem"
  content  = tls_private_key.serdar_key.private_key_pem
}

*/

################ VM JENKINS UND TERRAFORM KONFIGURATION ##########################
resource "azurerm_network_security_group" "serdarjenkinsvm-nsg" {
  name                = "serdarjenkinsvm-nsg"
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins-association" {
  network_interface_id      = azurerm_network_interface.jenkins-nic.id
  network_security_group_id = azurerm_network_security_group.serdarjenkinsvm-nsg.id
}


resource "azurerm_public_ip" "serdarjenkins-public_ip" {
  name                = "serdarjenkins-public_ip"
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "jenkins-nic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name

  ip_configuration {
    name                          = "serdarjenkins-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.serdarjenkins-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "serdar-jenkins-vm" {
  name                  = "serdar-jenkins-vm"
  resource_group_name   = azurerm_resource_group.serdar-sadikoglu-rg.name
  location              = azurerm_resource_group.serdar-sadikoglu-rg.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.jenkins-nic.id]

  computer_name                   = "serdar-jenkins-vm"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./serdarkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}


######################## VM ANSIBLE , SERVER KONFIGURATION #################################
resource "azurerm_network_security_group" "serdar-server-nsg" {
  name                = "serdar-server-nsg"
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "server-association" {
  network_interface_id      = azurerm_network_interface.server-nic.id
  network_security_group_id = azurerm_network_security_group.serdar-server-nsg.id
}

resource "azurerm_public_ip" "serdar-server-public_ip" {
  name                = "serdar-server-public_ip"
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "server-nic" {
  name                = "server-nic"
  location            = azurerm_resource_group.serdar-sadikoglu-rg.location
  resource_group_name = azurerm_resource_group.serdar-sadikoglu-rg.name

  ip_configuration {
    name                          = "serdar-server-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.serdar-server-public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "serdar-server-vm" {
  name                  = "serdar-server-vm"
  resource_group_name   = azurerm_resource_group.serdar-sadikoglu-rg.name
  location              = azurerm_resource_group.serdar-sadikoglu-rg.location
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.server-nic.id]

  computer_name                   = "serdar-server-vm"
  disable_password_authentication = true


  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./serdarkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}