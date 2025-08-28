include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  prefix               = local.common_vars.project_name
  location             = local.common_vars.azure.region
  resource_group_name   = local.common_vars.rg_roles.network
  subscription_id      = local.common_vars.azure.subscription_id
  tenant_id            = local.common_vars.azure.tenant_id

  allowed_ssh_cidr     = "10.0.0.0/24"
  allowed_sql_cidr     = "10.0.1.0/24"

  # Nombres de subnets que el módulo usará para construir los NSG
  subnet1_name = local.common_vars.network.subnet1_name
  subnet2_name = local.common_vars.network.subnet2_name
  subnet3_name = local.common_vars.network.subnet3_name
  subnet4_name = local.common_vars.network.subnet4_name

  tags = {
    Tipo_Recurso  = "NSG"
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}
