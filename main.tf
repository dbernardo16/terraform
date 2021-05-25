terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rgAtividade2"
  location = "eastus2"
}

resource "azurerm_virtual_network" "virtualNetwork" {
    name                = "networkAtividade2"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name                 = "subnetAtividade2"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.virtualNetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip" {
    name                         = "ipAtividade2"
    location                     = "eastus2"
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
}

resource "azurerm_network_security_group" "networkSecurityGroup" {
    name                = "nsgAtividade2"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "mysql"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "ssh"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "networkInterface" {
    name                      = "niAtividade2"
    location                  = "eastus2"
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "ipNiAtividade2"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.ip.id
    }
}

resource "azurerm_network_interface_security_group_association" "netWorkInterfaceSecurityGroupAssociation" {
    network_interface_id      = azurerm_network_interface.networkInterface.id
    network_security_group_id = azurerm_network_security_group.networkSecurityGroup.id
}

data "azurerm_public_ip" "ipMysqlAtividade2" {
  name                = azurerm_public_ip.ip.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_storage_account" "storageaccount" {
    name                        = "saatividadedois"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = "eastus2"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

resource "azurerm_linux_virtual_machine" "virtualMachine" {
    name                  = "VMAtividade2"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.networkInterface.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDiskMySQL"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "VMAtividade2"
    admin_username = var.user
    admin_password = var.password
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
    }

    depends_on = [ azurerm_resource_group.rg ]
}

resource "null_resource" "upload_file" {
    provisioner "file" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = data.azurerm_public_ip.ipMysqlAtividade2.ip_address
        }
        source = "mysql"
        destination = "/home/terraform"
    }
}

resource "null_resource" "install_mysql" {
    triggers = {
        order = null_resource.upload_file.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = var.user
            password = var.password
            host = data.azurerm_public_ip.ipMysqlAtividade2.ip_address
        }
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y mysql-server-5.7",
            "sudo mysql < /home/terraform/mysql/user.sql",
            "sudo cp -f /home/terraform/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf",
            "sudo service mysql restart",
            "touch teste.txt",
            "sleep 20",
        ]
    }
}

output "public_ip_address_vm" {
  value = azurerm_public_ip.ip.ip_address
}