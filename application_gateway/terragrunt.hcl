# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencias
dependency "networking" {
  config_path = "../networking"
  skip_outputs = false
}

dependency "swa" {
  config_path = "../static_web_app"
  skip_outputs = false
}

dependency "apim" {
  config_path = "../apim_backend_api_dev"
  skip_outputs = false
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

# 🎯 Entradas del módulo
inputs = {
  # ---- Contexto Provider ----
  subscription_id = local.common_vars.azure.subscription_id
  tenant_id       = local.common_vars.azure.tenant_id

  # ---- Identificación ----
  name                = "agw-${local.common_vars.project_name}-${local.common_vars.environment}"
  resource_group_name = local.common_vars.rg_roles.network
  location            = local.common_vars.azure.region

  # ---- Red ----
  subnet_id = try(
    dependency.networking.outputs.subnet_ids[local.common_vars.network.subnet_appgw_name],
    null
  )
  capacity = 2

  # ---- Dominios ----
  web_domain = "www.${local.common_vars.domain}"
  api_domain = "api.${local.common_vars.domain}"

  # ---- Backends ----
  swa_fqdn  = dependency.swa.outputs.swa_default_host
  apim_fqdn = dependency.apim.outputs.apim_gateway_url

  # ---- Certificado ----
  ssl_cert = null

  # ---- Tags obligatorios ----
  tags = {
    Tipo_Recurso = "ApplicationGateway"
    Environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
  }
}
