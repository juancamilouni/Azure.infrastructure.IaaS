# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}


# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}


inputs = {
  name                = "pip-agw-${local.common_vars.environment}"
  resource_group_name   = local.common_vars.rg_roles.apps
  location             = local.common_vars.azure.region
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Tipo_Recurso  = "PublicIP"
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}