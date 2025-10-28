# Extinguisher 500 Error - Fix Summary

**Date**: 2025-10-18
**Status**: ✅ FIXED

## Problem

The FireProof dashboard was showing HTTP 500 errors when trying to fetch extinguishers after successful login:

```
GET https://api.fireproofapp.net/api/extinguishers?tenantId=634f2b52-d32a-46dd-a045-d158e793adcb 500 (Internal Server Error)
```

## Root Cause

Two issues were discovered:

### 1. Missing Database Column

The `dbo.Extinguishers` table was missing the `IsOutOfService` column that the service code expected.

**Service Code** (ExtinguisherService.cs:76-82) was trying to pass:
- `@TenantId`
- `@LocationId`
- `@ExtinguisherTypeId`
- `@IsActive`
- `@IsOutOfService` ❌ **Column didn't exist**

### 2. Stored Procedure Parameter Mismatch

The stored procedure `dbo.usp_Extinguisher_GetAll` only accepted 1 parameter (`@TenantId`), but the service code was passing 5 parameters.

**Before**:
```sql
CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetAll
    @TenantId UNIQUEIDENTIFIER
AS
...
```

**After**:
```sql
CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER = NULL,
    @ExtinguisherTypeId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = NULL,
    @IsOutOfService BIT = NULL
AS
...
```

## Solution Applied

### Step 1: Added Missing Column

Created and executed `/mnt/d/Dev2/fireproof/database/scripts/ADD_ISOUTOFSERVICE_RLS.sql`:

```sql
ALTER TABLE dbo.Extinguishers
ADD IsOutOfService BIT NOT NULL DEFAULT 0;

ALTER TABLE dbo.Extinguishers
ADD OutOfServiceReason NVARCHAR(500) NULL;
```

✅ **Result**: Columns successfully added to production database

### Step 2: Fixed Stored Procedure

Created and executed `/mnt/d/Dev2/fireproof/database/scripts/FIX_EXTINGUISHER_GETALL_PARAMS.sql`:

- Added 4 optional parameters
- Added filtering logic using `WHERE` clause
- Added `IsOutOfService` column to SELECT list
- Improved JOIN conditions with tenant filtering

✅ **Result**: Stored procedure now accepts all 5 parameters and returns data correctly

### Step 3: Updated Schema Creation Script

Updated `/mnt/d/Dev2/fireproof/database/scripts/CREATE_STANDARD_STORED_PROCEDURES.sql` so future deployments include the fix.

## Verification

Tested the stored procedure directly:

```sql
EXEC dbo.usp_Extinguisher_GetAll
    @TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb',
    @LocationId = NULL,
    @ExtinguisherTypeId = NULL,
    @IsActive = NULL,
    @IsOutOfService = NULL
```

✅ **Result**: Successfully returned 3 extinguishers with all expected columns

**Sample Data**:
- TEST-MO-001 (Main Office, Ansul A-10, ABC Dry Chemical)
- TEST-MO-002 (Main Office, Kidde ProLine 5 CO2, Carbon Dioxide)
- TEST-WW-001 (West Wing - Building B, Amerex B456, ABC Dry Chemical)

## Files Created/Modified

### New Files
1. `/mnt/d/Dev2/fireproof/database/scripts/ADD_ISOUTOFSERVICE_RLS.sql` - Adds missing columns
2. `/mnt/d/Dev2/fireproof/database/scripts/FIX_EXTINGUISHER_GETALL_PARAMS.sql` - Fixes stored procedure

### Modified Files
1. `/mnt/d/Dev2/fireproof/database/scripts/CREATE_STANDARD_STORED_PROCEDURES.sql` - Updated for future deployments

## What's Fixed

✅ JWT Authentication (from previous session)
✅ Extinguisher table schema (added IsOutOfService column)
✅ Stored procedure parameter mismatch
✅ Database filtering now supports location, type, active status, and out-of-service status

## Next Steps

The API is now fixed and should work correctly. To verify:

1. **Refresh the browser** - Hard refresh (Ctrl+Shift+R / Cmd+Shift+R) to clear any cached API responses
2. **Login again** - The dashboard should now load extinguishers without 500 errors
3. **Check the dashboard** - You should see 3 extinguishers displayed

## Timeline

- **Issue Reported**: 2025-10-18 ~21:00 GMT
- **Root Cause Identified**: 2025-10-18 ~21:30 GMT
- **Fix Applied**: 2025-10-18 ~21:45 GMT
- **Verification Complete**: 2025-10-18 ~21:50 GMT

## Lessons Learned

1. **Schema Synchronization**: After RLS migration, ensure all expected columns are present in the new schema
2. **Service/Database Contract**: Always verify that service code expectations match database stored procedure signatures
3. **Diagnostic Endpoints**: The JWT diagnostic pattern proved invaluable for quickly identifying that authentication was working correctly, allowing us to focus on the data layer issue

## Related Documentation

- JWT Authentication Pattern: `/mnt/d/dev2/patterns/jwt/`
- Production Auth Fix: `/mnt/d/Dev2/fireproof/PRODUCTION_AUTH_FIX.md`
- Database Deployment: `/mnt/d/Dev2/fireproof/database/DATABASE_DEPLOYMENT.md`
