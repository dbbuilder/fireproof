/*============================================================================
  File:     RunAll.sql
  Summary:  Master script to execute all database setup scripts in order
  Date:     October 9, 2025

  Description:
    This script runs all database migration scripts in the correct order:
    1. Create database
    2. Create core schema (Tenants, Users, Roles)
    3. Create tenant schema (Locations, ExtinguisherTypes, etc.)
    4. Create stored procedures (common)
    5. Create tenant stored procedures
    6. Add authentication fields
    7. Create authentication stored procedures

  Usage:
    sqlcmd -S sqltest.schoolvision.net,14333 -U sv -P "Gv51076!" -i RunAll.sql -C
============================================================================*/

PRINT '============================================================================'
PRINT 'FireProof Database Setup - Master Script'
PRINT 'Starting execution at: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '============================================================================'
PRINT ''

-- Step 1: Create Database
PRINT 'Step 1: Creating database...'
:r 000_CreateDatabase.sql
PRINT ''

-- Step 2: Create Core Schema
PRINT 'Step 2: Creating core schema (Tenants, Users, Roles)...'
:r 001_CreateCoreSchema.sql
PRINT ''

-- Step 3: Create Tenant Schema Template
PRINT 'Step 3: Creating tenant schema template...'
:r 002_CreateTenantSchema.sql
PRINT ''

-- Step 4: Create Common Stored Procedures
PRINT 'Step 4: Creating common stored procedures...'
:r 003_CreateStoredProcedures.sql
PRINT ''

-- Step 5: Create Tenant Stored Procedures
PRINT 'Step 5: Creating tenant stored procedures...'
:r 004_CreateTenantStoredProcedures.sql
PRINT ''

-- Step 6: Add Authentication Fields
PRINT 'Step 6: Adding authentication fields to Users table...'
:r 005_AddAuthenticationFields.sql
PRINT ''

-- Step 7: Create Authentication Stored Procedures
PRINT 'Step 7: Creating authentication stored procedures...'
:r 006_CreateAuthStoredProcedures.sql
PRINT ''

PRINT '============================================================================'
PRINT 'FireProof Database Setup Complete!'
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT ''
PRINT 'Database ready for use.'
PRINT 'Development test users created:'
PRINT '  - dev@fireproof.local (TenantAdmin)'
PRINT '  - inspector@fireproof.local (Inspector)'
PRINT '  - sysadmin@fireproof.local (SystemAdmin)'
PRINT ''
PRINT 'Use /api/authentication/dev-login for instant login in development'
PRINT '============================================================================'
GO
