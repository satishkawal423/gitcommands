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

resource "azurerm_resource_group" "RG" {
  name     = "myrg"
  location = "West Europe"
}
