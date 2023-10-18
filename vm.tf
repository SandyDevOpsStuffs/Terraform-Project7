provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_resource_group" "str-grp" {
  name     = "str-grp"
}


resource "azurerm_resource_group" "str-grp" {
  name     = "str-grp"  # Use the same resource group name as in Project5
  location = "East US"  # Use the same location as in Project5
}

data "azurerm_virtual_network" "example" {
  name                = "SDM-VNet"
  resource_group_name = azurerm_resource_group.str-grp.name
}

data "azurerm_subnet" "example" {
  name                 = "SDM-Subnet"
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.str-grp.name
}

resource "azurerm_network_interface" "example" {
  name                = "SDM-NIC"
  location            = data.azurerm_resource_group.str-grp.location
  resource_group_name = azurerm_resource_group.str-grp.name
  ip_configuration {
    name                          = "SDM-NIC-IPConfig"
    subnet_id                     = data.azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

variable "vm_size" {
  description = "The size of the Azure Virtual Machine"
  type        = string
  default     = "Standard_A1_v2"  # Replace with your preferred default size
}

resource "azurerm_virtual_machine" "example" {
  name                  = "SDM-VM"
  location              = data.azurerm_resource_group.str-grp.location
  resource_group_name   = azurerm_resource_group.str-grp.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "admin_sdm"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/admin_sdm/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")  # Use your own public key
    }
  }

}

terraform {
  backend "azurerm" {
    resource_group_name   = "str-grp"  # Use the resource group name from Project5
    storage_account_name  = "sdmeastusstracc1"  # Use the storage account name from Project5
    container_name        = "str-con-1"  # Choose a container name for Terraform state files
    key                   = "vm/project7.tfstate"  # Unique key for this state file
  }
}

