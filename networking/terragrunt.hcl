# 🔗 Incluye el archivo base que configura el backend y el provider
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}

# 🔗 Dependencia: NSG (debe haberse desplegado antes)
dependency "nsg" {
  config_path = "../nsg"
  skip_outputs = false
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
  vnet_name           = "${local.common_vars.project_name}-networking-${local.common_vars.environment}"
  location             = local.common_vars.azure.region
  resource_group_name   = local.common_vars.rg_roles.network
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
  address_space = local.common_vars.network.address_space
  enable_network_watcher  = false  # 👈 Añadido aquí

  subnets = [
    {
      name             = local.common_vars.network.subnet1_name
      address_prefixes = local.common_vars.network.subnet1_address_prefix
      network_security_group_id  = dependency.nsg.outputs.nsg_subnet1_id
    },
    {
      name             = local.common_vars.network.subnet2_name
      address_prefixes = local.common_vars.network.subnet2_address_prefix
      network_security_group_id  = dependency.nsg.outputs.nsg_subnet2_id
    },
    {
      name             = local.common_vars.network.subnet3_name
      address_prefixes = local.common_vars.network.subnet3_address_prefix
      network_security_group_id  = dependency.nsg.outputs.nsg_subnet3_id
    },
    {
      name             = local.common_vars.network.subnet4_name
      address_prefixes = local.common_vars.network.subnet4_address_prefix
      network_security_group_id  = dependency.nsg.outputs.nsg_subnet4_id
    }
  ]
  
  tags = {
    Tipo_Recurso  = "VirtualNetwork"
    environment = local.common_vars.environment
    Owner       = "juan.uni@doublevpartners.com"
    Project     = local.common_vars.project_name
  }
}

