# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  # Si prefieres más robusto, usa find_in_parent_folders("common_vars.yaml")
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencia: networking (para resolver subnet_ids)
dependency "networking" {
  config_path = "../networking"
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# Entradas del módulo
inputs = {
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  name                = "${local.common_vars.project_name}-aca-env-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.apps
  location            = local.common_vars.azure.region

  # Red (privado). Si no quieres privado, pasa null.
  infrastructure_subnet_id = try(
    dependency.networking.outputs.subnet_ids[local.common_vars.network.subnet3_name],
    null
  )

  internal_load_balancer_enabled = false

  # Alta disponibilidad
  zone_redundancy_enabled = false
# 🛑 NUEVO: Workload Profile
  workload_profiles = [
    {
      name      = "Dedicated-D4" # Ajuste según el perfil que utiliza
      min_nodes = 2
      max_nodes = 10
    }
  ]

  tags = {
    Tipo_Recurso = "ACA-ENV"
    environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
  }
}
