output "resource_group" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "backend_app_url" {
  description = "The default hostname of the Backend Web App"
  value       = azurerm_app_service.backend_app.default_site_hostname
}

output "middleware_app_url" {
  description = "The default hostname of the Middleware Web App"
  value       = azurerm_app_service.middleware_app.default_site_hostname
}

output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_sql_server.sql_server.name
}

output "sql_database_name" {
  description = "The name of the SQL Database"
  value       = azurerm_sql_database.sql_db.name
}
