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

# Entradas del módulo
inputs = {
  # ---- Provider
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Recurso
  name                = "${local.common_vars.project_name}-aca-env-${local.common_vars.environment}"
  resource_group_name = local.common_vars.resource_groups.apps
  location            = local.common_vars.azure.region

  # ---- Observabilidad
  log_analytics_workspace_id = local.common_vars.monitor.log_analytics_id

  # ---- Red (privado vs público)
  infrastructure_subnet_id       = try(local.common_vars.network.subnets.containerapps, null)
  internal_load_balancer_enabled = false

  # ---- Alta disponibilidad
  zone_redundancy_enabled = false

  tags = {
    Tipo_Recurso  = "ACR"
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}