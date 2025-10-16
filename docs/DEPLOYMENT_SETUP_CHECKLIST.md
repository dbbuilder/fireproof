# FireProof Deployment Setup Checklist

This checklist guides you through the one-time setup required to enable automated deployments to staging and production.

## Prerequisites Checklist

- [ ] Azure subscription with Contributor access
- [ ] GitHub repository admin access
- [ ] Azure CLI installed (`az --version`)
- [ ] .NET 8.0 SDK installed (`dotnet --version`)
- [ ] SQL Server tools installed (`sqlcmd -?`)
- [ ] Git configured with repository access

## Part 1: Azure Infrastructure Setup

### Step 1: Create Staging Environment Resources

```bash
# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Create staging resource group
az group create --name rg-fireproof-staging --location eastus

# Create App Service Plan (B1 tier for staging)
az appservice plan create \
  --name asp-fireproof-staging \
  --resource-group rg-fireproof-staging \
  --sku B1 \
  --is-linux

# Create App Service for Backend API
az webapp create \
  --name fireproof-api-staging \
  --resource-group rg-fireproof-staging \
  --plan asp-fireproof-staging \
  --runtime "DOTNETCORE:8.0"

# Create SQL Server
az sql server create \
  --name fireproof-sql-staging \
  --resource-group rg-fireproof-staging \
  --location eastus \
  --admin-user sqladmin \
  --admin-password 'YOUR_SECURE_PASSWORD_HERE'

# Create SQL Database (S1 tier for staging)
az sql db create \
  --resource-group rg-fireproof-staging \
  --server fireproof-sql-staging \
  --name FireProofDB-Staging \
  --service-objective S1

# Allow Azure services to access SQL Server
az sql server firewall-rule create \
  --resource-group rg-fireproof-staging \
  --server fireproof-sql-staging \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create Static Web App for Frontend
az staticwebapp create \
  --name fireproof-frontend-staging \
  --resource-group rg-fireproof-staging \
  --location eastus

# Create Application Insights
az monitor app-insights component create \
  --app fireproof-appinsights-staging \
  --location eastus \
  --resource-group rg-fireproof-staging \
  --application-type web

# Create Storage Account for photos
az storage account create \
  --name fireproofstaging \
  --resource-group rg-fireproof-staging \
  --location eastus \
  --sku Standard_LRS
```

**Record these values:**
- [ ] App Service URL: `https://fireproof-api-staging.azurewebsites.net`
- [ ] SQL Server: `fireproof-sql-staging.database.windows.net,1433`
- [ ] SQL Database: `FireProofDB-Staging`
- [ ] SQL Username: `sqladmin`
- [ ] SQL Password: `[your password]`
- [ ] Static Web App URL: `[shown in Azure Portal]`

### Step 2: Create Production Environment Resources

```bash
# Create production resource group
az group create --name rg-fireproof-prod --location eastus

# Create App Service Plan (P1V2 tier for production)
az appservice plan create \
  --name asp-fireproof-prod \
  --resource-group rg-fireproof-prod \
  --sku P1V2 \
  --is-linux

# Create App Service for Backend API
az webapp create \
  --name fireproof-api-prod \
  --resource-group rg-fireproof-prod \
  --plan asp-fireproof-prod \
  --runtime "DOTNETCORE:8.0"

# Create SQL Server
az sql server create \
  --name fireproof-sql-prod \
  --resource-group rg-fireproof-prod \
  --location eastus \
  --admin-user sqladmin \
  --admin-password 'YOUR_SECURE_PASSWORD_HERE'

# Create SQL Database (S3 tier for production)
az sql db create \
  --resource-group rg-fireproof-prod \
  --server fireproof-sql-prod \
  --name FireProofDB-Production \
  --service-objective S3

# Allow Azure services to access SQL Server
az sql server firewall-rule create \
  --resource-group rg-fireproof-prod \
  --server fireproof-sql-prod \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create Static Web App for Frontend
az staticwebapp create \
  --name fireproof-frontend-prod \
  --resource-group rg-fireproof-prod \
  --location eastus

# Create Application Insights
az monitor app-insights component create \
  --app fireproof-appinsights-prod \
  --location eastus \
  --resource-group rg-fireproof-prod \
  --application-type web

# Create Storage Account for photos
az storage account create \
  --name fireproofprod \
  --resource-group rg-fireproof-prod \
  --location eastus \
  --sku Standard_LRS
```

