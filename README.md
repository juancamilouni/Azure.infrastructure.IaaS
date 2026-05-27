# Precredit Azure Infrastructure – Terragrunt

# Propósito del repositorio

El repositorio Azure.infrastructure.IaaS contiene la orquestación y configuración por ambiente necesaria para desplegar la infraestructura de Precredit en Azure.

Está construido sobre Terragrunt, una capa de automatización sobre Terraform que facilita la reutilización de módulos, la gestión de estados remotos y la definición de dependencias entre recursos.

Este repositorio no define recursos de Azure directamente; en su lugar consume los módulos del repositorio Azure.Modules.infrastructure y los despliega en los ambientes dev, qa, pre-prod y prod.

---

# Tipo de infraestructura

Precredit utiliza un enfoque híbrido que combina recursos IaaS y servicios PaaS.

## Recursos IaaS

- Redes virtuales (Virtual Network)
- Grupos de seguridad (NSG)
- Grupos de recursos
- Direcciones IP públicas
- Cuentas de almacenamiento

Estos recursos proporcionan la base de conectividad, segmentación de red y seguridad para la plataforma.

## Servicios PaaS

- Azure Container Apps
- Azure API Management
- Azure Key Vault
- Azure Application Gateway
- Azure Static Web Apps
- Azure Database for PostgreSQL Flexible Server
- Azure Cosmos DB for MongoDB

La plataforma utiliza PostgreSQL Flexible Server y Cosmos DB para la persistencia de información transaccional, almacenamiento de datos de aplicación y manejo de logs.

Los ambientes dev, qa y prod mantienen la misma estructura lógica y esquemas definidos por la aplicación, permitiendo consistencia entre entornos, facilidad en pruebas funcionales y simplificación de despliegues y migraciones.

La combinación de IaaS y PaaS permite aprovechar el control de infraestructura en componentes críticos mientras se reducen tareas operativas mediante servicios administrados de Azure.

---

# Estructura del repositorio

La raíz del repositorio contiene los siguientes elementos clave:

## Carpetas por módulo

Cada subdirectorio corresponde a un módulo que se desea desplegar:

- networking
- nsg
- keyvault
- containerapps_core
- containerapps_gateway
- application_gateway
- apim_backend_api
- entre otros

Cada carpeta incluye únicamente un archivo terragrunt.hcl que define cómo y con qué parámetros se invoca el módulo.

---

## terragrunt_azure.hcl

Archivo de configuración común que genera automáticamente:

- backend.tf
- provider.tf
- versions.tf

para todos los módulos.

Define:

- Backend remoto usando Azure Storage
- Proveedor azurerm
- Autenticación OIDC

De esta manera no es necesario repetir configuraciones en cada módulo y se centralizan las versiones mínimas de los providers.

---

## common_vars.template.yaml

Plantilla de variables comunes que define parámetros como:

- Nombre del proyecto
- Región de Azure
- Subredes
- Rangos IP
- Tamaños de bases de datos
- Configuración de PostgreSQL
- Configuración de Cosmos DB
- Variables de Container Apps
- Nombres de recursos

Durante los workflows de GitHub Actions esta plantilla se transforma en common_vars.yaml reemplazando variables con valores obtenidos desde GitHub Secrets y Variables.

---

## .github/workflows/

Contiene los workflows principales:

- terragrunt-deploy.yml
- terragrunt-destroy.yml

Estos workflows automatizan el despliegue y destrucción de módulos en cada ambiente.

---

# terragrunt.hcl de cada módulo

El archivo terragrunt.hcl de cada carpeta sigue un patrón común.

## Inclusión de configuración base

```hcl
include {
  path = find_in_parent_folders("terragrunt_azure.hcl")
}
```

Esto incorpora:

- Backend remoto
- Provider de Azure
- Configuración global de Terragrunt

---

## Dependencias

Las dependencias se declaran cuando un módulo requiere salidas de otro módulo.

Ejemplos:

- networking depende de nsg
- containerapps_core depende de containerapps_environment
- application_gateway depende de networking
- PostgreSQL y Cosmos DB dependen de networking y private endpoints

Esto garantiza el orden correcto de despliegue.

---

## Carga de variables comunes

```hcl
locals {
  common_vars = yamldecode(file("../common_vars.yaml"))
}
```

Permite reutilizar configuraciones compartidas entre ambientes.

---

## Referencia al módulo remoto

```hcl
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure//networking?ref=v0.1.0"
}
```

Durante los workflows este valor se sobrescribe dinámicamente con un token temporal para descargar el módulo privado correspondiente.

---

## Inputs

Los parámetros del módulo se asignan mediante el bloque inputs.

Ejemplo:

```hcl
inputs = {
  location            = local.common_vars.azure.region
  resource_group_name = local.common_vars.rg_roles.network
  subscription_id     = local.common_vars.azure.subscription_id
  tenant_id           = local.common_vars.azure.tenant_id
}
```

---

# Gestión del estado y autenticación

Todos los estados de Terraform se almacenan en Azure Storage.

La clave de cada estado se construye utilizando:

```hcl
path_relative_to_include()
```

Esto asegura que cada módulo tenga su propio archivo terraform.tfstate.

---

## Autenticación OIDC

El proveedor de Azure se configura utilizando autenticación OIDC.

Ventajas:

