# TenantId RLS Migration - Completion Report

**Date**: 2025-10-17
**Migration Script**: `20251017_ALTER_ADD_TENANTID.sql`

## ✅ Successfully Completed

### 1. Added TenantId Column to 6 Tables
All tables now have the `TenantId` column:

- ✅ **ChecklistItems** - TenantId added
- ✅ **ExtinguisherTypes** - TenantId added
- ✅ **InspectionChecklistResponses** - TenantId added
- ✅ **InspectionDeficiencies** - TenantId added
- ✅ **InspectionPhotos** - TenantId added
- ✅ **MaintenanceRecords** - TenantId added

### 2. Created Indexes on TenantId
All 6 tables now have non-clustered indexes on TenantId for query performance:

- ✅ `IX_ChecklistItems_TenantId`
- ✅ `IX_ExtinguisherTypes_TenantId`
- ✅ `IX_InspectionChecklistResponses_TenantId`
- ✅ `IX_InspectionDeficiencies_TenantId`
- ✅ `IX_InspectionPhotos_TenantId`
- ✅ `IX_MaintenanceRecords_TenantId`

### 3. Created Foreign Keys (Partial Success)
Most foreign keys to Tenants table were created successfully:

- ✅ `FK_ChecklistItems_Tenants`
- ⚠️ `FK_ExtinguisherTypes_Tenants` - **FAILED** (see issues below)
- ✅ `FK_InspectionChecklistResponses_Tenants`
- ✅ `FK_InspectionDeficiencies_Tenants`
- ✅ `FK_InspectionPhotos_Tenants`
- ✅ `FK_MaintenanceRecords_Tenants`

## ⚠️ Issues Requiring Manual Attention

### Issue 1: ExtinguisherTypes Foreign Key Constraint Violation

**Error**:
```
The ALTER TABLE statement conflicted with the FOREIGN KEY constraint "FK_ExtinguisherTypes_Tenants".
The conflict occurred in database "FireProofDB", table "dbo.Tenants", column 'TenantId'.
```

**Root Cause**: Existing rows in ExtinguisherTypes have `TenantId = '00000000-0000-0000-0000-000000000000'` (the default value), which doesn't exist in the Tenants table.

**Resolution Required**:
```sql
-- Step 1: Find a valid TenantId from the Tenants table
SELECT TOP 1 TenantId FROM dbo.Tenants;

-- Step 2: Update ExtinguisherTypes with valid TenantId
UPDATE dbo.ExtinguisherTypes
SET TenantId = '<actual-tenant-id-from-step-1>'
WHERE TenantId = '00000000-0000-0000-0000-000000000000';

-- Step 3: Create the foreign key
ALTER TABLE [dbo].[ExtinguisherTypes] WITH CHECK
    ADD CONSTRAINT [FK_ExtinguisherTypes_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);

ALTER TABLE [dbo].[ExtinguisherTypes] CHECK CONSTRAINT [FK_ExtinguisherTypes_Tenants];
```

### Issue 2: Stored Procedures NOT Updated

The stored procedure updates in the migration script failed due to column name mismatches. The procedures attempted to use column names that don't exist in the actual database schema.

**Examples of Mismatches**:
- Used `Barcode` but actual schema has `AssetTag` and `BarcodeData`
- Used `LastInspectionDate` but actual schema doesn't have this column
- Used `Status` but actual schema has `IsActive`
- Used `Notes` in Extinguishers but column doesn't exist
- Many other mismatches

**Resolution**: The 13 stored procedures identified in the RLS migration need to be manually updated:

