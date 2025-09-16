# 🔗 Backend/provider común
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 🔗 Dependencia: instancia APIM (para apim_name + product_id)
dependency "apim" {
  config_path  = "../apim_instance_public_dev"
  skip_outputs = false
}

# 📦 Origen del módulo (ruta de tu repo)
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# 🎯 Entradas
inputs = {
  # Provider
  subscription_id = local.common.azure.subscription_id
  tenant_id       = local.common.azure.tenant_id

  # Contexto APIM
  resource_group_name = local.common.resource_groups.rg_apps
  apim_name           = dependency.apim.outputs.apim_name

  # Backend (tu ACA público en DEV)
  backend_name = "backend-${local.common.project_name}"                 
  backend_url  = "https://containersonarqubedev.mangosand-1896af9c.eastus2.azurecontainerapps.io"

  # API (elige un base-path único para evitar colisiones)
  api_name         = "api-${local.common.project_name}-${local.common.environment}"   # "api-precredit-desarrollo"
  api_display_name = "${local.common.project_name}-API-${local.common.environment}"   # "precredit-API-desarrollo"
  api_path         = "sonarqube"                                                       # EJEMPLO: tu app sirve en '/'

  # OpenAPI (opcional)
  openapi_spec_url          = ""
  api_subscription_required = true

  # Product: lo reutilizamos del módulo de instancia
  product_id = dependency.apim.outputs.product_id  # "plan-precredit-desarrollo"

  # CORS (opcional)
  enable_cors          = false
  cors_allowed_origins = ["http://localhost:3000"]
}
