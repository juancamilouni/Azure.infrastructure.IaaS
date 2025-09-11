# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencia: ACA Environment
dependency "aca_environment" {
  config_path = "../containerapps_environment"

  # Permite validate/plan si aún no se aplicó el env
  mock_outputs = {
    aca_environment_id = "dummy-env-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# 📦 Módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# Entradas del módulo (SIN secretos por ahora)
inputs = {
  # ---- Provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                = "${local.common_vars.project_name}-sonarqube-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.apps
  environment_id      = dependency.aca_environment.outputs.aca_environment_id  # 👈 usa el nombre real del output

  # ---- Imagen (ACR) ----
  image = "precreditacrdesarrollo.azurecr.io/sonarqube:latest"

  # ---- (Opcional) Workload profile ----
  workload_profile_name = try(local.common_vars.aca.workload_profile_name, null)

  # ---- Identidad ----
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []

  # ---- Ingress (interno) ----
  ingress_enabled            = true
  ingress_external           = false
  target_port                = 9000
  ingress_transport          = "auto"
  allow_insecure_connections = false

  # ---- Recursos ----
  cpu    = 1
  memory = "2.0Gi"

  # ---- Env (claras) ----
  env_vars = {
    SONARQUBE_WEB_JAVAOPTS = "-Xms512m -Xmx512m"
  }

  # ---- Secretos (no usados aún) ----
  secret_env_map = {}
  secrets        = []

  # ---- Registry ----
  registry = null  # usarás MSI + AcrPull

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
