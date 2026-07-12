resource "azurerm_orchestrated_virtual_machine_scale_set" "example" {
  name                = "my-orchestrated-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  platform_fault_domain_count = 1 #for better reliability
  sku_name                    = "Standard_B1s"

  zones = ["1"]
}