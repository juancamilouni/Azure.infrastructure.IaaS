# 🔗 Backend & provider centralizados
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 🔗 Dependencia: ACA Environment
dependency "aca_environment" {
  config_path = "../containerapps_environment"

  mock_outputs = {
    aca_environment_id = "dummy-env-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 🔗 Dependencia: Identidad UAMI
dependency "identity" {
  config_path  = "../identity"
  skip_outputs = false
}

# 🔗 Dependencia: Role Assignment (para asegurar AcrPull antes de desplegar)
dependency "role_assignment" {
  config_path  = "../role_assignment"
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# 🎯 Entradas del módulo
inputs = {
  # ---- Contexto provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                = "precredit-product-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.apps
  environment_id      = dependency.aca_environment.outputs.aca_environment_id

  # ---- Imagen (desde tu ACR) ----
  image = "acrprecreditqa.azurecr.io/precredit-products-qa:latest"

  # ---- Recursos ----
  container_cpu    = 0.5
  container_memory = "1Gi"

  # ---- Ingress ----
  target_port       = 8080
  ingress_external  = true
  ingress_transport = "auto"

  # ---- Identidad (desactiva UAMI temporalmente) ----
  system_identity            = false
  user_assigned_identity_ids = []

  # ---- Registro (usa admin username + password) ----
  registry_server          = "acrprecreditqa.azurecr.io"
  registry_username        = "acrprecreditqa"
  registry_password_secret = "acr-password"
  registry_password_value  = "HZBTnoYKFSlGHp8JC2SFzbPLL7vL3Dh9povu51zK1j+ACRBigM0W"

  # ---- Escalado ----
  min_replicas     = 1
  max_replicas     = 3
  http_concurrency = 60

  # ---- Revisión ----
  revision_mode = "single"

  # ---- Tags ----
  tags = {
    Tipo_Recurso = "ACA-APP"
    environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
    component    = "sonarqube"
    managed_by   = "terragrunt"
  }
}

