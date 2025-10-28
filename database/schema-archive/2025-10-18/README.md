# Database Schema Archive - October 18, 2025

## Extraction Details

- **Date**: October 18, 2025
- **Database**: FireProofDB
- **Server**: sqltest.schoolvision.net:14333
- **Tool**: SQL Extract v1.0.0
- **Purpose**: Capture production schema state after completing NULL value fixes and RLS migration

## Schema Summary

### Schemas (4)
- `dbo` (core schema)
- `DEMO001` (demo tenant schema)
- Additional tenant schemas created dynamically

### Tables (18)
Core schema (dbo):
1. Users
2. Tenants
3. SystemRoles
4. UserSystemRoles
5. UserTenantRoles
6. AuditLog
7. ExtinguisherTypes
8. ChecklistTemplates
9. ChecklistItems
10. Locations
11. Extinguishers
12. Inspections
13. InspectionPhotos
14. InspectionChecklistResponses
15. InspectionDeficiencies
16. MaintenanceRecords
17. Reports
18. InspectionTypes

### Stored Procedures (69)
Full list in `06_CREATE_PROCEDURES.sql`

Key procedures:
- Authentication: `usp_User_GetByEmail`, `usp_User_ValidatePassword`, `usp_User_UpdateRefreshToken`
- Tenants: `usp_Tenant_GetAll`, `usp_Tenant_GetById`, `usp_Tenant_Create`
- Locations: `usp_Location_GetAll`, `usp_Location_GetById`, `usp_Location_Create`
- Extinguishers: `usp_Extinguisher_GetAll`, `usp_Extinguisher_GetById`, `usp_Extinguisher_Create`, `usp_Extinguisher_GetByBarcode`
- Inspections: `usp_Inspection_GetAll`, `usp_Inspection_GetById`, `usp_Inspection_Create`, `usp_Inspection_Complete`
- Checklist: `usp_ChecklistTemplate_GetAll`, `usp_ChecklistItem_GetByTemplate`, `usp_InspectionChecklistResponse_CreateBatch`

### Constraints
- **Primary Keys**: 18 (one per table)
- **Foreign Keys**: 35 (enforcing referential integrity)
- **Unique Constraints**: 6
- **Check Constraints**: 2

### Indexes (32)
- Clustered indexes on primary keys
- Non-clustered indexes on foreign keys
- Performance indexes on common query columns

## Recent Schema Changes

### October 17-18, 2025: NULL Value Fixes
Fixed SqlNullValueException errors in Inspections table:
1. **String columns**: Set NULL values to empty string or defaults
2. **Boolean columns**: Added NOT NULL constraints with DEFAULT values
   - All 16 boolean inspection fields now have NOT NULL with DEFAULT 0

Scripts:
- `FIX_NULL_INSPECTION_VALUES.sql` - Updated 4 rows with NULL strings
- `FIX_ALL_INSPECTION_NULLS.sql` - Comprehensive NULL value update
- `FIX_ALL_INSPECTION_BOOLEAN_NULLS.sql` - Updated NULL boolean values
- `FIX_INSPECTION_BOOLEAN_SCHEMA_V2.sql` - Added NOT NULL constraints (PERMANENT FIX)

### October 17, 2025: RLS Migration
Migrated from tenant-specific schemas to single dbo schema with Row Level Security (RLS):
- All tables now in `dbo` schema
- TenantId column added to all tenant-specific tables
- RLS policies enforce tenant isolation
- All stored procedures updated to filter by TenantId

Scripts:
- `MIGRATE_TO_STANDARD_SCHEMA.sql`
- `ADD_ISOUTOFSERVICE_RLS.sql`

### Super Admin User Creation
Created stored procedure for super admin user creation:
- `usp_CreateSuperAdmin` - Creates users with role copying from template user
- Default password: "FireProofIt!" (BCrypt WorkFactor 12)

Users created:
- Charlotte Payne (cpayne4@kumc.edu)
- Jon Dunn (jdunn@2amarketing.com)

Scripts:
- `CREATE_SUPER_ADMIN_USERS.sql`
- `CREATE_USP_CREATE_SUPER_ADMIN.sql`
- `RESET_PASSWORDS_TO_FIREPROOFIT.sql`

## Deployment Files

### Production-Ready Schema
Deploy in this order:
1. `01_CREATE_SCHEMAS.sql` - Create database schemas
2. `02_CREATE_TABLES.sql` - Create all tables
3. `03_CREATE_CONSTRAINTS.sql` - Add constraints and foreign keys
4. `04_CREATE_INDEXES.sql` - Create indexes
5. `06_CREATE_PROCEDURES.sql` - Create stored procedures

### Seed Data
Not included in schema extract. Use separate seed data scripts:
- `SEED_CI_TEST_DATA.sql` - Test data for CI/CD
- `CREATE_USP_CREATE_SUPER_ADMIN.sql` - Admin user creation procedure

## Schema Integrity

All schema objects have been validated:
- ✅ All tables have primary keys
- ✅ All foreign keys properly constrained
- ✅ All indexes created successfully
- ✅ All stored procedures compile without errors
- ✅ No NULL value exceptions in boolean or required fields
- ✅ RLS policies enforce tenant isolation

## Archive Contents

This archive contains:
- `01_CREATE_SCHEMAS.sql` - Schema definitions
- `02_CREATE_TABLES.sql` - Table DDL
- `03_CREATE_CONSTRAINTS.sql` - Constraints and FKs
- `04_CREATE_INDEXES.sql` - Index definitions
- `06_CREATE_PROCEDURES.sql` - All 69 stored procedures

## Related Archives

Previous scripts archived to:
`/mnt/d/Dev2/fireproof/database/scripts-archive/2025-10-18-pre-schema-extract/`

Contains all schema-impacting scripts that led to this current state.

## Next Steps

Future schema changes should:
1. Create migration script in `database/scripts/`
2. Test on development database
3. Deploy to staging
4. After successful staging deployment, create new schema archive
5. Deploy to production
6. Archive old scripts to dated folder

## Notes

- All boolean inspection fields now have NOT NULL constraints - prevents future NULL exceptions
- Password hashes use BCrypt WorkFactor 12 for security
- RLS policies require TenantId in all queries - ensures data isolation
- All stored procedures use proper error handling with TRY/CATCH blocks

---
Generated: October 18, 2025
Extracted by: SQL Extract (https://github.com/dbbuilder/SQLExtract)
