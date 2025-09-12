# 🔗 Backend & provider centralizados
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
}

# 🔗 Dependencia: ACA Environment (para obtener aca_environment_id)
dependency "aca_environment" {
  config_path = "../containerapps_environment"

  mock_outputs = {
    aca_environment_id = "dummy-env-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 🔗 Dependencia: UAMI (la identidad reutilizable con AcrPull)
dependency "uami" {
  config_path  = "../identity"  # <- ajusta la ruta a tu terragrunt de identity
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform (container_app)
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  # ---- Contexto provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                = "containersonarqubedev"
  resource_group_name = local.common_vars.rg_roles.apps
  environment_id      = dependency.aca_environment.outputs.aca_environment_id

  # ---- Imagen (desde tu ACR) ----
  image = "precreditacrdesarrollo.azurecr.io/sonarqube:latest"

  # ---- Recursos ----
  container_cpu    = 1
  container_memory = "2Gi"

  # ---- Ingress interno (APIM al frente) ----
  target_port       = 9000
  ingress_external  = false
  ingress_transport = "auto"

  # ---- Identidad: usar SOLO la UAMI ----
  system_identity            = false
  user_assigned_identity_ids = [ dependency.uami.outputs.uami_id ]

  # ---- Variables de entorno ----
  env_vars = {
    SONARQUBE_WEB_JAVAOPTS = "-Xms512m -Xmx512m"
  }

  # ---- Secretos (cuando los tengas en KV) ----
  secrets        = []
  secret_env_map = {}

  # ---- Escalado ----
  min_replicas     = 1
  max_replicas     = 1
  http_concurrency = 60

  # ---- Revisión ----
  revision_mode = "single" # el módulo lo normaliza a "Single"

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
