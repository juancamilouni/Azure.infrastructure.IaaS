# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencia: ACA Environment (para obtener environment_id)
dependency "aca_environment" {
  # Ajusta a donde tengas el terragrunt del ACA Environment
  config_path = "../containerapps_environment"

  # Permite validar/planear sin tener aplicado el env todavía
  mock_outputs = {
    environment_id = "dummy-env-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# Entradas del módulo (SIN secretos por ahora)
inputs = {
  # ---- Contexto provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                = "${local.common_vars.project_name}-sonarqube-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.apps

  # ✅ Toma el primer output disponible entre varios nombres típicos
  environment_id = try(
    dependency.aca_environment.outputs.environment_id,
    dependency.aca_environment.outputs.aca_environment_id,
    dependency.aca_environment.outputs.container_app_environment_id,
    dependency.aca_environment.outputs.containerapps_environment_id,
    dependency.aca_environment.outputs.container_app_env_id,
    dependency.aca_environment.outputs.id
  )

  # ---- Imagen (desde tu ACR) ----
  image = "precreditacrdesarrollo.azurecrdesarrollo.azurecr.io/sonarqube:latest"
  # Si el login server es 'precreditacrdesarrollo.azurecr.io', corrige a:
  # image = "precreditacrdesarrollo.azurecr.io/sonarqube:latest"

  # ---- (Opcional) Workload profile (si tu ACA Env v2 lo usa) ----
  workload_profile_name = try(local.common_vars.aca.workload_profile_name, null)

  # ---- Identidad (MSI por defecto) ----
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []

  # ---- Ingress (interno; APIM/lo que definas al frente) ----
  ingress_enabled            = true
  ingress_external           = false
  target_port                = 9000
  ingress_transport          = "auto"
  allow_insecure_connections = false

  # ---- Recursos (ajusta si lo necesitas más potente) ----
  cpu    = 1
  memory = "2.0Gi"

  # ---- Variables de entorno (claras) ----
  env_vars = {
    SONARQUBE_WEB_JAVAOPTS = "-Xms512m -Xmx512m"
  }

  # ---- Secretos (AÚN NO configurados) ----
  secret_env_map = {}
  secrets        = []

  # ---- Registry ----
  registry = null  # Usaremos MSI + rol AcrPull (se asigna luego)

  # ---- Escalado ----
  min_replicas = 1
  max_replicas = 1

  # ---- Tags ----
  tags = {
    Tipo_Recurso = "ACA-APP"
    environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
    managed_by   = "terragrunt"
    component    = "sonarqube"
  }
}
