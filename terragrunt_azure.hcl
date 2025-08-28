locals {
  # Carga todas las variables comunes desde un archivo externo
  common_vars = yamldecode(file("common_vars.yaml"))
}

# Configuración del backend remoto para almacenar el estado de Terraform
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    resource_group_name  = local.common_vars.rg_roles.data
    storage_account_name = local.common_vars.azure.storage_account_name
    container_name       = local.common_vars.azure.storage_container_name
    key                  = "${path_relative_to_include()}/terraform.tfstate"   
    use_azuread_auth     = true
  }
}

# Genera archivo de proveedor con configuración OIDC
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {}
  subscription_id            = "${local.common_vars.azure.subscription_id}"
  tenant_id                  = "${local.common_vars.azure.tenant_id}"
  client_id                  = "${local.common_vars.azure.client_id}"
  use_oidc                   = true
  skip_provider_registration = false
}

provider "azapi" {}
EOF
}

# Genera archivo de versiones y definición de providers requeridos
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.104.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.10.0"
    }
  }
}
EOF
}
