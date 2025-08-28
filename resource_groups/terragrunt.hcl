# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  subscription_id      = local.common.azure.subscription_id
  tenant_id            = local.common.azure.tenant_id
  location             = local.common.azure.region
  resource_group_names = values(local.common.rg_roles)

  tags = {
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}
