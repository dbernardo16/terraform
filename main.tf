terraform {
  required_version = ">= 0.14.9"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }


}

provider "azurerm" {
    skip_provider_registration = true
  features {}
}

resource "azurerm_resource_group" "as02-rg" {
  name     = "rg"
  location = "eastus"
}

resource "azurerm_subnet" "as02-subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.as02-rg.name
  virtual_network_name = azurerm_virtual_network.as02-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_virtual_network" "as02-vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.as02-rg.location
  resource_group_name = azurerm_resource_group.as02-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    turma = "as02"
  }
}
