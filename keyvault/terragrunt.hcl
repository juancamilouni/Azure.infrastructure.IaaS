# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  # Si prefieres más robusto, usa find_in_parent_folders("common_vars.yaml")
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 🔗 Dependencia: networking (para resolver subnet_ids)
dependency "networking" {
  config_path = "../networking"
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  # Provider
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id

  # Recurso
  name                = "kv-${local.common_vars.project_name}-${local.common_vars.environment}"
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.rg_roles.apps

  # Seguridad y operación
  sku_name                   = "standard"
  soft_delete_retention_days = 30
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  # Público por ahora (sin PE, no rompe egress de tus contenedores)
  public_network_access_enabled = true


    # Firewall: Deny por defecto, permitir AzureServices, tus IPs y TODAS las subnets de la VNet
  network_acls_default_action  = "Deny"
  network_acls_bypass          = "AzureServices"
  network_acls_ip_rules        = try(local.common_vars.security.allowed_ips, [])

  # TODAS las subnets exportadas por tu módulo de red
  network_acls_vnet_subnet_ids = values(dependency.networking.outputs.subnet_ids)


  tags = {
    Environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
    Tipo_Recurso= "KeyVault"
  }
}