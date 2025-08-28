# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure..git/<modulo>?ref=main"
}

# 📤 Variables que pasan al módulo
inputs = {
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.resource_group

  # Recomendado si el módulo los recibe
  storage_account_name  = local.common_vars.azure.storage_account_name
  container_name        = local.common_vars.azure.storage_container_name

  tags = {
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}
