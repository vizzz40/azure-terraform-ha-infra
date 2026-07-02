# we keep all our resource inside a resource group, so we need to create one first

resource "azure_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.lcoation
}

# we then make our Vnet

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet" #i am using string interpolation to create a name for the vnet based on the resource group name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azure_resource_group.rg.name
}

# we then make our subnet

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-subnet-a"
  resource_group_name  = azure_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}