**Record these values:**
- [ ] App Service URL: `https://fireproof-api-prod.azurewebsites.net`
- [ ] SQL Server: `fireproof-sql-prod.database.windows.net,1433`
- [ ] SQL Database: `FireProofDB-Production`
- [ ] SQL Username: `sqladmin`
- [ ] SQL Password: `[your password]`
- [ ] Static Web App URL: `[shown in Azure Portal]`

### Step 3: Configure App Service Settings

**Staging:**
```bash
az webapp config appsettings set \
  --name fireproof-api-staging \
  --resource-group rg-fireproof-staging \
  --settings \
    "ASPNETCORE_ENVIRONMENT=Staging" \
    "ConnectionStrings__DefaultConnection=Server=tcp:fireproof-sql-staging.database.windows.net,1433;Initial Catalog=FireProofDB-Staging;Persist Security Info=False;User ID=sqladmin;Password=YOUR_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
    "Jwt__SecretKey=GENERATE_32_CHARACTER_SECRET_KEY" \
    "TamperProofing__SignatureKey=GENERATE_32_CHARACTER_SECRET_KEY"
```

**Production:**
```bash
az webapp config appsettings set \
  --name fireproof-api-prod \
  --resource-group rg-fireproof-prod \
  --settings \
    "ASPNETCORE_ENVIRONMENT=Production" \
    "ConnectionStrings__DefaultConnection=Server=tcp:fireproof-sql-prod.database.windows.net,1433;Initial Catalog=FireProofDB-Production;Persist Security Info=False;User ID=sqladmin;Password=YOUR_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
    "Jwt__SecretKey=GENERATE_32_CHARACTER_SECRET_KEY" \
    "TamperProofing__SignatureKey=GENERATE_32_CHARACTER_SECRET_KEY"
```

**Generate secure keys with:**
```bash
openssl rand -base64 32
```

## Part 2: GitHub Repository Setup

### Step 4: Download Publish Profiles

**Staging:**
1. Navigate to Azure Portal > App Services > `fireproof-api-staging`
2. Click **Deployment Center** in left menu
3. Click **Manage publish profile**
4. Click **Download publish profile**
5. Save as `staging-publish-profile.PublishSettings`

**Production:**
1. Navigate to Azure Portal > App Services > `fireproof-api-prod`
2. Click **Deployment Center**
3. Click **Manage publish profile**
4. Click **Download publish profile**
5. Save as `production-publish-profile.PublishSettings`

### Step 5: Get Static Web App Deployment Tokens

**Staging:**
```bash
az staticwebapp secrets list \
  --name fireproof-frontend-staging \
  --resource-group rg-fireproof-staging \
  --query "properties.apiKey" -o tsv
```
Save this token as `STAGING_STATIC_WEB_APP_TOKEN`

**Production:**
```bash
az staticwebapp secrets list \
  --name fireproof-frontend-prod \
  --resource-group rg-fireproof-prod \
  --query "properties.apiKey" -o tsv
```
Save this token as `PRODUCTION_STATIC_WEB_APP_TOKEN`

### Step 6: Configure GitHub Secrets

Navigate to your GitHub repository:
**Settings > Secrets and variables > Actions > New repository secret**

Add the following secrets:

#### Backend Secrets
- [ ] `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING` - Contents of `staging-publish-profile.PublishSettings`
- [ ] `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION` - Contents of `production-publish-profile.PublishSettings`

#### Frontend Secrets - Staging
- [ ] `AZURE_STATIC_WEB_APPS_API_TOKEN_STAGING` - Token from Step 5
- [ ] `STAGING_API_BASE_URL` - `https://fireproof-api-staging.azurewebsites.net/api`
- [ ] `STAGING_AZURE_AD_B2C_AUTHORITY` - Your Azure AD B2C authority URL
- [ ] `STAGING_AZURE_AD_B2C_CLIENT_ID` - Your Azure AD B2C client ID
- [ ] `STAGING_FRONTEND_URL` - Static Web App URL from Azure Portal

