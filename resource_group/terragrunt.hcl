# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/ocrcsa/it_landing-zone-IaC.git//<modulo>?ref=main"
}

inputs = {
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
  location            = local.common_vars.azure.region
  resource_group_name = "${local.common_vars.project_name}-rg"
  
  tags = {
    Environment = "Desarollo"
    Owner       = "juan.uni@doublevpartners.com"
    Project     = "Precredit"
  }
}
