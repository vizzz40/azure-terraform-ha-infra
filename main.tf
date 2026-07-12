#logical provider (works within terraform logic) to assign random name to load balancer hostname
resource "random_string" "lb_hostname" {
  length  = 8
  special = false
}
# we keep all our resource inside a resource group, so we need to create one first

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# we then make our Vnet

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet" #i am using string interpolation to create a name for the vnet based on the resource group name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# we then make our subnet

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefix
}

resource "azurerm_network_security_group" "myNSG" {
  name                = "${var.resource_group_name}-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

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

resource "azurerm_public_ip" "lb_public_ip" {
  name                = "${var.resource_group_name}-lb-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones                = ["1", "2", "3"]
  domain_name_label  = random_string.lb_hostname.result
}

resource "azurerm_lb" "load_balancer" {
  name                = "${var.resource_group_name}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}
# add the probe and backend pool for the LB\

resource "azurerm_lb_backend_address_pool" "bpool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "BackEndAddressPool"
}

#The LB will check the server on '/' path at port 80 every few seconds for a 200 status code aka probing

resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "http-probe"
  port            = 80
  protocol = "Http"
  request_path = "/"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "http_rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpool.id]
  probe_id = azurerm_lb_probe.http_probe.id
}

resource "azurerm_public_ip" "nat_pip" {
  name                = "nat-gateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb_nat_rule" "ssh_nat_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "SSH-Access"
  protocol                       = "Tcp"
  frontend_port_start            = 50000 
  frontend_port_end              = 50010 
  backend_port                   = 22    
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpool.id
  frontend_ip_configuration_name = "LoadBalancerFrontEnd" 
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}