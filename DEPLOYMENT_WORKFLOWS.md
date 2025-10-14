# Deployment Workflows Guide

## Overview

This document describes the four GitHub Actions workflows available for deploying the FireProof application to staging and production environments.

## Available Workflows

### 1. Deploy to Staging (`deploy-staging.yml`)
**Purpose**: Automated deployment to staging environment for testing

**Triggers**:
- Automatic: Push to `staging` branch
- Manual: Via GitHub Actions UI (workflow_dispatch)

**What it does**:
1. Deploys backend to `fireproof-api-staging`
2. Deploys frontend to `fireproof-staging`
3. Runs health checks on both

**URLs After Deployment**:
- Backend: https://fireproof-api-staging.azurewebsites.net
- Frontend: https://staging.fireproofapp.net

**When to use**: Every time you want to test changes in a staging environment

**How to trigger manually**:
1. Go to GitHub Actions tab
2. Select "Deploy to Staging"
3. Click "Run workflow"
4. Optionally provide a reason
5. Click "Run workflow"

---

### 2. Deploy to Production (`deploy-production.yml`)
**Purpose**: Direct deployment to production environment

**Triggers**:
- Manual only (requires explicit action)

**What it does**:
1. Deploys backend to `fireproof-api-test-2025`
2. Deploys frontend to production Static Web App
3. Runs comprehensive tests
4. Requires production environment approval (if configured)

**URLs After Deployment**:
- Backend: https://api.fireproofapp.net
- Frontend: https://fireproofapp.net

**When to use**:
- Hotfixes that need immediate production deployment
- When you want to skip staging and deploy directly

**⚠️ Warning**: This bypasses staging validation. Use with caution.

**How to trigger**:
1. Go to GitHub Actions tab
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Fill in required fields:
   - **Version/Tag**: Which branch/tag to deploy (default: main)
   - **Reason**: Required explanation for production deployment
   - **Skip tests**: Whether to skip health checks (default: false)
5. Click "Run workflow"
6. If environment protection rules are enabled, approve the deployment

---

### 3. Deploy to Staging and Production (`deploy-all.yml`)
**Purpose**: Sequential deployment to both environments with approval gate

**Triggers**:
- Manual only

**What it does**:
1. Deploys to staging first
2. Waits for manual approval
3. Deploys to production after approval

**When to use**:
- Major releases that need full environment validation
- When you want to test in staging before promoting

**How to trigger**:
1. Go to GitHub Actions tab
2. Select "Deploy to Staging and Production"
3. Click "Run workflow"
4. Fill in required fields:
   - **Reason**: Explanation for deployment
   - **Skip staging**: Whether to skip staging (default: false)
5. Click "Run workflow"
6. After staging completes, you'll see an approval request
7. Review staging environment
8. Approve production deployment when ready

---

### 4. Promote Staging to Production (`promote-to-production.yml`)
**Purpose**: Safest way to deploy - promotes tested staging code to production

**Triggers**:
- Manual only

**What it does**:
1. Validates staging environment is healthy
2. Tests staging backend and frontend
3. Deploys the same code to production
4. Creates a release tag for tracking
5. Requires production environment approval

**URLs Tested**:
- Staging Backend: https://fireproof-api-staging.azurewebsites.net
- Staging Frontend: https://staging.fireproofapp.net

**When to use**:
- **Recommended for all production deployments**
- After thorough testing in staging
- For planned releases with proper validation

**How to trigger**:
1. Test thoroughly in staging environment
2. Go to GitHub Actions tab
3. Select "Promote Staging to Production"
4. Click "Run workflow"
5. Fill in required fields:
   - **Reason**: Explanation for promotion
   - **Confirm tests passed**: Confirm staging tests passed
6. Click "Run workflow"
7. Workflow validates staging health
8. Approve production deployment when prompted
9. A release tag is automatically created

---

## Workflow Comparison

