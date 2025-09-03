# 🔗 Incluye backend/provider base
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Origen del módulo Terraform (usa tu repo)
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
  name                = "${local.common_vars.project_name}-swa-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.apps
  location            = local.common_vars.azure.region

  sku_tier           = "Standard"
  sku_size           = "Standard"
  identity_enabled   = false
  custom_domain      = null  # déjalo null hasta que tengas el DNS listo

  tags = {
    Tipo_Recurso = "StaticWebApp"
    environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
  }
}
