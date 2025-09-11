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

  # Permitir validar/planear sin haber aplicado el env aún
  mock_outputs = {
    aca_environment_id = "dummy-env-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 📦 Repositorio del módulo Terraform (container_app)
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git//modules/container_app?ref=main"
}

# Entradas del módulo (sin secretos por ahora)
inputs = {
  # ---- Contexto provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                 = "${local.common_vars.project_name}-sonarqube-${local.common_vars.environment}"
  resource_group_name  = local.common_vars.rg_roles.apps
  environment_id       = dependency.aca_environment.outputs.aca_environment_id

  # ---- Imagen (desde tu ACR) ----
  image = "precreditacrdesarrollo.azurecr.io/sonarqube:latest"

  # ---- Recursos ----
  container_cpu    = 1
  container_memory = "2Gi"

  # ---- Ingress (interno; APIM/lo que definas al frente) ----
  target_port       = 9000
  ingress_external  = false
  ingress_transport = "auto"

  # ---- Identidad (MSI por defecto) ----
  system_identity            = true
  user_assigned_identity_ids = []

  # ---- Variables de entorno ----
  env_vars = {
    SONARQUBE_WEB_JAVAOPTS = "-Xms512m -Xmx512m"
  }

  # ---- Secretos (AÚN NO configurados) ----
  secrets = []
  secret_env_map = {}

  # ---- Registry (si usas MI + AcrPull, no pongas nada) ----
  # registry_server          = null
  # registry_username        = null
  # registry_password_secret = null
  # registry_password_value  = null

  # ---- Escalado ----
  min_replicas     = 1
  max_replicas     = 1
  http_concurrency = 60

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