| Feature | Deploy Staging | Deploy Production | Deploy All | Promote to Production |
|---------|---------------|-------------------|------------|----------------------|
| **Trigger** | Auto + Manual | Manual Only | Manual Only | Manual Only |
| **Staging** | ✅ Yes | ❌ No | ✅ Yes | ✅ Validates |
| **Production** | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| **Approval Gate** | ❌ No | ⚠️ Optional | ✅ Yes | ✅ Yes |
| **Tests in Staging** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Release Tag** | ❌ No | ❌ No | ❌ No | ✅ Yes |
| **Risk Level** | 🟢 Low | 🔴 High | 🟡 Medium | 🟢 Low |
| **Recommended for** | Testing | Hotfixes | Major Releases | Normal Releases |

---

## Required GitHub Secrets

Before using these workflows, configure the following secrets in your GitHub repository:

### Backend Deployment Secrets
```
AZURE_WEBAPP_PUBLISH_PROFILE_STAGING
  - Get from: Azure Portal → fireproof-api-staging → Deployment Center → Download Publish Profile

AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION
  - Get from: Azure Portal → fireproof-api-test-2025 → Deployment Center → Download Publish Profile
```

### Frontend Deployment Secrets
```
AZURE_STATIC_WEB_APPS_API_TOKEN_STAGING
  - Get from: Azure Portal → fireproof-staging → Overview → Manage deployment token

AZURE_STATIC_WEB_APPS_API_TOKEN_NICE_SMOKE_08DBC500F
  - Get from: Azure Portal → nice-smoke-08dbc500f → Overview → Manage deployment token
```

---

## Environment Protection Rules (Recommended)

### Setting up Production Approval

1. Go to repository Settings → Environments
2. Create environment named "production"
3. Enable "Required reviewers"
4. Add team members who can approve production deployments
5. Optionally set wait timer (e.g., 5 minutes)

### Setting up Production-Approval Environment

1. Create environment named "production-approval"
2. Enable "Required reviewers"
3. Add team members who can approve the staging-to-production promotion

This adds a manual approval step before production deployments.

---

## Recommended Deployment Flow

### For Regular Development

```
1. Develop on feature branch
2. Merge to staging branch
   → Automatic deployment to staging via "Deploy to Staging" workflow
3. Test in staging environment
4. When ready:
   → Trigger "Promote Staging to Production" workflow
   → Approve production deployment
5. Monitor production environment
```

### For Hotfixes

```
1. Create hotfix branch from main
2. Apply fix and test locally
3. Option A (safer):
   → Merge to staging first
   → Use "Promote to Production" workflow

4. Option B (faster):
   → Use "Deploy to Production" workflow directly
   → Provide clear reason for bypassing staging
```

### For Major Releases

```
1. Develop features in feature branches
2. Merge to staging branch for integration testing
3. Test thoroughly in staging
4. Use "Deploy to Staging and Production" workflow
   → Deploys to staging
   → Allows time for final testing
   → Requires approval before production
   → Deploys to production
```

---

## Monitoring Deployments

### Via GitHub Actions UI

1. Go to repository → Actions tab
2. Click on workflow name
3. Click on specific run
4. View logs for each job

### Via Azure Portal

**Backend**:
- Portal → App Services → fireproof-api-staging (or fireproof-api-test-2025)
- Click "Deployment Center" → "Logs"

**Frontend**:
- Portal → Static Web Apps → fireproof-staging (or nice-smoke-08dbc500f)
- Click "Deployments" → View specific deployment

### Health Check URLs

**Staging**:
- Backend: https://fireproof-api-staging.azurewebsites.net/health
- Frontend: https://staging.fireproofapp.net/

**Production**:
- Backend: https://api.fireproofapp.net/health
- Frontend: https://fireproofapp.net/

---

## Troubleshooting

### Workflow fails during backend deployment

