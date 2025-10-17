# TenantId and RLS Migration Summary

**Date**: October 17, 2025
**Purpose**: Migrate from tenant-specific schemas to single-schema RLS (Row Level Security) approach

## Changes Applied

### 1. Added TenantId Column to 6 Tables

The following tables now have `TenantId UNIQUEIDENTIFIER NOT NULL`:

- ✅ **ChecklistItems** - Added after ChecklistTemplateId
- ✅ **ExtinguisherTypes** - Added after TypeName
- ✅ **InspectionChecklistResponses** - Added after InspectionId
- ✅ **InspectionDeficiencies** - Added after InspectionId
- ✅ **InspectionPhotos** - Added after InspectionId
- ✅ **MaintenanceRecords** - Added after ExtinguisherId

### 2. Added Indexes and Foreign Keys

For each table that received TenantId:
- Created non-clustered index on TenantId with INCLUDE clause for PK
- Added foreign key constraint to Tenants table
- Named pattern: `FK_{TableName}_Tenants` and `IX_{TableName}_TenantId`

### 3. Tables Already With TenantId (No Changes)

These tables already had proper TenantId implementation:
- AuditLog
- ChecklistTemplates
- Extinguishers
- InspectionChecklistTemplates
- Inspections
- InspectionTypes
- Locations
- Tenants (has TenantId as part of PK)
- UserTenantRoles

### 4. Global Tables (Should NOT Have TenantId)

These tables remain global and share data across all tenants:
- **SystemRoles** - Global role definitions
- **Users** - Users can belong to multiple tenants
- **UserSystemRoles** - System-wide role assignments

## Required Manual Updates

### Stored Procedures Requiring Attention

The following 13 procedures may need manual review to add @TenantId parameters and WHERE clause filtering:

1. **usp_ChecklistTemplate_GetById**
2. **usp_ChecklistTemplate_GetByType**
3. **usp_Extinguisher_GetById**
4. **usp_Inspection_GetById**
5. **usp_InspectionChecklistResponse_GetByInspection**
6. **usp_InspectionDeficiency_Create**
7. **usp_InspectionDeficiency_GetByInspection**
8. **usp_InspectionDeficiency_Resolve**
9. **usp_InspectionPhoto_Create**
10. **usp_InspectionPhoto_GetByInspection**
11. **usp_InspectionPhoto_GetByType**
12. **usp_Location_GetById**
13. **usp_UserTenantRole_GetByUser**

### Procedure Update Pattern

For each procedure, ensure:

#### 1. Add @TenantId Parameter
```sql
CREATE PROCEDURE dbo.usp_Example_GetById
    @ExampleId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER  -- ADD THIS
AS
```

#### 2. Add TenantId to WHERE Clause
```sql
-- Before:
WHERE ExampleId = @ExampleId

-- After (RLS):
WHERE ExampleId = @ExampleId
    AND TenantId = @TenantId
```

#### 3. Add TenantId to INSERT Statements
```sql
INSERT INTO Examples (
    ExampleId,
    TenantId,  -- ADD THIS
    OtherColumn
) VALUES (
    @ExampleId,
    @TenantId,  -- ADD THIS
    @OtherColumn
)
```

#### 4. Add TenantId to JOIN Conditions
```sql
-- Before:
INNER JOIN OtherTable o ON e.OtherId = o.OtherId

-- After (RLS):
INNER JOIN OtherTable o ON e.OtherId = o.OtherId
    AND e.TenantId = o.TenantId
```

## Testing Checklist

After manual procedure updates:

- [ ] Test all CREATE procedures with TenantId parameter
- [ ] Test all GET procedures filter by TenantId correctly
- [ ] Test all UPDATE procedures verify TenantId matches
- [ ] Test all DELETE procedures verify TenantId matches
- [ ] Verify cross-tenant data isolation (User A can't see User B's data)
- [ ] Test foreign key cascades work correctly
- [ ] Verify indexes improve query performance
- [ ] Check that UserTenantRoles properly links users to their tenants

## RLS Best Practices

### 1. Always Pass TenantId from Application Layer

The C# service layer should:
```csharp
// Get TenantId from authenticated user context
var tenantId = _httpContextAccessor.HttpContext.User
    .FindFirst("TenantId")?.Value;

// Pass to all stored procedures
await connection.ExecuteAsync(
    "dbo.usp_Example_GetAll",
    new { TenantId = tenantId }
);
```

### 2. Never Trust Client-Supplied TenantId

Always derive TenantId from:
- JWT claims
- Session state
- Database lookup from authenticated UserId

### 3. Audit All Tenant-Scoped Operations

The AuditLog table tracks all operations and includes TenantId for filtering.

## Migration Execution Plan

1. **Backup Database** ⚠️ CRITICAL
2. **Run the RLS_FIXED.sql script** (creates tables with TenantId)
3. **Manually update the 13 flagged stored procedures**
4. **Update C# service layer** to pass TenantId to all procedures
5. **Update DTOs** to include TenantId where needed
6. **Run integration tests** with multiple tenant accounts
7. **Verify data isolation** between tenants

## Files Generated

- **Original**: `/database/versions/20251017_15531.sql`
- **Fixed**: `/database/versions/20251017_15531_RLS_FIXED.sql`
- **Python Script**: `/tmp/fix_tenantid_rls.py`

## Additional Considerations

### ExtinguisherTypes

Decision needed: Should ExtinguisherTypes be:
- **Tenant-specific**: Each tenant can define their own types ✅ (Currently implemented)
- **Global**: Shared standard types across all tenants

If global types are preferred, remove TenantId from ExtinguisherTypes table.

### InspectionTypes

Similarly, InspectionTypes already has TenantId. Verify this aligns with business requirements.

### AuditLog

AuditLog has TenantId for filtering but logs ALL operations across all tenants for compliance.

## Security Notes

⚠️ **CRITICAL**: RLS in SQL Server requires:
1. Security Policies (not yet implemented - future enhancement)
2. Application-level enforcement (via stored procedures - CURRENT APPROACH)

Current approach relies on:
- Stored procedures MUST filter by TenantId
- Application MUST pass correct TenantId from auth context
- No direct table access - all access via stored procedures

Future enhancement: Implement SQL Server RLS Security Policies for defense-in-depth.
