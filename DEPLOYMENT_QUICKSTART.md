# FireProof Production Deployment - Quick Start

## Prerequisites Checklist

Before running the deployment:

- [ ] Azure CLI installed and logged in
- [ ] PowerShell 7.0+ installed
- [ ] Decided on globally unique App Service name
- [ ] Have SQL Server details ready (server name, admin credentials)
- [ ] Code built and tested locally
- [ ] All tests passing (93/93)

## Step 1: Login to Azure with Management Scope

```bash
az login --scope https://management.core.windows.net//.default
```

**Verify login**:
```bash
az account show
```

## Step 2: Decide on Names

You need to choose these values (must be globally unique):

```powershell
$AppServiceName = "fireproof-api-prod"  # Must be unique across all Azure
$ResourceGroup = "rg-fireproof"
$SqlServerName = "sqltest"  # Your existing SQL Server (without .database.windows.net)
$DatabaseName = "FireProofDB"
```

**Test if App Service name is available**:
```bash
az webapp list --query "[?name=='fireproof-api-prod'].name" -o tsv
```
If this returns nothing, the name is available.

## Step 3: Run Complete Deployment Script

This single script does tasks 1-12:

```powershell
cd /mnt/d/dev2/fireproof

# Run deployment
.\scripts\Deploy-Production.ps1 `
    -Environment Production `
    -AppName "fireproof-api-prod" `
    -SqlServer "sqltest" `
    -ResourceGroup "rg-fireproof" `
    -Location "eastus"
```

**What this does** (automatically):
1. ✅ Verifies Azure login
2. ✅ Creates/verifies resource group
3. ✅ Runs Key Vault setup (generates secure secrets)
4. ✅ Creates App Service Plan
5. ✅ Creates App Service
6. ✅ Enables Managed Identity
7. ✅ Grants Key Vault access
8. ✅ Configures app settings
9. ✅ Updates appsettings.Production.json
10. ✅ Configures SQL firewall
11. ✅ Builds and deploys application
12. ✅ Verifies deployment

**Expected Duration**: ~10 minutes

**During Key Vault setup, you'll be prompted for**:
- Database connection string (paste your full connection string)

Example:
```
Server=sqltest.database.windows.net;Database=FireProofDB;User Id=admin;Password=***;TrustServerCertificate=True;Encrypt=True
```

## Step 4: Verify Deployment

```bash
# Check if app is running
curl https://fireproof-api-prod.azurewebsites.net/health

# View logs
az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof
```

**Expected**: HTTP 200 with "Healthy" response

## Step 5: Run Post-Deployment Configuration

This script handles tasks 8-11:

```powershell
.\scripts\Configure-PostDeployment.ps1 `
    -SqlServer "sqltest" `
    -Database "FireProofDB" `
    -AppName "fireproof-api-prod" `
    -ResourceGroup "rg-fireproof"
```

**What this does**:
8. ✅ Enables TDE on database (if Azure SQL)
9. ✅ Configures automated backups (long-term retention)
10. ✅ Creates Application Insights
11. ✅ Provides SQL script to remove dev users

**Expected Duration**: ~5 minutes

## Step 6: Clean Up Dev Test Users

Run the SQL script provided by the post-deployment script:

```bash
# Using sqlcmd
sqlcmd -S sqltest.database.windows.net -d FireProofDB -U admin -P '***' -i cleanup-users.sql

# OR use Azure Data Studio / SSMS
```

The script shows you which users will be affected before deletion.

## Step 7: Test Authentication

```bash
# Test user registration
curl -X POST https://fireproof-api-prod.azurewebsites.net/api/authentication/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@company.com",
    "password": "SecurePass123!",
    "firstName": "Test",
    "lastName": "User"
  }'

# Test login
curl -X POST https://fireproof-api-prod.azurewebsites.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@company.com",
    "password": "SecurePass123!"
  }'
```

**Expected**: JWT tokens returned with 200 OK

## Troubleshooting

### Issue: "App Service name already exists"

Choose a different name and run again.

### Issue: "Database connection failed"

Check:
1. SQL Server firewall includes App Service IPs
2. Connection string in Key Vault is correct
3. SQL Server allows Azure services

**View firewall rules**:
```bash
az sql server firewall-rule list --server sqltest --resource-group rg-fireproof
```

### Issue: "Key Vault access denied"

Verify Managed Identity has access:
```bash
# Get principal ID
az webapp identity show --name fireproof-api-prod --resource-group rg-fireproof

# Verify access policy
az keyvault show --name kv-fireproof-prod --query properties.accessPolicies
```

### Issue: "Health check returns 503"

The app is still starting. Wait 30-60 seconds and try again.

View logs:
```bash
az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof
```

## Rollback

If something goes wrong:

```bash
# Stop the app
az webapp stop --name fireproof-api-prod --resource-group rg-fireproof

# Check logs
az webapp log download --name fireproof-api-prod --resource-group rg-fireproof

# Delete app (keeps Key Vault and data)
az webapp delete --name fireproof-api-prod --resource-group rg-fireproof

# Re-run deployment script
```

## Success Checklist

Deployment is successful when:

- [x] Health endpoint returns 200 OK
- [x] Application Insights receiving data
- [x] User registration works
- [x] User login works
- [x] JWT tokens validated
- [x] Authorization enforced (test with invalid token)
- [x] Logs showing Key Vault connection
- [x] Logs showing "TamperProofing service initialized"
- [x] No hardcoded secrets in logs
- [x] DevMode endpoint disabled (returns 404)

## Next Steps

After successful deployment:

1. **Set up continuous deployment** (GitHub Actions or Azure DevOps)
2. **Configure custom domain** with SSL certificate
3. **Set up monitoring alerts** for your operations team
4. **Create runbook** for common operations tasks
5. **Document disaster recovery** procedures
6. **Build UI components** for the frontend
7. **Implement Service Provider** multi-tenancy feature

## Support

- **Documentation**: `/docs/PRODUCTION_DEPLOYMENT.md`
- **Troubleshooting**: `/docs/KEYVAULT_SETUP.md#troubleshooting`
- **Security**: `/docs/SECURITY_HARDENING.md`
