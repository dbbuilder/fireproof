# Azure Key Vault Setup Guide

This guide explains how to set up and use Azure Key Vault for secure secrets management in the FireProof API.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Setup Steps](#setup-steps)
- [Local Development](#local-development)
- [Production Deployment](#production-deployment)
- [Secret Management](#secret-management)
- [Troubleshooting](#troubleshooting)

## Overview

The FireProof API uses Azure Key Vault to securely store sensitive configuration values:

- **JwtSecretKey**: JWT token signing secret
- **TamperProofingSignatureKey**: HMAC signature key for tamper-proofing
- **DatabaseConnectionString**: SQL Server connection string

### Configuration Hierarchy

The application follows this priority for configuration values:

1. **Azure Key Vault** (if configured)
2. **appsettings.{Environment}.json**
3. **appsettings.json**

This allows local development without Key Vault while enforcing it in production.

## Prerequisites

- Azure CLI installed: https://aka.ms/installazurecli
- Azure subscription with permissions to create:
  - Resource Groups
  - Key Vaults
  - Set access policies
- PowerShell 7.0+ (for setup script)

## Setup Steps

### 1. Login to Azure

```bash
az login
```

### 2. Run the Setup Script

```powershell
# For Development environment
.\scripts\Setup-AzureKeyVault.ps1 -Environment Development

# For Staging environment
.\scripts\Setup-AzureKeyVault.ps1 -Environment Staging

# For Production environment
.\scripts\Setup-AzureKeyVault.ps1 -Environment Production -ResourceGroup rg-fireproof-prod
```

The script will:
- Create Resource Group (if needed)
- Create Key Vault
- Generate secure random secrets for JWT and TamperProofing
- Prompt for database connection string
- Store all secrets in Key Vault
- Grant your user account access to secrets

### 3. Update appsettings

Copy the Key Vault URI from the script output and add to the appropriate appsettings file:

**appsettings.Production.json**:
```json
{
  "KeyVault": {
    "VaultUri": "https://kv-fireproof-prod.vault.azure.net/"
  },
  "Authentication": {
    "DevModeEnabled": false
  }
}
```

**appsettings.Staging.json**:
```json
{
  "KeyVault": {
    "VaultUri": "https://kv-fireproof-stag.vault.azure.net/"
  },
  "Authentication": {
    "DevModeEnabled": true
  }
}
```

### 4. Configure Authentication

The application uses `DefaultAzureCredential` which tries authentication in this order:

1. **Environment variables** (for production)
2. **Managed Identity** (for Azure App Service)
3. **Azure CLI** (for local development)
4. **Visual Studio** (for local development)
5. **Visual Studio Code** (for local development)

## Local Development

### Option 1: Use appsettings.json (Recommended for Dev)

Keep using local configuration without Key Vault:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=FireProofDB;..."
  },
  "Jwt": {
    "SecretKey": "local-development-secret-key-minimum-32-characters",
    "Issuer": "FireProofAPI",
    "Audience": "FireProofApp"
  },
  "TamperProofing": {
    "SignatureKey": "local-dev-signature-key"
  },
  "Authentication": {
    "DevModeEnabled": true
  }
}
```

### Option 2: Use Key Vault Locally

1. Ensure you're logged in: `az login`
2. Add Key Vault URI to appsettings.Development.json
3. Run the application

The app will use your Azure CLI credentials to access Key Vault.

## Production Deployment

### Azure App Service

1. **Enable Managed Identity**:
   ```bash
   az webapp identity assign \
     --name <app-name> \
     --resource-group <resource-group>
   ```

2. **Get the Managed Identity Principal ID**:
   ```bash
   az webapp identity show \
     --name <app-name> \
     --resource-group <resource-group> \
     --query principalId -o tsv
   ```

3. **Grant Key Vault Access**:
   ```bash
   az keyvault set-policy \
     --name kv-fireproof-prod \
     --object-id <principal-id> \
     --secret-permissions get list
   ```

4. **Set Environment Variables** in App Service Configuration:
   ```
   ASPNETCORE_ENVIRONMENT=Production
   ```

5. **Verify** the KeyVault:VaultUri is in appsettings.Production.json

### Azure Container Apps

1. **Enable Managed Identity** during creation or update:
   ```bash
   az containerapp identity assign \
     --name <app-name> \
     --resource-group <resource-group> \
     --system-assigned
   ```

2. **Grant Access** (same as App Service step 3)

### Using Service Principal (Alternative)

If Managed Identity isn't available:

1. **Create Service Principal**:
   ```bash
   az ad sp create-for-rbac \
     --name "fireproof-api-prod" \
     --role Reader \
     --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group>
   ```

2. **Grant Key Vault Access**:
   ```bash
   az keyvault set-policy \
     --name kv-fireproof-prod \
     --spn <app-id> \
     --secret-permissions get list
   ```

3. **Set Environment Variables**:
   ```
   AZURE_CLIENT_ID=<app-id>
   AZURE_CLIENT_SECRET=<password>
   AZURE_TENANT_ID=<tenant-id>
   ```

## Secret Management

### View Secrets

```bash
# List all secrets
az keyvault secret list --vault-name kv-fireproof-prod

# Show a specific secret
az keyvault secret show --vault-name kv-fireproof-prod --name JwtSecretKey
```

### Update Secrets

```bash
# Update JWT secret
az keyvault secret set \
  --vault-name kv-fireproof-prod \
  --name JwtSecretKey \
  --value "new-secret-value"

# Update with file content
az keyvault secret set \
  --vault-name kv-fireproof-prod \
  --name DatabaseConnectionString \
  --file connection-string.txt
```

### Rotate Secrets

1. Generate new secret value
2. Update in Key Vault
3. No application restart needed - values are read on demand

### Backup Secrets

```bash
# Backup a secret
az keyvault secret backup \
  --vault-name kv-fireproof-prod \
  --name JwtSecretKey \
  --file jwt-secret-backup.blob
```

## Troubleshooting

### Error: "Azure Key Vault configured but secrets not loading"

**Solution**: Check authentication
```bash
# Verify you're logged in
az account show

# Test Key Vault access
az keyvault secret list --vault-name kv-fireproof-prod
```

### Error: "The user, group or application does not have secrets get permission"

**Solution**: Grant permissions
```bash
az keyvault set-policy \
  --name kv-fireproof-prod \
  --object-id <your-object-id> \
  --secret-permissions get list
```

### Error: "Connection string not found"

**Solution**: Verify secret name matches exactly
- Key Vault secret name: `DatabaseConnectionString`
- Fallback appsettings: `ConnectionStrings:DefaultConnection`

### App works locally but fails in Azure

**Checklist**:
1. Is Managed Identity enabled?
2. Does Managed Identity have Key Vault access?
3. Is `ASPNETCORE_ENVIRONMENT` set to `Production`?
4. Is KeyVault:VaultUri in appsettings.Production.json?
5. Check App Service logs for authentication errors

### View Application Logs

```bash
# Azure App Service
az webapp log tail --name <app-name> --resource-group <resource-group>

# Azure Container Apps
az containerapp logs show --name <app-name> --resource-group <resource-group>
```

## Security Best Practices

1. **Never commit secrets** to source control
2. **Use Managed Identity** in production (no credentials to manage)
3. **Limit access** - grant only necessary permissions (get/list, not set/delete)
4. **Enable soft-delete** on Key Vault (enabled by default)
5. **Enable purge protection** for production Key Vaults
6. **Rotate secrets** regularly (every 90 days recommended)
7. **Monitor access** with Azure Monitor and Log Analytics
8. **Use separate Key Vaults** for each environment

## Additional Resources

- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [DefaultAzureCredential](https://docs.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential)
- [Managed Identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
