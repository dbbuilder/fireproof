# Schema Scripts Archive - October 18, 2025

## Purpose

This archive contains all schema-impacting SQL scripts that were executed leading up to the October 18, 2025 schema extraction.

## Archived Files

### Core Schema Creation
- `001_CreateCoreSchema.sql` - Initial core schema (Users, Tenants, AuditLog, SystemRoles)
- `002_CreateTenantSchema.sql` - Tenant-specific tables (Locations, Extinguishers, etc.)
- `002b_CreateTenantSchema_Part2.sql` - Additional tenant tables (Inspections, Photos, Maintenance)
- `005_CreateSchedulingTables.sql` - Scheduling and checklist tables

### Inspection Schema Evolution
- `CREATE_INSPECTION_TABLES.sql` - Initial inspection table creation
- `FIX_INSPECTIONS_SCHEMA.sql` - Schema corrections for inspection tables
- `FIX_ADD_INSPECTION_TYPES_TABLE.sql` - Added InspectionTypes lookup table

### RLS Migration (October 17, 2025)
- `MIGRATE_TO_STANDARD_SCHEMA.sql` - Migrated from per-tenant schemas to single dbo schema with RLS
- `ADD_ISOUTOFSERVICE_RLS.sql` - Added RLS support for IsOutOfService column

### Column Additions & Fixes
- `ADD_MISSING_EXTINGUISHER_COLUMNS.sql` - Added missing extinguisher columns
- `FIX_MISSING_COLUMNS.sql` - Fixed missing columns in various tables
- `ALTER_TABLES_TO_MATCH_DTOS.sql` - Aligned database schema with DTO models
- `RECREATE_TABLES_TO_MATCH_DTOS.sql` - Recreated tables to match DTOs

### NULL Value Fixes (October 17-18, 2025)
- `FIX_NULL_INSPECTION_VALUES.sql` - Fixed 4 rows with NULL inspection values
- `FIX_ALL_INSPECTION_NULLS.sql` - Comprehensive NULL value update for all inspection columns
- `FIX_ALL_INSPECTION_BOOLEAN_NULLS.sql` - Updated NULL boolean values to 0
- `FIX_INSPECTION_BOOLEAN_SCHEMA_V2.sql` - **PERMANENT FIX**: Added NOT NULL constraints to all 16 boolean inspection columns

## Key Learnings

### NULL Value Exception Prevention
The final solution required both data fixes AND schema constraints:
1. **Data Fix**: Update existing NULL values to defaults
2. **Schema Fix**: Add NOT NULL constraints with DEFAULT values
3. **Prevention**: New rows automatically get default values

### Boolean Columns Fixed
All 16 boolean inspection fields now have:
- `NOT NULL` constraint
- `DEFAULT 0` value
- Prevents SqlNullValueException when calling reader.GetBoolean()

### RLS Migration Benefits
- Simpler schema (single dbo schema instead of per-tenant)
- Better query performance
- Easier maintenance
- Built-in tenant isolation via RLS policies

## Current State

As of October 18, 2025:
- ✅ All tables in `dbo` schema with TenantId column
- ✅ All boolean columns have NOT NULL constraints
- ✅ No NULL value exceptions in production
- ✅ 69 stored procedures operational
- ✅ 18 tables with proper constraints
- ✅ 3 super admin users (Chris, Charlotte, Jon)

## Schema Archive Location

Current production schema extracted to:
`/mnt/d/Dev2/fireproof/database/schema-archive/2025-10-18/`

Use these deployment-ready files for:
- Disaster recovery
- New environment setup
- Schema documentation

## Notes

These scripts are archived for historical reference only. Do not execute these scripts directly - they may conflict with current schema state.

For current schema, use files in `/database/schema-archive/2025-10-18/`

---
Archived: October 18, 2025
