# Deployment Quick Reference

## Deployment Commands

### Deploy to Staging (Automatic)
```bash
git checkout develop
git merge feature/your-feature
git push origin develop
```
→ Triggers staging deployment automatically

### Deploy to Production (Automatic)
```bash
git checkout main
git merge develop
git push origin main
```
→ Triggers production deployment automatically (may require approval)

### Manual Workflow Trigger
1. Go to GitHub **Actions** tab
2. Select workflow (e.g., "Deploy Backend to Staging")
3. Click **Run workflow** button
4. Select branch and click **Run workflow**

## Health Checks

### Staging
```bash
# API health
curl https://fireproof-api-staging.azurewebsites.net/api/health

# Frontend
curl -I https://[staging-static-web-app-url]

# Database connectivity
sqlcmd -S fireproof-sql-staging.database.windows.net,1433 \
  -d FireProofDB-Staging -U sqladmin -P PASSWORD -C \
  -Q "SELECT COUNT(*) FROM dbo.Tenants"
```

### Production
```bash
# API health
curl https://fireproof-api-prod.azurewebsites.net/api/health

# Frontend
curl -I https://[production-static-web-app-url]

# Run E2E tests
cd frontend/fire-extinguisher-web
VITE_API_BASE_URL=https://fireproof-api-prod.azurewebsites.net/api npm run test:e2e
```

## Database Migrations

### Via GitHub Actions (Recommended)
1. Go to **Actions > Deploy Database Migrations**
2. Click **Run workflow**
3. Select environment: `staging` or `production`
4. Enter script names (comma-separated):
   ```
   FIX_PROCEDURE_PARAMETERS.sql,FIX_MISSING_COLUMNS.sql
   ```
5. Click **Run workflow**

### Manual Migration
```bash
# Connect to database
sqlcmd -S [SERVER] -d [DATABASE] -U [USERNAME] -P [PASSWORD] -C

# Run migration script
sqlcmd -S [SERVER] -d [DATABASE] -U [USERNAME] -P [PASSWORD] -C \
  -i database/scripts/MIGRATION_SCRIPT.sql
```

## Rollback

### Backend API (via Azure Portal)
1. Azure Portal > App Service > `fireproof-api-[env]`
2. **Deployment Center > Logs**
3. Find previous successful deployment
4. Click **Redeploy**

### Frontend (via Azure Portal)
1. Azure Portal > Static Web App > `fireproof-frontend-[env]`
2. **Deployments**
3. Find previous successful deployment
4. Click **Redeploy**

### Database (via Backup Restore)
```bash
# Restore from backup
sqlcmd -S [SERVER] -d master -U [USERNAME] -P [PASSWORD] -C \
  -Q "RESTORE DATABASE [DATABASE] FROM DISK = N'/path/to/backup.bak' WITH REPLACE"
```

## View Logs

### Backend API Logs
```bash
# Real-time tail
az webapp log tail --name fireproof-api-[env] --resource-group rg-fireproof-[env]

# Download logs
az webapp log download --name fireproof-api-[env] --resource-group rg-fireproof-[env] --log-file logs.zip
```

### GitHub Actions Logs
1. Go to **Actions** tab
2. Click on workflow run
3. Click on job to see detailed logs

### Application Insights Queries
```bash
# Query exceptions
az monitor app-insights query \
  --app fireproof-appinsights-[env] \
  --analytics-query "exceptions | top 10 by timestamp desc"

# Query slow requests
az monitor app-insights query \
  --app fireproof-appinsights-[env] \
  --analytics-query "requests | where duration > 2000 | top 10 by timestamp desc"
```

## Common Issues

### Issue: Deployment fails with "Publish profile not found"
**Fix:** Download fresh publish profile from Azure Portal and update GitHub secret

### Issue: Health check fails after deployment
**Fix:**
1. Wait 60 seconds for deployment to stabilize
2. Check App Service logs: `az webapp log tail --name [APP] --resource-group [RG]`
3. Verify connection string in App Service settings
4. Check Application Insights for exceptions

### Issue: Database migration fails
**Fix:**
1. Check SQL firewall rules (must allow Azure services)
2. Verify credentials in GitHub secrets
3. Test connection manually with sqlcmd
4. Review migration script syntax

### Issue: Frontend build fails
**Fix:**
1. Check GitHub Actions logs for npm errors
2. Verify all environment variables are set in GitHub secrets
3. Test build locally: `npm run build`
4. Check for ESLint errors: `npm run lint`

## GitHub Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `deploy-backend-staging.yml` | Push to `develop` | Deploy API to staging |
| `deploy-backend-production.yml` | Push to `main` | Deploy API to production |
| `deploy-frontend-staging.yml` | Push to `develop` | Deploy frontend to staging |
| `deploy-frontend-production.yml` | Push to `main` | Deploy frontend to production |
| `deploy-database-migrations.yml` | Manual trigger | Run database migrations |
| `run-tests.yml` | Push/PR to `main`/`develop` | Run all tests |

## Environment URLs

### Staging
- **Backend API:** `https://fireproof-api-staging.azurewebsites.net`
- **Frontend:** `[from Azure Static Web App]`
- **Database:** `fireproof-sql-staging.database.windows.net,1433`

### Production
- **Backend API:** `https://fireproof-api-prod.azurewebsites.net`
- **Frontend:** `[from Azure Static Web App]`
- **Database:** `fireproof-sql-prod.database.windows.net,1433`

## Required GitHub Secrets

### Backend
- `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING`
- `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION`

### Frontend
- `AZURE_STATIC_WEB_APPS_API_TOKEN_STAGING`
- `AZURE_STATIC_WEB_APPS_API_TOKEN_PRODUCTION`
- `STAGING_API_BASE_URL`
- `STAGING_AZURE_AD_B2C_AUTHORITY`
- `STAGING_AZURE_AD_B2C_CLIENT_ID`
- `STAGING_FRONTEND_URL`
- `PRODUCTION_API_BASE_URL`
- `PRODUCTION_AZURE_AD_B2C_AUTHORITY`
- `PRODUCTION_AZURE_AD_B2C_CLIENT_ID`
- `PRODUCTION_FRONTEND_URL`

### Database
- `STAGING_SQL_SERVER`
- `STAGING_SQL_DATABASE`
- `STAGING_SQL_USERNAME`
- `STAGING_SQL_PASSWORD`
- `PRODUCTION_SQL_SERVER`
- `PRODUCTION_SQL_DATABASE`
- `PRODUCTION_SQL_USERNAME`
- `PRODUCTION_SQL_PASSWORD`

## Emergency Contacts

- **DevOps Lead:** [contact info]
- **On-Call Engineer:** [PagerDuty link]
- **Azure Support:** [support link]

## Additional Resources

- **Full Deployment Guide:** `docs/DEPLOYMENT_GUIDE.md`
- **Setup Checklist:** `docs/DEPLOYMENT_SETUP_CHECKLIST.md`
- **Technical Requirements:** `REQUIREMENTS.md`
- **Project README:** `README.md`

---

**Last Updated:** 2025-01-15
