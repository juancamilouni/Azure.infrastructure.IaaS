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
  subscription_id = local.common.azure.subscription_id
  tenant_id       = local.common.azure.tenant_id
  name                = "${local.common.project_name}-aca-env-${local.common.environment}"
  resource_group_name = local.common.resource_groups.apps
  location            = local.common.azure.region

  log_analytics_workspace_id = local.common.monitor.log_analytics_id

  # Si quieres environment PRIVADO, pasa la subnet; si PÚBLICO, deja null.
  infrastructure_subnet_id       = try(local.common.network.subnets.containerapps, null)
  internal_load_balancer_enabled = false

  # ---- Alta disponibilidad
  zone_redundancy_enabled = false

  tags = {
    Tipo_Recurso = "ACA-ENV"
    environment  = local.common.environment
    Owner        = local.common.owner
    Project      = local.common.project_name
  }
}
