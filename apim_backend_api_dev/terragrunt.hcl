# apim_backend_api_dev/terragrunt.hcl
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

dependency "apim" {
  config_path  = "../apim_instance_public_dev"
  skip_outputs = false
}

terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  # Provider
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # Contexto APIM
  resource_group_name = local.common_vars.rg_roles.apps
  apim_name           = dependency.apim.outputs.apim_name

  # Backend: apunta a tu Container App
  backend_name = "backend-sonarqube"
  backend_url  = "https://containersonarqubedev.mangosand-1896af9c.eastus2.azurecontainerapps.io"

  # API expuesta en APIM
  api_name         = "api-sonarqube-dev"
  api_display_name = "SonarQube API (dev)"
  api_path         = "sonarqube"   # "" si quieres en raíz

  openapi_spec_url          = ""
  api_subscription_required = true

  # Vincular a Product existente
  product_id = "plan-precredit-desarrollo"

  # Habilitar CORS solo si lo necesitas
  enable_cors          = true
  cors_allowed_origins = ["https://frontend.midominio.com"]
}
