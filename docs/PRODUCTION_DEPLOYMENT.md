# FireProof API - Production Deployment Guide

## Pre-Deployment Checklist

Complete these steps **before** deploying to production:

### 1. Azure Key Vault Setup (30 minutes)

```powershell
# Run from project root
.\scripts\Setup-AzureKeyVault.ps1 -Environment Production -ResourceGroup rg-fireproof-prod
```

**What this does**:
- Creates Azure Key Vault: `kv-fireproof-prod`
- Generates cryptographically secure JWT secret (64 characters)
- Generates cryptographically secure tamper-proofing key (64 characters)
- Prompts for production database connection string
- Stores all secrets in Key Vault

**Output**: Note the Key Vault URI (e.g., `https://kv-fireproof-prod.vault.azure.net/`)

### 2. Update Production Configuration

Edit `appsettings.Production.json`:

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

**Verify**:
- KeyVault URI matches output from step 1
- DevModeEnabled is `false`
- No secrets in appsettings.Production.json

### 3. Build and Test Locally

```bash
# Set environment to Production
export ASPNETCORE_ENVIRONMENT=Production  # Linux/Mac
$env:ASPNETCORE_ENVIRONMENT="Production"  # Windows PowerShell

# Login to Azure (for local Key Vault access)
az login

# Build
dotnet build -c Release

# Run tests
dotnet test

# Test application startup
dotnet run --project backend/FireExtinguisherInspection.API
```

**Verify**:
- Application starts without errors
- Logs show "Azure Key Vault configured"
- Logs show secrets loaded from Key Vault
- /health endpoint returns 200 OK

## Deployment Options

### Option A: Azure App Service (Recommended)

#### Step 1: Create App Service

```bash
# Variables
RESOURCE_GROUP="rg-fireproof-prod"
APP_SERVICE_PLAN="asp-fireproof-prod"
WEB_APP_NAME="fireproof-api-prod"
LOCATION="eastus"

# Create App Service Plan (B1 or higher)
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNETCORE:8.0"
```

#### Step 2: Enable Managed Identity

```bash
# Enable system-assigned managed identity
az webapp identity assign \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP

# Get the principal ID (save this)
PRINCIPAL_ID=$(az webapp identity show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

echo "Managed Identity Principal ID: $PRINCIPAL_ID"
```

#### Step 3: Grant Key Vault Access

```bash
# Grant the managed identity access to Key Vault
az keyvault set-policy \
  --name kv-fireproof-prod \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

#### Step 4: Configure App Settings

```bash
# Set environment
az webapp config appsettings set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings ASPNETCORE_ENVIRONMENT=Production

# Configure logging
az webapp log config \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --application-logging filesystem \
  --level information
```

#### Step 5: Configure SQL Server Firewall

```bash
# Get App Service outbound IPs
az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query outboundIpAddresses -o tsv

# Add each IP to SQL Server firewall (or use Azure CLI)
az sql server firewall-rule create \
  --resource-group <sql-resource-group> \
  --server <sql-server-name> \
  --name "Allow-AppService" \
  --start-ip-address <ip> \
  --end-ip-address <ip>

# OR allow all Azure services
az sql server firewall-rule create \
  --resource-group <sql-resource-group> \
  --server <sql-server-name> \
  --name "AllowAllAzureIPs" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

#### Step 6: Deploy Application

```bash
# Build for production
dotnet publish backend/FireExtinguisherInspection.API -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .
cd ..

# Deploy to App Service
az webapp deployment source config-zip \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --src deploy.zip
```

#### Step 7: Verify Deployment

```bash
# Check application logs
az webapp log tail \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP

# Test health endpoint
curl https://$WEB_APP_NAME.azurewebsites.net/health

# Test API endpoint (should require authentication)
curl https://$WEB_APP_NAME.azurewebsites.net/api/locations
```

### Option B: Azure Container Apps

#### Step 1: Build Container Image

```bash
# Login to Azure Container Registry
az acr login --name <your-acr-name>

# Build and push image
docker build -t <your-acr-name>.azurecr.io/fireproof-api:latest .
docker push <your-acr-name>.azurecr.io/fireproof-api:latest
```

#### Step 2: Create Container App

```bash
# Create Container Apps environment
az containerapp env create \
  --name fireproof-env-prod \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Create Container App with managed identity
az containerapp create \
  --name fireproof-api-prod \
  --resource-group $RESOURCE_GROUP \
  --environment fireproof-env-prod \
  --image <your-acr-name>.azurecr.io/fireproof-api:latest \
  --target-port 8080 \
  --ingress external \
  --env-vars ASPNETCORE_ENVIRONMENT=Production \
  --system-assigned
```

#### Step 3: Configure (same as App Service steps 2-7)

## Post-Deployment Tasks

### 1. Enable SQL Server TDE

