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
  # Provider desde common_vars
  subscription_id      = local.common_vars.azure.subscription_id
  tenant_id            = local.common_vars.azure.tenant_id

  # Recurso
  resource_group_name  = local.common_vars.rg_roles.apps
  location             = local.common_vars.azure.region
  name                 = "${local.common_vars.project_name}-swa-${local.common_vars.environment}"

  # SKU Standard
  sku_tier             = "Standard"
  sku_size             = "Standard"

  # Identidad administrada
  identity_enabled     = true

  # (Opcional) dominio cuando lo tengas
  # custom_domain      = "app.midominio.com"

  # Tags (mantén Environment y Owner como obligatorios)
  tags = {
    Tipo_Recurso = "StaticWebApp"
    Environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
  }
}