#### Frontend Secrets - Production
- [ ] `AZURE_STATIC_WEB_APPS_API_TOKEN_PRODUCTION` - Token from Step 5
- [ ] `PRODUCTION_API_BASE_URL` - `https://fireproof-api-prod.azurewebsites.net/api`
- [ ] `PRODUCTION_AZURE_AD_B2C_AUTHORITY` - Your Azure AD B2C authority URL
- [ ] `PRODUCTION_AZURE_AD_B2C_CLIENT_ID` - Your Azure AD B2C client ID
- [ ] `PRODUCTION_FRONTEND_URL` - Static Web App URL from Azure Portal

#### Database Secrets - Staging
- [ ] `STAGING_SQL_SERVER` - `fireproof-sql-staging.database.windows.net,1433`
- [ ] `STAGING_SQL_DATABASE` - `FireProofDB-Staging`
- [ ] `STAGING_SQL_USERNAME` - `sqladmin`
- [ ] `STAGING_SQL_PASSWORD` - Your SQL password

#### Database Secrets - Production
- [ ] `PRODUCTION_SQL_SERVER` - `fireproof-sql-prod.database.windows.net,1433`
- [ ] `PRODUCTION_SQL_DATABASE` - `FireProofDB-Production`
- [ ] `PRODUCTION_SQL_USERNAME` - `sqladmin`
- [ ] `PRODUCTION_SQL_PASSWORD` - Your SQL password

### Step 7: Configure GitHub Environments

1. Navigate to **Settings > Environments**
2. Click **New environment**
3. Create environment named `staging`:
   - No additional configuration needed
4. Create environment named `production`:
   - Enable **Required reviewers**
   - Add yourself and team members as reviewers
   - Set **Deployment branches** to `main` only

### Step 8: Create Branch Protection Rules

1. Navigate to **Settings > Branches**
2. Click **Add rule** for `main` branch:
   - [ ] Check "Require a pull request before merging"
   - [ ] Check "Require approvals" (at least 1)
   - [ ] Check "Require status checks to pass before merging"
   - [ ] Add status checks: "Backend Tests", "Frontend Tests"
   - [ ] Check "Require branches to be up to date before merging"

3. Click **Add rule** for `develop` branch:
   - [ ] Check "Require status checks to pass before merging"
   - [ ] Add status checks: "Backend Tests", "Frontend Tests"

## Part 3: Database Initialization

### Step 9: Run Initial Database Migrations

**Staging:**
```bash
# Connect to staging database
sqlcmd -S fireproof-sql-staging.database.windows.net,1433 \
  -d FireProofDB-Staging \
  -U sqladmin \
  -P YOUR_PASSWORD \
  -C

# Or run via GitHub Actions:
# 1. Go to Actions > Deploy Database Migrations
# 2. Select 'staging' environment
# 3. Enter migration scripts: "001_CreateCoreSchema.sql,002_CreateTenantSchema.sql,002b_CreateTenantSchema_Part2.sql,005_CreateSchedulingTables.sql"
# 4. Run workflow
```

**Production:**
```bash
# Connect to production database
sqlcmd -S fireproof-sql-prod.database.windows.net,1433 \
  -d FireProofDB-Production \
  -U sqladmin \
  -P YOUR_PASSWORD \
  -C

# Or run via GitHub Actions (same steps as staging)
```

**Required migration scripts (in order):**
1. `001_CreateCoreSchema.sql` - Core tables (Tenants, Users, AuditLog)
2. `002_CreateTenantSchema.sql` - Tenant tables (Locations, Extinguishers, ExtinguisherTypes)
3. `002b_CreateTenantSchema_Part2.sql` - Inspections, Photos, Maintenance
4. `005_CreateSchedulingTables.sql` - Scheduling features
5. `FIX_PROCEDURE_PARAMETERS.sql` - Stored procedure parameter fixes
6. `FIX_MISSING_COLUMNS.sql` - Column mapping fixes

### Step 10: Seed Test Data (Staging Only)