**Possible causes**:
1. Missing or invalid publish profile secret
2. Azure App Service not responding
3. Build errors in .NET code

**Solution**:
1. Check workflow logs for specific error
2. Verify publish profile is up-to-date
3. Test build locally: `dotnet build --configuration Release`

### Workflow fails during frontend deployment

**Possible causes**:
1. Missing or invalid Static Web Apps token
2. Build errors in Vue code
3. npm install failures

**Solution**:
1. Check workflow logs for specific error
2. Verify Static Web Apps token is valid
3. Test build locally: `npm run build`

### Health check fails after deployment

**Possible causes**:
1. App Service is still starting up
2. Database connection issues
3. Configuration errors

**Solution**:
1. Wait 1-2 minutes and check again
2. Check Azure App Service logs
3. Verify app settings in Azure Portal

### Approval not triggering

**Possible causes**:
1. Environment protection rules not configured
2. No reviewers assigned to environment

**Solution**:
1. Check Settings → Environments → production
2. Ensure "Required reviewers" is enabled
3. Verify reviewers are added

---

## Best Practices

### ✅ Do

- Always test in staging before production
- Use "Promote to Production" for normal releases
- Provide clear reasons for deployments
- Monitor health checks after deployment
- Keep publish profiles and tokens secure
- Review staging thoroughly before promoting
- Create release tags for major versions

### ❌ Don't

- Deploy directly to production without staging validation (except hotfixes)
- Skip health checks unless absolutely necessary
- Share deployment secrets in plain text
- Deploy without providing a reason
- Ignore failed health checks
- Deploy during peak usage hours without planning

---

## Rollback Procedures

### If production deployment fails:

1. **Immediate**:
   - Workflow will fail and not complete deployment
   - Previous version remains active

2. **If deployment succeeded but app is broken**:
   ```bash
   # Option 1: Re-run previous workflow
   - Go to Actions → Find last successful run
   - Click "Re-run all jobs"

   # Option 2: Deploy specific tag
   - Use "Deploy to Production" workflow
   - Set version to previous release tag
   - Provide reason: "Rollback to v1.1.1"
   ```

### Emergency rollback

1. Go to Azure Portal
2. Navigate to App Service or Static Web App
3. Go to "Deployment Center" or "Deployments"
4. Find previous successful deployment
5. Click "Redeploy"

---

## Additional Resources

- **Azure App Service Documentation**: https://docs.microsoft.com/azure/app-service/
- **Azure Static Web Apps Documentation**: https://docs.microsoft.com/azure/static-web-apps/
- **GitHub Actions Documentation**: https://docs.github.com/actions

---

## Workflow File Locations

```
.github/workflows/
├── deploy-staging.yml              # Auto + manual staging deployment
├── deploy-production.yml           # Manual production deployment
├── deploy-all.yml                  # Sequential staging → production
└── promote-to-production.yml       # Promote tested staging to production
```

---

## Quick Reference Commands

### Trigger workflows via GitHub CLI

```bash
# Deploy to staging
gh workflow run deploy-staging.yml

# Deploy to production
gh workflow run deploy-production.yml -f version=main -f reason="Production release v1.2.0"

# Deploy to both (with approval)
gh workflow run deploy-all.yml -f reason="Major release v1.2.0"

# Promote staging to production
gh workflow run promote-to-production.yml -f reason="Release v1.2.0" -f confirm_tests_passed="Yes - Tests Passed"
```

### Check workflow status

```bash
# List recent workflow runs
gh run list --workflow=deploy-staging.yml

# Watch a running workflow
gh run watch

# View workflow logs
gh run view --log
```

---

## Summary

- **Staging Deployment**: Automatic on push to `staging` branch
- **Production Deployment**: Manual only, requires approval
- **Recommended Flow**: staging → test → promote to production
- **Safest Option**: "Promote Staging to Production" workflow

For questions or issues, please contact the DevOps team or create an issue in the repository.
