# 📥 Variables globales
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}

# 📦 Repositorio del módulo Terraform
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure.git/<modulo>?ref=main"
}

inputs = {
  apim_name             = "my-api-management-instance"
  location             = "East US"
  resource_group_name  = "my-resource-group"
  sku_name             = "Basic"
  sku_capacity         = 1
  publisher_name       = "My Company"
  publisher_email      = "company@example.com"
  tags                 = {
    Environment = "Dev"
  }
  api_names            = ["api1", "api2"]
  api_display_names    = ["API 1", "API 2"]
  api_paths            = ["/api1", "/api2"]
  api_service_urls     = ["https://api1.example.com", "https://api2.example.com"]
  api_operations       = ["getData", "postData"]
  api_operation_display_names = ["Get Data", "Post Data"]
  api_operation_methods = ["GET", "POST"]
  api_operation_url_templates = ["/data", "/data"]
}