```sql
-- Connect to master database
USE master;
GO

-- Enable TDE
ALTER DATABASE FireProofDB SET ENCRYPTION ON;
GO

-- Verify encryption
SELECT DB_NAME(database_id) AS DatabaseName, encryption_state
FROM sys.dm_database_encryption_keys
WHERE DB_NAME(database_id) = 'FireProofDB';
-- encryption_state = 3 means encrypted
```

### 2. Configure Database Backups

```bash
# For Azure SQL Database - backups are automatic
# Configure retention policy
az sql db ltr-policy set \
  --resource-group <sql-resource-group> \
  --server <sql-server-name> \
  --database FireProofDB \
  --weekly-retention "P4W" \
  --monthly-retention "P12M" \
  --yearly-retention "P7Y" \
  --week-of-year 1
```

### 3. Remove Dev Test Users

```sql
-- Connect to FireProofDB
USE FireProofDB;
GO

-- Disable dev test users (don't delete - preserve audit trail)
UPDATE dbo.Users
SET IsActive = 0
WHERE Email LIKE '%@dev.local' OR Email LIKE '%@test.local';

-- Or delete if preferred
DELETE FROM dbo.Users
WHERE Email LIKE '%@dev.local' OR Email LIKE '%@test.local';
```

### 4. Set Up Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app fireproof-api-prod \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --workspace <log-analytics-workspace-id>

# Get instrumentation key
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --app fireproof-api-prod \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)

# Add to App Service
az webapp config appsettings set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$APPINSIGHTS_KEY"
```

### 5. Configure Monitoring Alerts

```bash
# Alert for failed requests
az monitor metrics alert create \
  --name "High Error Rate" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/<sub-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$WEB_APP_NAME" \
  --condition "count Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m

# Alert for high response time
az monitor metrics alert create \
  --name "High Response Time" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/<sub-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$WEB_APP_NAME" \
  --condition "avg HttpResponseTime > 2000" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Verification Checklist

After deployment, verify:

- [ ] Application starts successfully
- [ ] Health endpoint returns 200 OK
- [ ] Logs show Key Vault connection
- [ ] Authentication endpoints work (login, register)
- [ ] Authorization enforced (403 for unauthorized)
- [ ] Database connection works
- [ ] HTTPS enforced (HTTP redirects)
- [ ] CORS configured correctly
- [ ] DevMode endpoint disabled (returns 404 or 403)
- [ ] Application Insights receiving data
- [ ] Alerts configured and active
- [ ] Backups running successfully
- [ ] TDE enabled on database

## Rollback Plan

If issues occur:

1. **Stop the App Service**:
   ```bash
   az webapp stop --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
   ```

2. **Check Logs**:
   ```bash
   az webapp log download --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
   ```

3. **Revert to Previous Deployment**:
   ```bash
   # List deployments
   az webapp deployment list --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

   # Redeploy previous version
   az webapp deployment source config-zip --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --src previous-deploy.zip
   ```

4. **Restart**:
   ```bash
   az webapp start --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
   ```

## Support and Monitoring

### View Logs

```bash
# Real-time logs
az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# Download logs
az webapp log download --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --log-file logs.zip
```

### Application Insights Queries

```kusto
// Failed requests in last hour
requests
| where timestamp > ago(1h)
| where success == false
| summarize count() by resultCode, operation_Name

// Slow requests
requests
| where timestamp > ago(1h)
| where duration > 2000
| project timestamp, name, duration, resultCode
| order by duration desc

// Authentication failures
traces
| where timestamp > ago(1h)
| where message contains "Authorization failed"
| summarize count() by bin(timestamp, 5m)
```

## Troubleshooting

### Key Vault Access Issues

**Symptom**: "Azure Key Vault configured but secrets not loading"

**Solution**:
1. Verify Managed Identity is enabled
2. Verify Key Vault access policy includes the Managed Identity
3. Check appsettings.Production.json has correct VaultUri
4. Verify ASPNETCORE_ENVIRONMENT is set to "Production"

### Database Connection Issues

**Symptom**: "Cannot connect to SQL Server"

**Solution**:
1. Verify firewall rules include App Service IPs
2. Check connection string in Key Vault is correct
3. Verify SQL Server allows Azure services
4. Test connection from Azure Portal Query Editor

### Authentication Not Working

**Symptom**: "JWT token invalid" or "401 Unauthorized"

**Solution**:
1. Verify JwtSecretKey is in Key Vault
2. Verify secret name is exactly "JwtSecretKey"
3. Check Jwt:Issuer and Jwt:Audience match between token generation and validation
4. Verify token hasn't expired (60 minute default)

## Next Steps

After successful deployment:

1. [Build UI Components](./UI_DEVELOPMENT.md)
2. [Implement Service Provider Multi-Tenancy](./SERVICE_PROVIDER_SPEC.md)
3. [Configure CI/CD Pipeline](./CICD_SETUP.md)
