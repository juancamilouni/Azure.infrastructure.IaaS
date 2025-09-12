# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 🔗 Dependencias
dependency "identity" {
  config_path  = "../identity"
  skip_outputs = false
}

dependency "acr" {
  config_path  = "../Containerregistries" # terragrunt del módulo ACR
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# 🎯 Entradas
inputs = {
  # Contexto provider (asegúrate de que common_vars.yaml use la suscripción correcta e700bb19-...)
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # Rol AcrPull sobre el ACR
  scope              = dependency.acr.outputs.acr_id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
  principal_id       = dependency.identity.outputs.uami_principal_id
}
