# 🔗 Incluye el backend/provider común
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# 🎯 Entradas
inputs = {
  # Provider
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # Recurso (APIM)
  apim_name           = "apimprecreditdev"
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.rg_roles.apps
  sku_name            = "Developer_1"

  publisher_name  = "${local.common_vars.project_name}-apim-${local.common_vars.environment}"
  publisher_email = local.common_vars.org.publisher_email

  # Dominio custom (off en dev)
  custom_domain_enabled    = false
  custom_domain            = ""
  kv_certificate_secret_id = ""

  # Product principal (para agrupar tus APIs)
  create_product                = true
  product_id                    = "plan-${local.common_vars.project_name}-${local.common_vars.environment}" # ej: plan-precredit-dev
  product_display_name          = "Plan ${local.common_vars.project_name}-${local.common_vars.environment}"
  product_subscription_required = true   # en DEV puedes poner false si quieres probar sin keys
  product_approval_required     = false

  # Suscripción global asociada al Product
  create_subscription       = true
  subscription_display_name = "Precredit ${local.common_vars.environment} subscription"
  subscription_user_id      = "1" # Administrators

  tags = {
    Environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
    Tipo_Recurso = "APIM"
  }
}
