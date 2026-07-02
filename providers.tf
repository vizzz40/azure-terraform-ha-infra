terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    #random provider is used to generate random values for resource names
    random = {
        source  = "hashicorp/random"
        version = "~> 3.0"
        }
    }
}
# this is necessary for azurerm provider to work properly
provider "azurerm" {
  features {}
}