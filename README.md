# Acme Corporation Azure Infrastructure Deployment

This repository contains a Terraform project that sets up the infrastructure for migrating Acme Corporation's e-commerce API solution to the Azure West Europe data center. The solution includes:
- **Backend Web App:** Publicly accessible via Azure App Service.
- **Middleware Web App:** Accessed privately using Azure Private Link.
- **Azure SQL Database:** Secured with Transparent Data Encryption (TDE) and Customer Managed Keys (CMK) stored in Key Vault.
- **Networking:** Virtual Network (VNet) with dedicated subnets for private endpoints and VPN Gateway for secure on-premises connectivity.

## Prerequisites

Before getting started, ensure you have the following:
- **Terraform (>=1.0):** Installed and configured.
- **Azure CLI:** For authentication (run `az login`).
- **Active Azure Subscription:** You need access to an Azure subscription.
- **Git (optional):** To clone the repository.

## Setup Steps

### 1. Clone the Repository
Clone this repository to your local machine:
```bash
git clone https://github.com/mallikrao1/Technical-Assessment-.git
cd Technical-Assessment
az login
az account set --subscription "your-subscription-id"
terrafom init
terraform plain
terraform apply




