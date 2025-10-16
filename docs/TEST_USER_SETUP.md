# Test User Setup for E2E Testing

## Overview

This document describes the test user and tenant configuration that should be identical across all environments (development, staging, and production) to ensure E2E tests can run consistently.

## Test User Details

**Email:** `chris@servicevision.net`
**Password:** `Test123!`
**Name:** Chris Admin
**User ID:** `E236D7AC-07D1-4735-8562-8505AB5B7FBA`

## Tenant Assignment

**Tenant:** Demo Company Inc
**Tenant ID:** `634F2B52-D32A-46DD-A045-D158E793ADCB`
**Tenant Code:** `DEMO001`
**Role:** TenantAdmin

## Current Status (Development)

✅ User exists in development database
✅ Tenant exists in development database
✅ User-tenant role assignment configured
✅ E2E tests passing with this configuration (24/24)

## Setup for Staging and Production

To ensure E2E tests can run against staging and production, run the following SQL script on each environment:

```bash
# Staging
sqlcmd -S [STAGING_SQL_SERVER] -d FireProofDB-Staging -U [USERNAME] -P [PASSWORD] -C -i database/scripts/SEED_TEST_USER_TENANT.sql

# Production
sqlcmd -S [PRODUCTION_SQL_SERVER] -d FireProofDB-Production -U [USERNAME] -P [PASSWORD] -C -i database/scripts/SEED_TEST_USER_TENANT.sql
```

Or use the GitHub Actions workflow:

1. Go to **Actions > Deploy Database Migrations**
2. Select environment: `staging` or `production`
3. Enter script: `SEED_TEST_USER_TENANT.sql`
4. Run workflow

## Verification

After running the script, verify the setup:

```sql
SELECT
    u.Email,
    u.FirstName + ' ' + u.LastName AS FullName,
    t.CompanyName AS Tenant,
    utr.RoleName AS Role
FROM dbo.Users u
JOIN dbo.UserTenantRoles utr ON u.UserId = utr.UserId
JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
WHERE u.Email = 'chris@servicevision.net';
```

Expected output:
```
Email                     FullName     Tenant            Role
------------------------- ------------ ----------------- -------------
chris@servicevision.net   Chris Admin  Demo Company Inc  TenantAdmin
```

## E2E Test Configuration

Update the Playwright configuration to run against different environments:

**Development:**
```bash
cd frontend/fire-extinguisher-web
VITE_API_BASE_URL=http://localhost:7001/api npm run test:e2e
```

**Staging:**
```bash
VITE_API_BASE_URL=https://fireproof-api-staging.azurewebsites.net/api npm run test:e2e
```

**Production:**
```bash
VITE_API_BASE_URL=https://fireproof-api-prod.azurewebsites.net/api npm run test:e2e
```

## Test Credentials

The E2E tests use these credentials (stored in `tests/e2e/auth.setup.ts`):

```javascript
const TEST_USER = {
  email: 'chris@servicevision.net',
  password: 'Test123!'
}
```

## Important Notes

1. **Password Security**: This is a test account with a well-known password. It should ONLY be used for testing purposes and should NOT have access to real production data.

2. **Tenant Isolation**: The "Demo Company Inc" tenant should contain ONLY test data to prevent test runs from affecting real data.

3. **User Permissions**: The TenantAdmin role gives full access within the tenant for comprehensive testing.

4. **Consistency**: All environments must have identical user/tenant IDs to ensure tests work across environments.

## Troubleshooting

### Test fails with "Login failed"
- Verify user exists: `SELECT * FROM dbo.Users WHERE Email = 'chris@servicevision.net'`
- Verify password hash matches
- Check dev mode is enabled if using dev login

### Test fails with "No tenants found"
- Verify tenant exists: `SELECT * FROM dbo.Tenants WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB'`
- Verify user-tenant role: `SELECT * FROM dbo.UserTenantRoles WHERE UserId = 'E236D7AC-07D1-4735-8562-8505AB5B7FBA'`

### Test data differs between environments
- Re-run `SEED_TEST_USER_TENANT.sql` script
- Verify all IDs match the values in this document
- Check tenant schema is properly created

---

**Last Updated:** 2025-10-16
**Maintained By:** DevOps Team
