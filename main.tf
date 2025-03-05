//prodvider block
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
  }
    cloud {

      organization = "lockey_network"

      workspaces {
        name = "Workspace_Remote_State"
      }
    }
  }

provider "azurerm" {
  features {}
  subscription_id = "46941756-e91a-497a-981e-88b1aab7033c"

}
//Resource Group
resource "azurerm_resource_group" "TF-RG" {
  name     = "terraform-rg"
  location = "UK South"
  tags = {
    environment = "TerraformDeployment"
  }
}
//Virtual Network
resource "azurerm_virtual_network" "VNET3" {
  name                = "Terraform-VNET"
  resource_group_name = azurerm_resource_group.TF-RG.name
  location            = azurerm_resource_group.TF-RG.location
  address_space       = ["192.168.0.0/16"]

  tags = azurerm_resource_group.TF-RG.tags

}
//Subnet
resource "azurerm_subnet" "VirtualMachines" {
  name                 = "Terraform-VM-Subnet"
  resource_group_name  = azurerm_resource_group.TF-RG.name
  virtual_network_name = azurerm_virtual_network.VNET3.name
  address_prefixes     = ["192.168.1.0/24"]

}
//Network Security Group
resource "azurerm_network_security_group" "NSG1" {
  name                = "Terraform-NSG1"
  location            = azurerm_resource_group.TF-RG.location
  resource_group_name = azurerm_resource_group.TF-RG.name


  security_rule {
    name                       = "HTTPSInbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPSOutbound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.TF-RG.tags
  //Associate the NSG with the subnet
}
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.VirtualMachines.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

resource "azurerm_public_ip" "TF-PublicIP-1" {
  name                = "publicIP-1"
  resource_group_name = azurerm_resource_group.TF-RG.name
  location            = azurerm_resource_group.TF-RG.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = {
    environment = "TerraformDeployment"
  }
}
// Create a network interface
resource "azurerm_network_interface" "TF-NIC-1" {
  name                = "TF-NIC-1"
  location            = azurerm_resource_group.TF-RG.location
  resource_group_name = azurerm_resource_group.TF-RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.VirtualMachines.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.TF-PublicIP-1.id

  }
}
//Virtual Machine
resource "azurerm_windows_virtual_machine" "TF-VM-1" {
  name                = "TF-VM-1"
  resource_group_name = azurerm_resource_group.TF-RG.name
  location            = azurerm_resource_group.TF-RG.location
  size                = "Standard_DS1_v2"
  admin_username      = "Bossman"
  admin_password      = "randyh1ckeY"
  network_interface_ids = [
    azurerm_network_interface.TF-NIC-1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

}

