# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  # Si prefieres más robusto, usa find_in_parent_folders("common_vars.yaml")
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencias
dependency "identity" {
  config_path  = "../identity"
  skip_outputs = false
}

dependency "acr" {
  # Apunta al terragrunt de tu ACR (donde tengas el módulo ACR)
  config_path  = "../Containerregistries"
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# GUID built-in de AcrPull:
# 7f951dda-4ed3-4680-a7ca-43fe172d538d
inputs = {
  subscription_id    = local.common_vars.azure.subscription_id
  tenant_id          = local.common_vars.azure.tenant_id

  scope              = dependency.acr.outputs.acr_id
  role_definition_id = "/subscriptions/${local.common_vars.azure.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
  principal_id       = dependency.identity.outputs.uami_principal_id
}
