# FireProof Production Deployment - Command Reference

## Quick Setup (Copy & Paste)

**Subscription**: Test Environment (7b2beff3-b38a-4516-a75f-3216725cc4e9)

### 1. Set Variables

```powershell
# Set your deployment configuration
$ResourceGroup = "rg-fireproof"
$Location = "eastus"
$AppName = "fireproof-api-test"  # Change this to be globally unique
$AppServicePlan = "asp-fireproof-prod"
$SqlServer = "sqltest"
$SqlDatabase = "FireProofDB"
$KeyVaultName = "kv-fireproof-prod"
$Environment = "Production"
```

### 2. Create Resource Group

```bash
az group create --name $ResourceGroup --location $Location
```

### 3. Run Key Vault Setup

```powershell
cd /mnt/d/dev2/fireproof
./scripts/Setup-AzureKeyVault.ps1 -Environment $Environment -ResourceGroup $ResourceGroup -Location $Location
```

**Save the Key Vault URI from output!**

### 4. Update appsettings.Production.json

Edit: `backend/FireExtinguisherInspection.API/appsettings.Production.json`

```json
{
  "KeyVault": {
    "VaultUri": "https://kv-fireproof-prod.vault.azure.net/"
  }
}
```

### 5. Create App Service

```bash
# Create plan
az appservice plan create \
  --name $AppServicePlan \
  --resource-group $ResourceGroup \
  --location $Location \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --name $AppName \
  --resource-group $ResourceGroup \
  --plan $AppServicePlan \
  --runtime "DOTNETCORE:8.0"
```

### 6. Enable Managed Identity & Grant Access

```bash
# Enable identity
az webapp identity assign --name $AppName --resource-group $ResourceGroup

# Get principal ID
$PrincipalId = az webapp identity show \
  --name $AppName \
  --resource-group $ResourceGroup \
  --query principalId -o tsv

# Grant Key Vault access
az keyvault set-policy \
  --name $KeyVaultName \
  --object-id $PrincipalId \
  --secret-permissions get list
```

### 7. Configure App Settings

```bash
# Set environment
az webapp config appsettings set \
  --name $AppName \
  --resource-group $ResourceGroup \
  --settings ASPNETCORE_ENVIRONMENT=Production

# Enable logging
az webapp log config \
  --name $AppName \
  --resource-group $ResourceGroup \
  --application-logging filesystem \
  --level information
```

### 8. Configure SQL Firewall

```bash
az sql server firewall-rule create \
  --resource-group $ResourceGroup \
  --server $SqlServer \
  --name "AllowAllAzureIPs" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 9. Build & Deploy

```powershell
cd /mnt/d/dev2/fireproof

# Build
dotnet publish backend/FireExtinguisherInspection.API -c Release -o ./publish

# Package
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy
az webapp deployment source config-zip \
  --name $AppName \
  --resource-group $ResourceGroup \
  --src ./deploy.zip

# Cleanup
Remove-Item ./publish -Recurse -Force
Remove-Item ./deploy.zip -Force
```

### 10. Verify Deployment

```powershell
# Wait for app to start
Start-Sleep -Seconds 30

# Test health endpoint
Invoke-WebRequest -Uri "https://$AppName.azurewebsites.net/health"

# Or with curl
curl https://$AppName.azurewebsites.net/health
```

### 11. View Logs

```bash
az webapp log tail --name $AppName --resource-group $ResourceGroup
```

## Post-Deployment Tasks

### Enable TDE (if Azure SQL)

```bash
az sql db tde set \
  --database $SqlDatabase \
  --server $SqlServer \
  --resource-group $ResourceGroup \
  --status Enabled
```

### Configure Backups

```bash
az sql db ltr-policy set \
  --database $SqlDatabase \
  --server $SqlServer \
  --resource-group $ResourceGroup \
  --weekly-retention "P4W" \
  --monthly-retention "P12M" \
  --yearly-retention "P7Y" \
  --week-of-year 1
```

### Set Up Application Insights

```bash
# Create workspace
$WorkspaceName = "$AppName-logs"
az monitor log-analytics workspace create \
  --workspace-name $WorkspaceName \
  --resource-group $ResourceGroup \
  --location $Location

# Get workspace ID
$WorkspaceId = az monitor log-analytics workspace show \
  --workspace-name $WorkspaceName \
  --resource-group $ResourceGroup \
  --query id -o tsv

# Create Application Insights
$AppInsightsName = "$AppName-insights"
az monitor app-insights component create \
  --app $AppInsightsName \
  --location $Location \
  --resource-group $ResourceGroup \
  --workspace $WorkspaceId

# Get connection string
$ConnectionString = az monitor app-insights component show \
  --app $AppInsightsName \
  --resource-group $ResourceGroup \
  --query connectionString -o tsv

# Update app settings
az webapp config appsettings set \
  --name $AppName \
  --resource-group $ResourceGroup \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="$ConnectionString"
```

### Remove Dev Test Users

```sql
-- Connect to FireProofDB and run:
USE FireProofDB;
GO

-- Soft delete dev users
UPDATE dbo.Users
SET IsActive = 0, ModifiedDate = GETUTCDATE()
WHERE Email LIKE '%@dev.local'
   OR Email LIKE '%@test.local'
   OR Email LIKE '%example.com%';
GO

-- Verify
SELECT COUNT(*) as ActiveDevUsers
FROM dbo.Users
WHERE (Email LIKE '%@dev.local' OR Email LIKE '%@test.local' OR Email LIKE '%example.com%')
AND IsActive = 1;
GO
```

## Troubleshooting

### Check App Service Status

```bash
az webapp show --name $AppName --resource-group $ResourceGroup --query state
```

### Restart App Service

```bash
az webapp restart --name $AppName --resource-group $ResourceGroup
```

### Download Logs

```bash
az webapp log download --name $AppName --resource-group $ResourceGroup
```

### Test Endpoints

```bash
# Health check
curl https://$AppName.azurewebsites.net/health

# Register user
curl -X POST https://$AppName.azurewebsites.net/api/authentication/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@company.com","password":"SecurePass123!","firstName":"Test","lastName":"User"}'

# Login
curl -X POST https://$AppName.azurewebsites.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@company.com","password":"SecurePass123!"}'
```

## Rollback

```bash
# Stop app
az webapp stop --name $AppName --resource-group $ResourceGroup

# Delete and recreate
az webapp delete --name $AppName --resource-group $ResourceGroup
# Then re-run deployment steps
```

## Production Checklist

- [ ] Resource group created
- [ ] Key Vault created with secrets
- [ ] appsettings.Production.json updated
- [ ] App Service created
- [ ] Managed Identity enabled
- [ ] Key Vault access granted
- [ ] App settings configured
- [ ] SQL firewall configured
- [ ] Application deployed
- [ ] Health check passing
- [ ] TDE enabled
- [ ] Backups configured
- [ ] Application Insights set up
- [ ] Dev users removed
- [ ] Authentication tested
- [ ] Authorization tested
