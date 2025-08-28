# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure..git/<modulo>?ref=main"
}

inputs = {
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
  location            = local.common_vars.azure.region
  resource_group_name = "${local.common_vars.project_name}-rg"
  
  tags = {
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = "Precredit"
  }
}
