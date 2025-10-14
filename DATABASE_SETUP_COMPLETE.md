# FireProof Database Setup - COMPLETE

**Date:** October 14, 2025
**Status:** ✅ Ready for Testing

## Summary

The FireProof database has been fully configured with all required schemas, tables, stored procedures, and seed data for both DEMO001 and DEMO002 tenants.

## What Was Completed

### 1. Tenant Schemas
- ✅ DEMO001 tenant schema created (`tenant_634F2B52-D32A-46DD-A045-D158E793ADCB`)
- ✅ DEMO002 tenant schema created (`tenant_5827F83D-743D-422D-94D5-90665BDA3506`)

### 2. Complete Extinguishers Table Schema
Added all columns required by the ExtinguisherService:
- ✅ `LastServiceDate` - Track last service performed
- ✅ `NextServiceDueDate` - Schedule next service
- ✅ `NextHydroTestDueDate` - Schedule hydrostatic testing
- ✅ `FloorLevel` - Physical location detail
- ✅ `Notes` - General notes field
- ✅ `QrCodeData` - QR code for mobile scanning
- ✅ `IsOutOfService` - Service status flag
- ✅ `OutOfServiceReason` - Reason when out of service

### 3. Missing Stored Procedures Created
#### Extinguisher Management:
- ✅ `usp_Extinguisher_GetById` - Get single extinguisher by ID
- ✅ `usp_Extinguisher_GetAll` - List all extinguishers (existing)
- ✅ `usp_Extinguisher_GetByBarcode` - Find by barcode (existing)

#### Extinguisher Type Management:
- ✅ `usp_ExtinguisherType_GetAll` - List all types
- ✅ `usp_ExtinguisherType_GetById` - Get single type by ID
- ✅ `usp_ExtinguisherType_Create` - Create new type

#### Location Management:
- ✅ `usp_Location_GetAll` - List all locations (existing)
- ✅ `usp_Location_GetById` - Get single location by ID (existing)
- ✅ `usp_Location_Create` - Create new location (existing)

### 4. Seed Data (DEMO001)
- ✅ **3 Locations:**
  - HQ-BLDG: Headquarters Building (Seattle, WA)
  - WAREHOUSE-A: Warehouse A (Tacoma, WA)
  - FACTORY-01: Manufacturing Plant 1 (Everett, WA)

- ✅ **10 Extinguisher Types:**
  - ABC Dry Chemical (2x, for legacy reasons)
  - BC Dry Chemical (2x)
  - K Class K Wet Chemical (2x)
  - CO2 Carbon Dioxide (2x)
  - H2O Water (2x)

- ✅ **15 Extinguishers:**
  - 5 at HQ Building
  - 5 at Warehouse A
  - 5 at Manufacturing Plant 1

### 5. Test Users
- ✅ **chris@servicevision.net**
  - Role: SystemAdmin
  - Can access all tenants
  - Dev login enabled (no password required)

- ✅ **multi@servicevision.net**
  - Role: TenantAdmin for both DEMO001 and DEMO002
  - Can switch between tenants
  - Dev login enabled (no password required)

## Scripts Created

All scripts are in `/database/scripts/`:

1. **CREATE_MISSING_TENANT_SCHEMAS_FIXED.sql**
   - Creates tenant schemas and base tables

2. **POPULATE_DEMO001_SEED_DATA.sql**
   - Populates DEMO001 with locations, types, and extinguishers

3. **CREATE_MISSING_PROCEDURES_DEMO001.sql**
   - Creates all missing stored procedures

4. **ADD_MISSING_EXTINGUISHER_COLUMNS.sql**
   - Adds all required columns to Extinguishers table

5. **TEST_DATABASE_COMPLETE.sql**
   - Comprehensive automated test suite

6. **test-api.sh** (in project root)
   - Automated API endpoint testing

## Testing Instructions

### Frontend Testing (Recommended First)

1. **Navigate to:** https://fireproofapp.net

2. **Login:**
   - Email: `chris@servicevision.net`
   - Click "Dev Login" (no password required)

3. **Select Tenant:**
   - Choose "DEMO001"

4. **Verify Dashboard:**
   - Should load without console errors
   - Should display summary statistics

