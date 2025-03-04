variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "acme-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "private_subnet_address_prefix" {
  description = "Address prefix for the private endpoints subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpn_subnet_address_prefix" {
  description = "Address prefix for the VPN gateway subnet"
  type        = string
  default     = "10.0.2.0/27"
}
