// Data block to get current client configuration
data "azurerm_client_config" "current" {}

//
// Generate a random integer to append to resource names for uniqueness
//
resource "random_integer" "unique_id" {
  min = 10000
  max = 99999
}

//
// Resource Group
//
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

//
// Virtual Network and Subnets
//
resource "azurerm_virtual_network" "vnet" {
  name                = "acme-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "private-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_subnet_address_prefix]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vpn_subnet_address_prefix]
}

//
// App Service Plans for the two applications
//
resource "azurerm_app_service_plan" "backend_plan" {
  name                = "acme-backend-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "App"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service_plan" "middleware_plan" {
  name                = "acme-middleware-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "App"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

//
// Web Apps: Backend (publicly accessible) and Middleware (accessed via private endpoint)
//
resource "azurerm_app_service" "backend_app" {
  name                = "acme-backend-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.backend_plan.id

  site_config {
    // Additional app settings can be specified here
  }
}

resource "azurerm_app_service" "middleware_app" {
  name                = "acme-middleware-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.middleware_plan.id

  site_config {
    // Additional app settings can be specified here
  }
}

//
// Key Vault and Customer Managed Key for SQL Database encryption
//
resource "azurerm_key_vault" "kv" {
  name                        = "acme-kv-${random_integer.unique_id.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_enabled         = true
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
      "list",
      "update",
      "delete",
      "backup",
      "restore",
      "import",
      "recover"
    ]
  }
}

resource "azurerm_key_vault_key" "cmk" {
  name         = "acme-cmk"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048
}

//
// Azure SQL Server and Database with TDE using CMK
//
resource "azurerm_sql_server" "sql_server" {
  name                         = "acmesqlserver${random_integer.unique_id.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "P@ssw0rd1234!"  // Use secure secret management in production
}

resource "azurerm_sql_database" "sql_db" {
  name                = "acme-sqldb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql_server.name
  sku_name            = "S0"
  max_size_bytes      = "1073741824" // 1GB for demo purposes
  zone_redundant      = false
}

resource "azurerm_mssql_server_key" "sql_cmk" {
  server_id        = azurerm_sql_server.sql_server.id
  key_vault_key_id = azurerm_key_vault_key.cmk.id
  key_type         = "AzureKeyVault"

  depends_on = [
    azurerm_key_vault.kv,
    azurerm_sql_server.sql_server
  ]
}

//
// Private Endpoints for secure connectivity
//

// Private Endpoint for Middleware Web App (to be accessed by the Backend app via Private Link)
resource "azurerm_private_endpoint" "middleware_pe" {
  name                = "acme-middleware-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "middleware-connection"
    private_connection_resource_id = azurerm_app_service.middleware_app.id
    subresource_names              = ["sites"]  // For App Services, the subresource is typically "sites"
    is_manual_connection           = false
  }
}

// Private Endpoint for SQL Server (so that only the Middleware app can access the database via Private Link)
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "acme-sql-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_sql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

//
// Optional: VPN Gateway for on-premises connectivity
//
resource "azurerm_public_ip" "vpn_public_ip" {
  name                = "acme-vpn-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "acme-vpn-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configurations {
    name                 = "vnetGatewayConfig"
    public_ip_address_id = azurerm_public_ip.vpn_public_ip.id
    subnet_id            = azurerm_subnet.gateway_subnet.id
  }
}