- No se almacenan credenciales estáticas
- Se utilizan tokens efímeros
- Mayor seguridad
- Menor exposición de secretos

También se incluye el provider azapi para recursos avanzados de Azure.

---

# Workflows de CI/CD con GitHub Actions

Los workflows automatizan tanto despliegues como destrucciones de infraestructura.

---

# terragrunt-deploy.yml

## Desencadenador

Se ejecuta mediante:

```yaml
repository_dispatch
```

con el tipo:

```yaml
deploy-module
```

El payload incluye:

- module
- version
- environment

---

## Variables y secretos

El workflow consume:

### Secrets

- ARM_CLIENT_ID
- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID
- GH_APP_PRIVATE_KEY
- SQL_ADMIN_PASSWORD
- COSMOS_DB_KEYS
- entre otros

### Variables

- AZURE_REGION
- NETWORK_ADDRESS_SPACE
- POSTGRES_SKU
- COSMOS_DB_NAME
- STORAGE_ACCOUNT_NAME
- etc.

Estas variables son procesadas mediante:

```bash
envsubst
```

para generar common_vars.yaml.

---

## Descarga del módulo

El workflow genera un token temporal mediante GitHub App:

```bash
INSTALL_TOKEN
```

Este token permite clonar el repositorio privado Azure.Modules.infrastructure.

---

## Ejecución de Terragrunt

El flujo principal ejecuta:

```bash
terragrunt init
terragrunt validate
terragrunt plan
terragrunt apply -auto-approve
```

También gestiona:

- Bloqueos de estado
- Force unlock
- Validaciones
- Logs de despliegue

---

# terragrunt-destroy.yml

## Desencadenador

Se ejecuta manualmente mediante:

```yaml
workflow_dispatch
```

Parámetros requeridos:

- module
- version
- environment

---

## Proceso

El workflow:

1. Realiza checkout
2. Inicia sesión en Azure
3. Genera common_vars.yaml
4. Descarga el módulo
5. Ejecuta:

```bash
terragrunt destroy
```

en modo no interactivo.

También maneja:

- Bloqueos
- Logs
- Errores
- Limpieza de estados

---

# Variables y secretos

Toda la información sensible se almacena mediante:

- GitHub Secrets
- GitHub Variables

---

## Secrets

Contienen información confidencial:

- CLIENT_ID
- TENANT_ID
- DATA_SUBSCRIPTION_ID
- SQL_ADMIN_PASSWORD
- POSTGRES_ADMIN_PASSWORD
- COSMOS_DB_CONNECTION_STRING
- GH_APP_PRIVATE_KEY

---

## Variables

Definen configuraciones por ambiente:

- AZURE_REGION
- SKU de PostgreSQL
- Configuración de Cosmos DB
- Nombres de subredes
- Rangos IP
- Storage Accounts
- Límites de presupuesto

---

# Conexión con el repositorio de módulos

Este repositorio consume los módulos definidos en:

```text
Azure.Modules.infrastructure
```

---

## Referencia de origen

Cada terragrunt.hcl apunta a un módulo específico:

```hcl
terraform {
  source = "git::https://github.com/juancamilouni/Azure.Modules.infrastructure//<modulo>?ref=<version>"
}
```

Durante el workflow esta URL se actualiza dinámicamente para incluir:

- Token temporal
- Versión requerida

Esto garantiza despliegues reproducibles y controlados.

---

## Variables comunes

Los nombres de variables definidos en:

- variables.tf
- common_vars.yaml

mantienen consistencia entre repositorios.

---

## Dependencias

Terragrunt gestiona dependencias entre módulos como:

- networking
- nsg
- keyvault
- postgres
- cosmosdb
- containerapps_environment
- application_gateway

Esto asegura que los recursos base existan antes del despliegue de servicios dependientes.

---

# Flujo de trabajo típico

## 1. Creación o actualización de módulos

Se desarrolla o modifica un módulo dentro de:

```text
Azure.Modules.infrastructure
```

Luego se genera una nueva versión:

```text
v0.X.Y
```

---

## 2. Configuración del despliegue

Se crea o actualiza el archivo:

```text
terragrunt.hcl
```

indicando:

- módulo
- versión
- dependencias
- variables

---

## 3. Ejecución del workflow

Se dispara:

```yaml
repository_dispatch
```

El workflow:

- genera common_vars.yaml
- descarga el módulo
- inicializa Terraform/Terragrunt
- despliega la infraestructura

---

## 4. Destrucción opcional

Se ejecuta:

```yaml
terragrunt-destroy.yml
```

para eliminar recursos de ambientes de prueba o temporales.

---

# Conclusión

El repositorio Azure.infrastructure.IaaS actúa como la capa de orquestación de la infraestructura de Precredit.

La separación entre:

- módulos reutilizables
- configuración por ambiente
- workflows CI/CD

permite:

- reutilización de código
- despliegues consistentes
- control de versiones
- automatización segura
- gobernanza centralizada

La integración de PostgreSQL Flexible Server y Cosmos DB for MongoDB complementa la arquitectura permitiendo persistencia escalable y consistente entre ambientes dev, qa y prod.

Combinado con GitHub Actions, Terragrunt y autenticación OIDC, el proyecto logra despliegues reproducibles, seguros y alineados con buenas prácticas modernas de infraestructura como código.