resource "azurerm_orchestrated_virtual_machine_scale_set" "example" {
  name                = "my-orchestrated-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  platform_fault_domain_count = 1 #for better reliability
  sku_name                    = "Standard_B1s"
  instances = 3
  zones = ["1"]
  
  user_data_base64 = base64encode(file("user_data.sh"))

  os_profile {
    linux_configuration {
      disable_password_authentication = true
      admin_username                  = "azureuser"
      admin_ssh_key {
        username   = "azureuser"
        public_key = file("./ssh/id_rsa.pub")
      }
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }

  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}
}
