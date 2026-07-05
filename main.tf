#logical provider (works within terraform logic) to assign random name to load balancer hostname
resource "random_string" "lb_hostname" {
  length  = 8
  special = false
}
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
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azure_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

resource "azurerm_network_security_group" "myNSG" {
  name                = "${var.resource_group_name}-NSG"
  location            = var.location
  resource_group_name = azure_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP-From-LB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-From-LB"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.myNSG.id
}

