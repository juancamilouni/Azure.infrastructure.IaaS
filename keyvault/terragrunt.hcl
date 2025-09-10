# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  # Si prefieres más robusto, usa find_in_parent_folders("common_vars.yaml")
  common_vars = yamldecode(file("../common_vars.yaml"))
}


# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id

  name                = "kv-${local.common_vars.project_name}"
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.resource_group

  sku_name                   = "standard"
  soft_delete_retention_days = 30
  purge_protection_enabled   = true
  rbac_authorization_enabled = true
  public_network_access_enabled = true # cámbialo cuando agregues Private Endpoint

  tags = {
    Environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
    Tipo_Recurso= "KeyVault"
  }
}
