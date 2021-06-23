terraform {
  required_version = ">= 1.0"
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

provider "aws" {
  region  = "us-east-1"
  profile = "personal"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.64.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform"
    storage_account_name = "tebrielterraformstate"
    container_name       = "nextcloud"
    key                  = "terraform.tfstate"
  }
}
