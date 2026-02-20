// configure providers 
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.60.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "e910c4ee-b806-498f-bcf9-f1ac1201a801"
  client_id = "8bb6347b-d955-4262-a0d0-f61755cfe061"
  client_secret = "2AA8Q~WzJlKao6GF.bt.VchdpPnCLnQtiUghpdmG"
  tenant_id = "2ee60809-1e40-4121-af43-ad86b14e3063"
  features {
    
  }
}
// Configured locals
locals {
  resource_group_name = "myrg"
  location            = "centralindia"
  virtual_network = {
    name = "vnet1"
    address_space = ["10.0.0.0/16"]

  }
  subnets = [
    {
      name = "subnet1"
      address_prefixes = ["10.0.1.0/24"]
    },
    {
      name = "subnet2"
      address_prefixes = ["10.0.2.0/24"]
 
}
  ]
}

//This resource block is used to create a resource group
resource "azurerm_resource_group" "RG" {
  name     = local.resource_group_name
  location = local.location
}
//This resource block is used to create a virthual network
resource "azurerm_virtual_network" "vnet" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = local.virtual_network.address_space
  depends_on = [ azurerm_resource_group.RG ]
 
}

//this resource block is used to create two subnets in the virthual network
resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = local.subnets[0].address_prefixes
  depends_on = [azurerm_virtual_network.vnet]
}
resource "azurerm_subnet" "subnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = local.subnets[1].address_prefixes
  depends_on = [azurerm_virtual_network.vnet]
}

//this resource block is used to create a nic with private ip
resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internalip"
    subnet_id = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.publicip1.id}"
  }
  
}

//this resource block is used to create a public ip
resource "azurerm_public_ip" "publicip1" {
  name                = "myfirstpublicip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"

  tags = {
    environment = "study"
  }
  depends_on = [ azurerm_resource_group.RG ]
}

//this resource block is used to create a NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "mynsg"
  location            = local.location
  resource_group_name = local.resource_group_name
  depends_on = [ azurerm_resource_group.RG ]

  security_rule {
    name                       = "rdprule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "study"
  }
}

//this resource block is used to NSG association to subnetA
resource "azurerm_subnet_network_security_group_association" "associatewithsubnetA" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on = [ azurerm_resource_group.RG ]
}

//this resource block is used to create a windows virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "myvm1"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "standard_d2ads_v5"
  admin_username      = "adminuser"
  admin_password      = "Welcome@12345"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_resource_group.RG, azurerm_network_interface.nic ]
  tags = { "Woner" ="satish Rajput" }
}

//this resource block is used to create a data disk
resource "azurerm_managed_disk" "DataDisk" {
  name                 = "Disk2"
  location             = local.location
  resource_group_name  = local.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

//this resource block is used to attach the data disk to virtual machine
resource "azurerm_virtual_machine_data_disk_attachment" "attattachdatadisk" {
  managed_disk_id    = azurerm_managed_disk.DataDisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = "1"
  caching            = "ReadWrite"
}

//this resource block is used to create a route table and add a route to it
resource "azurerm_route_table" "route" {
  name                = "routetable"
  location            = local.location
  resource_group_name = local.resource_group_name

  route {
    name           = "route1"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VnetLocal"
  }
}

//this resource block is used to associate the route table with subnetA
resource "azurerm_subnet_route_table_association" "associatewithsubnetB" {
  subnet_id      = azurerm_subnet.subnetA.id
  route_table_id = azurerm_route_table.route.id
}

// This resource block is used for creating data disk snapshot
resource "azurerm_snapshot" "snapshot" {
  name                = "myvm1_osdisk_snapshot"
  location            = local.location
  resource_group_name = local.resource_group_name
  create_option       = "Copy"
  source_uri          = azurerm_managed_disk.DataDisk.id
}

// Vnet peering practicale with two vm servers

// Configured locals
locals {
  resource_group_name = "myrg"
  location            = "centralindia"
}

// This resource block is for create resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

// This resource block is for create virtual network1
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet01"
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

// This resource block is for create virtual network2

resource "azurerm_subnet" "subnet1" {
  name                 = "mysubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet02"
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = ["192.168.0.0/16"]
}
resource "azurerm_subnet" "subnet2" {
  name                 = "mysubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["192.168.1.0/24"]
}

// Vnet peering between vnet1 and vnet2

resource "azurerm_virtual_network_peering" "example-1" {
  name                      = "peer1to2"
  resource_group_name       = local.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "example-2" {
  name                      = "peer2to1"
  resource_group_name       = local.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  depends_on = [ azurerm_virtual_network.vnet1,azurerm_virtual_network.vnet2 ]
}
// public ip configuration for vm1 and vm2

resource "azurerm_public_ip" "publicip1" {
  name                = "myfirstpublicip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "publicip2" {
  name                = "mysecondpublicip"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.rg ]
}
resource "azurerm_network_interface" "nic2" {
  name                = "mynic2"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internalip"
    subnet_id = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.publicip2.id}"
  }
}

resource "azurerm_network_interface" "nic1" {
  name                = "mynic1"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internalip"
    subnet_id = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.publicip1.id}"
  }
}

// This resource block is for create Virthual machine

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "myvm1"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "standard_d2ads_v5"
  admin_username      = "adminuser"
  admin_password      = "Welcome@12345"
  network_interface_ids = [
  azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
  version   = "latest"
  }
  
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "myvm2"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "standard_d2ads_v5"
  admin_username      = "adminuser"
  admin_password      = "Welcome@12345"
  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }
}

// NSG

resource "azurerm_network_security_group" "nsg" {
  name                = "mynsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "rdprule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "associate1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_subnet_network_security_group_association" "associate2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


  
