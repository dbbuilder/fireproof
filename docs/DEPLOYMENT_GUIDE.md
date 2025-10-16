# FireProof Deployment Guide

This guide provides comprehensive instructions for deploying the FireProof application to staging and production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Staging Deployment](#staging-deployment)
5. [Production Deployment](#production-deployment)
6. [Database Migration](#database-migration)
7. [Rollback Procedures](#rollback-procedures)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Azure Resources

**Staging Environment:**
- Azure App Service: `fireproof-api-staging` (Linux, B1 or higher)
- Azure Static Web App: For frontend hosting
- Azure SQL Database: `FireProofDB-Staging` (S1 or higher)
- Azure Key Vault: `fireproof-kv-staging`
- Azure Application Insights: `fireproof-appinsights-staging`
- Azure Storage Account: `fireproofstaging` (for photo storage)

**Production Environment:**
- Azure App Service: `fireproof-api-prod` (Linux, P1V2 or higher)
- Azure Static Web App: For frontend hosting
- Azure SQL Database: `FireProofDB-Production` (S3 or higher)
- Azure Key Vault: `fireproof-kv-prod`
- Azure Application Insights: `fireproof-appinsights-prod`
- Azure Storage Account: `fireproofprod` (for photo storage)

### Required Tools

- Azure CLI (`az`)
- .NET 8.0 SDK
- Node.js 20.x
- sqlcmd (SQL Server command-line tools)
- Git

### Access Requirements

- Azure subscription with Contributor access
- GitHub repository with Actions enabled
- SQL Server admin credentials
- Azure AD B2C tenant configuration

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Push to 'develop' branch  →  Staging Deployment           │ │
│  │  Push to 'main' branch     →  Production Deployment        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
         ┌──────────▼────────┐      ┌──────────▼────────┐
         │   Staging Env     │      │  Production Env   │
         │                   │      │                   │
         │ ┌───────────────┐ │      │ ┌───────────────┐ │
         │ │  Backend API  │ │      │ │  Backend API  │ │
         │ │  (App Service)│ │      │ │  (App Service)│ │
         │ └───────┬───────┘ │      │ └───────┬───────┘ │
         │         │         │      │         │         │
         │ ┌───────▼───────┐ │      │ ┌───────▼───────┐ │
         │ │  Azure SQL DB │ │      │ │  Azure SQL DB │ │
         │ └───────────────┘ │      │ └───────────────┘ │
         │                   │      │                   │
         │ ┌───────────────┐ │      │ ┌───────────────┐ │
         │ │  Frontend App │ │      │ │  Frontend App │ │
         │ │  (Static Web) │ │      │ │  (Static Web) │ │
         │ └───────────────┘ │      │ └───────────────┘ │
         └───────────────────┘      └───────────────────┘
```

## GitHub Secrets Configuration

### Repository Secrets (Required)

Navigate to **Settings > Secrets and variables > Actions** in your GitHub repository and add the following secrets:

#### Backend Deployment Secrets

**Staging:**
- `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING` - Download from Azure Portal: App Service > Deployment Center > Manage publish profile

**Production:**
- `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION` - Download from Azure Portal: App Service > Deployment Center > Manage publish profile

#### Frontend Deployment Secrets

**Staging:**
- `AZURE_STATIC_WEB_APPS_API_TOKEN_STAGING` - From Azure Static Web App > Manage deployment token
- `STAGING_API_BASE_URL` - e.g., `https://fireproof-api-staging.azurewebsites.net/api`
- `STAGING_AZURE_AD_B2C_AUTHORITY` - e.g., `https://fireproofb2c.b2clogin.com/fireproofb2c.onmicrosoft.com/B2C_1_signupsignin`
- `STAGING_AZURE_AD_B2C_CLIENT_ID` - Azure AD B2C Application (client) ID
- `STAGING_FRONTEND_URL` - e.g., `https://staging.fireproofapp.net`

**Production:**
- `AZURE_STATIC_WEB_APPS_API_TOKEN_PRODUCTION` - From Azure Static Web App > Manage deployment token
- `PRODUCTION_API_BASE_URL` - e.g., `https://fireproof-api-prod.azurewebsites.net/api`
- `PRODUCTION_AZURE_AD_B2C_AUTHORITY` - Azure AD B2C authority URL
- `PRODUCTION_AZURE_AD_B2C_CLIENT_ID` - Azure AD B2C Application (client) ID
- `PRODUCTION_FRONTEND_URL` - e.g., `https://fireproofapp.net`

#### Database Migration Secrets

**Staging:**
- `STAGING_SQL_SERVER` - e.g., `fireproof-sql-staging.database.windows.net,1433`
- `STAGING_SQL_DATABASE` - e.g., `FireProofDB-Staging`
- `STAGING_SQL_USERNAME` - SQL admin username
- `STAGING_SQL_PASSWORD` - SQL admin password

**Production:**
- `PRODUCTION_SQL_SERVER` - e.g., `fireproof-sql-prod.database.windows.net,1433`
- `PRODUCTION_SQL_DATABASE` - e.g., `FireProofDB-Production`
- `PRODUCTION_SQL_USERNAME` - SQL admin username
- `PRODUCTION_SQL_PASSWORD` - SQL admin password

### Environment Configuration

Configure GitHub Environments for approval workflows:

1. Navigate to **Settings > Environments**
2. Create two environments: `staging` and `production`
3. For production:
   - Enable "Required reviewers" and add team members
   - Set deployment branch to `main` only
   - Add environment-specific secrets if needed

## Staging Deployment

### Automatic Deployment (CI/CD)

Deployments to staging trigger automatically when code is pushed to the `develop` branch:

```bash
git checkout develop
git merge feature/your-feature
git push origin develop
```

This triggers:
1. `.github/workflows/deploy-backend-staging.yml` (if backend code changed)
2. `.github/workflows/deploy-frontend-staging.yml` (if frontend code changed)

### Manual Deployment

To manually trigger a staging deployment:

1. Navigate to **Actions** tab in GitHub
2. Select the workflow:
   - "Deploy Backend to Staging" or
   - "Deploy Frontend to Staging"
3. Click **Run workflow**
4. Select branch `develop`
5. Click **Run workflow**

### First-Time Staging Setup

Before the first deployment:

1. **Create Azure Resources:**
   ```bash
   # Login to Azure
   az login

   # Create resource group
   az group create --name rg-fireproof-staging --location eastus

   # Create App Service Plan
   az appservice plan create --name asp-fireproof-staging --resource-group rg-fireproof-staging --sku B1 --is-linux

   # Create App Service
   az webapp create --name fireproof-api-staging --resource-group rg-fireproof-staging --plan asp-fireproof-staging --runtime "DOTNETCORE:8.0"

   # Create SQL Server
   az sql server create --name fireproof-sql-staging --resource-group rg-fireproof-staging --location eastus --admin-user sqladmin --admin-password 'YourSecurePassword123!'

   # Create SQL Database
   az sql db create --resource-group rg-fireproof-staging --server fireproof-sql-staging --name FireProofDB-Staging --service-objective S1

   # Create Static Web App
   az staticwebapp create --name fireproof-frontend-staging --resource-group rg-fireproof-staging --location eastus
   ```

2. **Configure App Service Settings:**
   ```bash
   az webapp config appsettings set --name fireproof-api-staging --resource-group rg-fireproof-staging --settings \
     "ASPNETCORE_ENVIRONMENT=Staging" \
     "ConnectionStrings__DefaultConnection=Server=tcp:fireproof-sql-staging.database.windows.net,1433;Initial Catalog=FireProofDB-Staging;Persist Security Info=False;User ID=sqladmin;Password=YourSecurePassword123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
     "Jwt__SecretKey=YOUR_32_CHARACTER_JWT_SECRET_KEY_HERE" \
     "TamperProofing__SignatureKey=YOUR_32_CHARACTER_SIGNATURE_KEY_HERE"
   ```

3. **Run Database Migrations:**
   ```bash
   # Navigate to Actions > Deploy Database Migrations
   # Select 'staging' environment
   # Enter migration scripts: "001_CreateCoreSchema.sql,002_CreateTenantSchema.sql,002b_CreateTenantSchema_Part2.sql,005_CreateSchedulingTables.sql"
   # Run workflow
   ```

4. **Deploy Backend and Frontend:**
   ```bash
   # Push to develop branch or manually trigger workflows
   git push origin develop
   ```

## Production Deployment

### Automatic Deployment (CI/CD)

Deployments to production trigger automatically when code is pushed to the `main` branch:

```bash
git checkout main
git merge develop
git push origin main
```

This triggers:
1. `.github/workflows/deploy-backend-production.yml` (if backend code changed)
2. `.github/workflows/deploy-frontend-production.yml` (if frontend code changed)
3. Requires manual approval (if configured in GitHub Environments)

### Manual Deployment

To manually trigger a production deployment:

1. Navigate to **Actions** tab in GitHub
2. Select the workflow:
   - "Deploy Backend to Production" or
   - "Deploy Frontend to Production"
3. Click **Run workflow**
4. Select branch `main`
5. Click **Run workflow**
6. Wait for approval (if configured)

### Production Deployment Checklist

Before deploying to production:

- [ ] All staging tests passing (24/24 E2E tests)
- [ ] Code reviewed and approved by team lead
- [ ] Database backup completed
- [ ] Rollback plan documented
- [ ] Stakeholders notified of deployment window
- [ ] Post-deployment verification plan ready
- [ ] Monitoring alerts configured

### First-Time Production Setup

Similar to staging setup, but with production-grade resources:

```bash
# Create production resources
az group create --name rg-fireproof-prod --location eastus

# Use P1V2 App Service Plan for better performance
az appservice plan create --name asp-fireproof-prod --resource-group rg-fireproof-prod --sku P1V2 --is-linux

# Create App Service
az webapp create --name fireproof-api-prod --resource-group rg-fireproof-prod --plan asp-fireproof-prod --runtime "DOTNETCORE:8.0"

# Use S3 SQL Database for better performance
az sql server create --name fireproof-sql-prod --resource-group rg-fireproof-prod --location eastus --admin-user sqladmin --admin-password 'YourSecurePassword123!'
az sql db create --resource-group rg-fireproof-prod --server fireproof-sql-prod --name FireProofDB-Production --service-objective S3

# Create Static Web App
az staticwebapp create --name fireproof-frontend-prod --resource-group rg-fireproof-prod --location eastus

# Configure App Service settings (similar to staging with production values)
```

## Database Migration

### Running Migrations via GitHub Actions

1. Navigate to **Actions > Deploy Database Migrations**
2. Click **Run workflow**
3. Select environment: `staging` or `production`
4. Enter comma-separated script filenames (e.g., `FIX_PROCEDURE_PARAMETERS.sql,FIX_MISSING_COLUMNS.sql`)
5. Click **Run workflow**
6. Monitor execution in Actions tab

### Manual Migration (Emergency)

If GitHub Actions is unavailable:

```bash
# Connect to database
sqlcmd -S fireproof-sql-staging.database.windows.net,1433 -d FireProofDB-Staging -U sqladmin -P YourSecurePassword123! -C

# Run migration script
sqlcmd -S fireproof-sql-staging.database.windows.net,1433 -d FireProofDB-Staging -U sqladmin -P YourSecurePassword123! -C -i database/scripts/MIGRATION_SCRIPT.sql
```

### Migration Best Practices

1. **Always backup before migration:**
   ```sql
   BACKUP DATABASE [FireProofDB-Production]
   TO DISK = N'/tmp/FireProofDB_backup_20250115.bak'
   WITH FORMAT, INIT, SKIP, NOREWIND, NOUNLOAD, STATS = 10;
   ```

2. **Test on staging first:**
   - Run migration on staging
   - Verify application functionality
   - Review query performance
   - Then deploy to production

3. **Monitor during migration:**
   - Watch for blocking queries
   - Monitor CPU and memory usage
   - Check error logs

4. **Verify after migration:**
   ```sql
   -- Check table counts
   SELECT TABLE_SCHEMA, COUNT(*) AS TableCount
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_TYPE = 'BASE TABLE'
   GROUP BY TABLE_SCHEMA;

   -- Check stored procedure counts
   SELECT COUNT(*) AS ProcedureCount
   FROM INFORMATION_SCHEMA.ROUTINES
   WHERE ROUTINE_TYPE = 'PROCEDURE';
   ```

## Rollback Procedures

### Backend API Rollback

**Option 1: Via Azure Portal (Fastest)**
1. Navigate to Azure Portal > App Service
2. Select `fireproof-api-prod` or `fireproof-api-staging`
3. Go to **Deployment > Deployment slots** (if using slots)
4. Click **Swap** to revert to previous slot
5. Or go to **Deployment Center > Logs**
6. Find previous successful deployment
7. Click **Redeploy**

**Option 2: Via Git Revert**
1. Identify the commit to revert:
   ```bash
   git log --oneline
   ```
2. Revert the problematic commit:
   ```bash
   git revert <commit-hash>
   git push origin main
   ```
3. GitHub Actions will automatically deploy the reverted version

**Option 3: Manual Publish Profile Deploy**
1. Checkout the last known good commit
2. Build locally:
   ```bash
   cd backend/FireExtinguisherInspection.API
   dotnet publish -c Release -o ./publish
   ```
3. Zip the publish folder
4. Upload via Azure Portal > App Service > Deployment Center

### Frontend Rollback

**Option 1: Azure Static Web Apps History**
1. Navigate to Azure Portal > Static Web App
2. Go to **Deployments**
3. Find previous successful deployment
4. Click **Redeploy**

**Option 2: Git Revert**
1. Revert the problematic commit:
   ```bash
   git revert <commit-hash>
   git push origin main
   ```
2. GitHub Actions will automatically redeploy

### Database Rollback

**Option 1: Restore from Backup (Safe)**
```bash
# Restore database from backup
sqlcmd -S fireproof-sql-prod.database.windows.net,1433 -d master -U sqladmin -P YourSecurePassword123! -C -Q "RESTORE DATABASE [FireProofDB-Production] FROM DISK = N'/tmp/FireProofDB_backup_20250115.bak' WITH REPLACE"
```

**Option 2: Run Rollback Script**
Create and maintain rollback scripts for each migration:
```sql
-- Example: Rollback for FIX_PROCEDURE_PARAMETERS.sql
DROP PROCEDURE IF EXISTS dbo.usp_Extinguisher_GetAll;
DROP PROCEDURE IF EXISTS dbo.usp_Inspection_GetAll;

-- Restore previous versions from backup or version control
```

### Emergency Rollback Decision Matrix

| Severity | Symptoms | Action | Rollback Method |
|----------|----------|--------|-----------------|
| **Critical** | Complete service outage, data corruption | Immediate rollback | Database restore + API slot swap |
| **High** | Major functionality broken, users affected | Rollback within 15 min | API/Frontend revert via Git |
| **Medium** | Minor bugs, limited user impact | Hotfix deployment | Forward fix in new deployment |
| **Low** | UI inconsistencies, non-critical features | Monitor and fix | Forward fix in next release |

## Post-Deployment Verification

### Automated Health Checks

GitHub Actions workflows include automated health checks that verify:
- API responds with HTTP 200 on `/api/health` endpoint
- Frontend loads successfully (HTTP 200)

### Manual Verification Checklist

After each deployment, verify the following:

#### Backend API Verification

1. **Health endpoint:**
   ```bash
   curl https://fireproof-api-prod.azurewebsites.net/api/health
   # Expected: { "status": "healthy" }
   ```

2. **Authentication endpoint:**
   ```bash
   curl https://fireproof-api-prod.azurewebsites.net/api/authentication/dev-login \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"email": "admin@fireproof.local", "password": "Admin123!"}'
   # Expected: { "token": "...", "refreshToken": "..." }
   ```

3. **Database connectivity:**
   ```bash
   # Use the token from authentication
   curl https://fireproof-api-prod.azurewebsites.net/api/tenants \
     -H "Authorization: Bearer <token>"
   # Expected: List of tenants
   ```

4. **Check Application Insights:**
   - Navigate to Azure Portal > Application Insights
   - Verify request telemetry is being logged
   - Check for any exceptions in last 30 minutes

#### Frontend Verification

1. **Load homepage:**
   ```bash
   curl -I https://fireproofapp.net
   # Expected: HTTP/1.1 200 OK
   ```

2. **Manual browser test:**
   - Open https://fireproofapp.net in browser
   - Verify login page loads
   - Attempt login with test credentials
   - Navigate to dashboard
   - Check all main navigation links
   - Verify data loads correctly

3. **Console errors:**
   - Open browser DevTools (F12)
   - Check Console tab for JavaScript errors
   - Check Network tab for failed requests

#### Database Verification

1. **Connect to database:**
   ```bash
   sqlcmd -S fireproof-sql-prod.database.windows.net,1433 -d FireProofDB-Production -U sqladmin -P YourPassword -C
   ```

2. **Verify table structure:**
   ```sql
   -- Check table counts
   SELECT TABLE_SCHEMA, COUNT(*) AS TableCount
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_TYPE = 'BASE TABLE'
   GROUP BY TABLE_SCHEMA;

   -- Verify stored procedures exist
   SELECT ROUTINE_NAME
   FROM INFORMATION_SCHEMA.ROUTINES
   WHERE ROUTINE_TYPE = 'PROCEDURE'
   ORDER BY ROUTINE_NAME;
   ```

3. **Test data integrity:**
   ```sql
   -- Check for recent audit logs
   SELECT TOP 10 *
   FROM dbo.AuditLog
   ORDER BY Timestamp DESC;

   -- Verify tenant count
   SELECT COUNT(*) AS TenantCount FROM dbo.Tenants;
   ```

#### E2E Test Verification

Run the full E2E test suite against the deployed environment:

```bash
cd frontend/fire-extinguisher-web
VITE_API_BASE_URL=https://fireproof-api-prod.azurewebsites.net/api npm run test:e2e
```

Expected result: 24/24 tests passing

### Monitoring Setup

Configure Azure Monitor alerts for:

1. **API Response Time** > 2 seconds (P95)
2. **API Error Rate** > 1% (HTTP 500 responses)
3. **Database CPU** > 80%
4. **Database DTU** > 90%
5. **App Service CPU** > 85%
6. **App Service Memory** > 90%

Configure alerts to notify via:
- Email to ops team
- Microsoft Teams channel
- PagerDuty (for critical alerts)

## Troubleshooting

### Common Deployment Issues

#### Issue: Backend deployment fails with "Publish profile not found"

**Solution:**
1. Download fresh publish profile from Azure Portal
2. Update GitHub secret `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING` or `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION`
3. Re-run workflow

#### Issue: Frontend deployment fails with "No such file or directory: dist"

**Solution:**
1. Check that `npm run build` succeeds locally
2. Verify `output_location: 'dist'` in workflow matches Vite config
3. Check for build errors in GitHub Actions logs

#### Issue: Database migration fails with "Login failed"

**Solution:**
1. Verify SQL credentials in GitHub secrets
2. Check Azure SQL firewall rules - ensure GitHub Actions IP is allowed
3. For Azure SQL, add firewall rule: "Allow Azure services and resources to access this server"

#### Issue: API returns 500 errors after deployment

**Solution:**
1. Check Application Insights logs for exceptions
2. Verify connection string is correct
3. Check that database migrations completed successfully
4. Review App Service logs:
   ```bash
   az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof-prod
   ```

#### Issue: Frontend can't connect to backend API

**Solution:**
1. Verify `VITE_API_BASE_URL` is set correctly in GitHub secrets
2. Check CORS configuration in backend `Program.cs`
3. Test API directly with curl to isolate issue
4. Check browser DevTools Network tab for CORS errors

#### Issue: Authentication fails with "Invalid token"

**Solution:**
1. Verify JWT secret matches between environments
2. Check Azure AD B2C configuration
3. Ensure redirect URIs are correctly configured
4. Review token expiration settings

### Getting Help

For deployment issues:

1. **Check GitHub Actions logs:**
   - Navigate to Actions tab
   - Click on failed workflow run
   - Review step-by-step logs

2. **Check Azure logs:**
   ```bash
   # App Service logs
   az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof-prod

   # Query Application Insights
   az monitor app-insights query --app fireproof-appinsights-prod --analytics-query "exceptions | top 10 by timestamp desc"
   ```

3. **Contact team:**
   - Create GitHub issue with deployment logs
   - Tag team lead with `@mention`
   - For critical issues, escalate via PagerDuty

---

## Quick Reference Commands

### Deploy to Staging
```bash
git checkout develop
git merge feature/your-feature
git push origin develop
```

### Deploy to Production
```bash
git checkout main
git merge develop
git push origin main
```

### Rollback Production API
```bash
# Via Azure Portal > App Service > Deployment Center > Redeploy previous version
```

### View Logs
```bash
# Backend logs
az webapp log tail --name fireproof-api-prod --resource-group rg-fireproof-prod

# Frontend logs (Static Web App)
# View in Azure Portal > Static Web App > Functions > Log Stream
```

### Database Backup
```bash
sqlcmd -S fireproof-sql-prod.database.windows.net,1433 -d FireProofDB-Production -U sqladmin -P YourPassword -C -Q "BACKUP DATABASE [FireProofDB-Production] TO DISK = N'/tmp/backup_$(date +%Y%m%d).bak'"
```

---

**Document Version:** 1.0
**Last Updated:** 2025-01-15
**Maintained By:** DevOps Team