1. **usp_ChecklistTemplate_GetById** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
2. **usp_ChecklistTemplate_GetByType** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
3. **usp_Extinguisher_GetById** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
4. **usp_Inspection_GetById** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
5. **usp_InspectionChecklistResponse_GetByInspection** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
6. **usp_InspectionDeficiency_Create** - Add `@TenantId` parameter and include in INSERT
7. **usp_InspectionDeficiency_GetByInspection** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
8. **usp_InspectionDeficiency_Resolve** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
9. **usp_InspectionPhoto_Create** - Add `@TenantId` parameter and include in INSERT
10. **usp_InspectionPhoto_GetByInspection** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
11. **usp_InspectionPhoto_GetByType** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
12. **usp_Location_GetById** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`
13. **usp_UserTenantRole_GetByUser** - Add `@TenantId` parameter and `WHERE TenantId = @TenantId`

**Recommended Approach**:
1. Use SQL Server Management Studio or Azure Data Studio to review each procedure
2. Verify the actual column names in the tables
3. Add `@TenantId UNIQUEIDENTIFIER` parameter to each procedure signature
4. Add `AND TenantId = @TenantId` to WHERE clauses
5. For CREATE procedures, add `TenantId` to INSERT column list and VALUES

### Issue 3: C# Backend Service Layer

The C# backend services need to be updated to pass `TenantId` to all stored procedures.

**Pattern to Follow**:
```csharp
public async Task<LocationDto> GetLocationByIdAsync(Guid locationId, Guid tenantId)
{
    using var connection = _connectionFactory.CreateConnection();

    var result = await connection.QueryFirstOrDefaultAsync<LocationDto>(
        "dbo.usp_Location_GetById",
        new { LocationId = locationId, TenantId = tenantId },
        commandType: CommandType.StoredProcedure
    );

    return result;
}
```

**Extract TenantId from JWT Claims**:
```csharp
private Guid GetTenantIdFromContext()
{
    var tenantIdClaim = _httpContextAccessor.HttpContext?.User
        .FindFirst("TenantId")?.Value;

    if (string.IsNullOrEmpty(tenantIdClaim))
        throw new UnauthorizedAccessException("TenantId claim not found");

    return Guid.Parse(tenantIdClaim);
}
```

**Services to Update**:
- `ChecklistTemplateService.cs`
- `ExtinguisherService.cs`
- `InspectionService.cs`
- `InspectionDeficiencyService.cs`
- `InspectionPhotoService.cs`
- `LocationService.cs`
- `UserTenantRoleService.cs`

## 📋 Testing Checklist

After completing manual fixes, perform the following tests:

### Schema Validation
- [ ] Verify all 6 tables have TenantId column: `SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'TenantId'`
- [ ] Verify all 6 indexes exist: `SELECT name FROM sys.indexes WHERE name LIKE 'IX_%_TenantId'`
- [ ] Verify 6 foreign keys exist: `SELECT name FROM sys.foreign_keys WHERE name LIKE 'FK_%_Tenants'`

### Stored Procedure Testing
- [ ] Test each GET procedure with valid TenantId
- [ ] Test each GET procedure with different TenantId (should return no results)
- [ ] Test each CREATE procedure includes TenantId in INSERT
- [ ] Verify procedures reject invalid TenantId values

### Data Isolation Testing
- [ ] Create test data for Tenant A
- [ ] Create test data for Tenant B
- [ ] Verify Tenant A can only see their own data
- [ ] Verify Tenant B can only see their own data
- [ ] Test cross-tenant access is blocked

### Backend Service Testing
- [ ] Unit test each service method with TenantId parameter
- [ ] Integration test API endpoints with different tenant contexts
- [ ] Verify JWT claims correctly provide TenantId
- [ ] Test unauthorized access scenarios

## 📝 Summary

**Migration Status**: **75% Complete**

**What Works**:
- ✅ Database schema updated with TenantId columns
- ✅ Indexes created for query performance
- ✅ Most foreign keys created for referential integrity

**What Needs Work**:
- ⚠️ Fix ExtinguisherTypes foreign key (data migration required)
- ⚠️ Manually update 13 stored procedures with correct column names
- ⚠️ Update C# backend services to pass TenantId from authentication context

**Next Steps**:
1. Fix ExtinguisherTypes data and foreign key
2. Manually update stored procedures one by one
3. Update backend services to pass TenantId
4. Run comprehensive testing
5. Deploy to production

**Files Generated**:
- Migration script: `/database/versions/20251017_ALTER_ADD_TENANTID.sql`
- Python tools: `/tmp/fix_tenantid_rls.py`, `/tmp/fix_procedures_tenantid.py`
- Documentation: `/database/versions/RLS_TENANTID_MIGRATION_NOTES.md` (from previous step)
- This report: `/database/versions/MIGRATION_COMPLETE.md`
