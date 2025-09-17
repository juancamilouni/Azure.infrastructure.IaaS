# 🔗 Backend/provider común
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 🔗 Dependencia de la instancia APIM (donde ya se creó Product/suscripción)
dependency "apim" {
  config_path  = "../apim_instance_public_dev"
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  resource_group_name = local.common_vars.rg_roles.api
  apim_name           = dependency.apim.outputs.apim_name

  backend_name = "backend-${local.common_vars.project_name}"
  backend_url  = "https://precredit-gateway-desarrollo.ambitioustree-c50c7bc2.eastus2.azurecontainerapps.io"

  api_name        = "api-${local.common_vars.project_name}-${local.common_vars.environment}"
  api_display_name = "${local.common_vars.project_name}-API-${local.common_vars.environment}"
  api_path        = "api"

  openapi_spec_url          = ""
  api_subscription_required = false

  create_product              = false
  product_id                  = "plan-${local.common_vars.project_name}-${local.common_vars.environment}"
  product_display_name        = "Plan ${local.common_vars.project_name}-${local.common_vars.environment}"
  product_subscription_required = false
  product_approval_required     = false

  enable_wildcard_operations = true
  wildcard_methods           = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
  enable_rewrite_uri         = true
}