```bash
# Connect to staging database
sqlcmd -S fireproof-sql-staging.database.windows.net,1433 \
  -d FireProofDB-Staging \
  -U sqladmin \
  -P YOUR_PASSWORD \
  -C \
  -i scripts/seed-test-data.js

# Or manually insert test data via SQL scripts
```

## Part 4: Verification

### Step 11: Test Staging Deployment

**Trigger first deployment:**
```bash
git checkout develop
git pull origin develop
git commit --allow-empty -m "chore: Trigger initial staging deployment"
git push origin develop
```

**Monitor deployment:**
1. Go to GitHub **Actions** tab
2. Watch "Deploy Backend to Staging" and "Deploy Frontend to Staging" workflows
3. Verify both complete successfully (green checkmarks)

**Verify staging environment:**
```bash
# Test API health
curl https://fireproof-api-staging.azurewebsites.net/api/health

# Test frontend
curl -I https://[your-static-web-app-url]
```

### Step 12: Test Production Deployment (Dry Run)

**DO NOT push to main yet!** First verify staging works completely.

Once staging is verified:
```bash
git checkout main
git merge develop
git push origin main
```

**Monitor deployment:**
1. Go to GitHub **Actions** tab
2. If you configured required reviewers, approve the deployment
3. Watch "Deploy Backend to Production" and "Deploy Frontend to Production" workflows
4. Verify both complete successfully

**Verify production environment:**
```bash
# Test API health
curl https://fireproof-api-prod.azurewebsites.net/api/health

# Test frontend
curl -I https://[your-production-url]

# Run E2E tests against production
cd frontend/fire-extinguisher-web
VITE_API_BASE_URL=https://fireproof-api-prod.azurewebsites.net/api npm run test:e2e
```

Expected: 24/24 tests passing

## Part 5: Configure Monitoring and Alerts

### Step 13: Set Up Application Insights Alerts

**Create alert for high error rate:**
```bash
az monitor metrics alert create \
  --name "High API Error Rate" \
  --resource-group rg-fireproof-prod \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-fireproof-prod/providers/Microsoft.Web/sites/fireproof-api-prod" \
  --condition "count requests/failed > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

**Create alert for slow response time:**
```bash
az monitor metrics alert create \
  --name "Slow API Response Time" \
  --resource-group rg-fireproof-prod \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-fireproof-prod/providers/Microsoft.Web/sites/fireproof-api-prod" \
  --condition "avg requests/duration > 2000" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Step 14: Configure Log Streaming

**Enable application logging:**
```bash
# Staging
az webapp log config \
  --name fireproof-api-staging \
  --resource-group rg-fireproof-staging \
  --application-logging filesystem \
  --level information

# Production
az webapp log config \
  --name fireproof-api-prod \
  --resource-group rg-fireproof-prod \
  --application-logging filesystem \
  --level warning
```

**View logs:**
```bash
# Staging
az webapp log tail --name fireproof-api-staging --resource-group rg-fireproof-staging

# Production
az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof-prod
```

## Completion Checklist

- [ ] All Azure resources created for staging
- [ ] All Azure resources created for production
- [ ] App Service settings configured
- [ ] GitHub secrets configured
- [ ] GitHub environments created
- [ ] Branch protection rules set
- [ ] Database migrations run on staging
- [ ] Database migrations run on production
- [ ] Test data seeded in staging
- [ ] First staging deployment successful
- [ ] First production deployment successful
- [ ] E2E tests passing against staging (24/24)
- [ ] E2E tests passing against production (24/24)
- [ ] Application Insights alerts configured
- [ ] Log streaming enabled
- [ ] Team notified of deployment process

## Next Steps

1. **Create runbooks** for common operational tasks
2. **Set up monitoring dashboards** in Azure Portal
3. **Document incident response procedures**
4. **Schedule regular backup verification tests**
5. **Review and update DEPLOYMENT_GUIDE.md** with any environment-specific details

## Support

For issues during setup:
- Review `docs/DEPLOYMENT_GUIDE.md` for detailed troubleshooting
- Check GitHub Actions logs for deployment errors
- Review Azure Portal logs for runtime errors
- Contact DevOps team for assistance

---

**Document Version:** 1.0
**Setup Time:** Approximately 2-3 hours
**Last Updated:** 2025-01-15