5. **Test Each Section:**
   - **Locations:** Should show 3 locations (HQ, Warehouse, Factory)
   - **Extinguishers:** Should show 15 extinguishers
   - **Extinguisher Types:** Should show 10 types (5 unique)
   - **Reports:** Should generate compliance reports

6. **Test Switch Tenant:**
   - Click user menu (top right)
   - Click "Switch Tenant"
   - Select DEMO002
   - Should switch context successfully

### Database Testing

Run the comprehensive test suite:

```bash
sqlcmd -S sqltest.schoolvision.net,14333 -U sv -P Gv51076! -d FireProofDB -C \
  -i database/scripts/TEST_DATABASE_COMPLETE.sql
```

Expected output:
- ✅ All 8 tests should PASS
- ✅ Procedure count: 16 for DEMO001
- ✅ Data counts: 3 locations, 10 types, 15 extinguishers

### API Testing (When Backend is Running)

```bash
bash test-api.sh
```

This will test:
1. Authentication (dev login)
2. Get available tenants
3. GET /api/locations
4. GET /api/extinguisher-types
5. GET /api/extinguishers

## Expected Console Behavior

### Before These Changes
```
Server error: Failed to retrieve extinguishers
Server error: An internal server error occurred
Error fetching extinguisher types: J
Failed to load dashboard data: J
```

### After These Changes
```
🔥 FireProof v1.1.2
📦 Build: 2025-10-14T03:24:04.398Z
🔧 Environment: production
(clean console - no errors)
```

## Database Verification Query

Run this to verify everything is ready:

```sql
-- Verify DEMO001 completeness
DECLARE @Schema NVARCHAR(128) = (
  SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001'
)

-- Check procedure count
SELECT COUNT(*) as ProcedureCount, 'Stored Procedures' as Category
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = @Schema

UNION ALL

-- Check data counts
SELECT COUNT(*), 'Locations'
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations

UNION ALL

SELECT COUNT(*), 'Extinguisher Types'
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes

UNION ALL

SELECT COUNT(*), 'Extinguishers'
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers

-- Expected output:
-- 16 Stored Procedures
--  3 Locations
-- 10 Extinguisher Types
-- 15 Extinguishers
```

## Next Steps

### Immediate Testing
1. ✅ Test frontend at https://fireproofapp.net
2. ✅ Login as chris@servicevision.net
3. ✅ Select DEMO001 tenant
4. ✅ Verify all pages load without errors
5. ✅ Check browser console for cleanliness

### Future Development
- Add inspection functionality
- Implement photo upload
- Create maintenance tracking
- Build reporting dashboard
- Add notification system
- Implement barcode scanning

## Troubleshooting

### If frontend still shows errors:

1. **Check tenant selection:**
   - Ensure tenant is selected after login
   - Check X-Tenant-ID header is sent with requests

2. **Verify stored procedures exist:**
   ```sql
   SELECT name FROM sys.procedures
   WHERE SCHEMA_NAME(schema_id) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
   ORDER BY name
   ```

3. **Check column existence:**
   ```sql
   SELECT COLUMN_NAME
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
   AND TABLE_NAME = 'Extinguishers'
   ORDER BY ORDINAL_POSITION
   ```

4. **Test stored procedure manually:**
   ```sql
   EXEC [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].usp_Extinguisher_GetAll
     @TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB',
     @LocationId = NULL,
     @ExtinguisherTypeId = NULL,
     @IsActive = 1,
     @IsOutOfService = NULL
   ```

## Support

If issues persist:
1. Check backend logs for detailed error messages
2. Verify connection string in backend configuration
3. Ensure SQL Server allows connections from backend
4. Check Azure Container App logs

## Files Changed

```
database/scripts/
├── CREATE_MISSING_TENANT_SCHEMAS_FIXED.sql (new)
├── POPULATE_DEMO001_SEED_DATA.sql (new)
├── CREATE_MISSING_PROCEDURES_DEMO001.sql (new)
├── ADD_MISSING_EXTINGUISHER_COLUMNS.sql (new)
└── TEST_DATABASE_COMPLETE.sql (new)

test-api.sh (new)
DATABASE_SETUP_COMPLETE.md (this file)
```

---

**Ready for Testing!** 🎉

The database is now complete with all required schemas, procedures, and data.
Please test the frontend and report any remaining issues.
