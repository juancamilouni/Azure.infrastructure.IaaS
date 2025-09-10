# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  # Si prefieres más robusto, usa find_in_parent_folders("common_vars.yaml")
  common_vars = yamldecode(file("../common_vars.yaml"))
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
  resource_group_name = local.common_vars.rg_roles.secmon

  # Seguridad y operación
  sku_name                   = "standard"
  soft_delete_retention_days = 30
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  # Público por ahora (sin PE, no rompe egress de tus contenedores)
  public_network_access_enabled = true

  # 🔒 ACLs (firewall KV): Deny por defecto, permitir solo lo que necesitas
  network_acls_default_action  = "Deny"
  network_acls_bypass          = "AzureServices"

  # (Opcional) IPs de CI/oficina desde el YAML
  network_acls_ip_rules = try(local.common_vars.security.allowed_ips, [])

  # Permitir la subnet donde vive ACA (p.ej. subnet3_name)
  network_acls_vnet_subnet_ids = [
    dependency.networking.outputs.subnet_ids[local.common_vars.network.subnet3_name]
  ]

  tags = {
    Environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
    Tipo_Recurso= "KeyVault"
  }
}