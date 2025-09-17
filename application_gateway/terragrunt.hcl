# 🔗 Incluye el backend/provider común
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
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
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.rg_roles.network

  # ---- Red ----
  subnet_id = local.common_vars.subnets.appgw
  capacity  = 2

  # ---- Dominios ----
  web_domain = "www.${local.common_vars.domain}"
  api_domain = "api.${local.common_vars.domain}"

  # ---- Backends ----
  swa_fqdn  = local.common_vars.apps.static_webapp_fqdn
  apim_fqdn = local.common_vars.apps.apim_fqdn

  # ---- Certificado ----
  ssl_cert = null

  # ---- Tags obligatorios ----
  tags = {
    Environment  = local.common_vars.environment
    Owner        = "juan.uni@doublevpartners.com"
    Project      = local.common_vars.project_name
    Tipo_Recurso = "ApplicationGateway"
  }
}
