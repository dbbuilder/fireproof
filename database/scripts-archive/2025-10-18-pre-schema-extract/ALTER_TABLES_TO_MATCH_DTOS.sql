/*******************************************************************************
 * ALTER TABLES TO MATCH C# DTO DEFINITIONS
 *
 * The C# DTOs define the actual contract. This script alters the database
 * tables to match what the C# code expects.
 *
 * Changes:
 * - InspectionTypes: Remove TypeCode, IntervalMonths, RequiresPhotos, etc.
 *                    Add TenantId, RequiresServiceTechnician, FrequencyDays
 * - Locations: Add Latitude, Longitude, LocationBarcodeData
 *
 * Created: 2025-10-15
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Altering Tables to Match C# DTOs';
PRINT '========================================';

-- ============================================================================
-- ALTER INSPECTION TYPES TO MATCH InspectionTypeDto
-- ============================================================================

PRINT 'Altering dbo.InspectionTypes...';

-- Drop old index on TypeCode first
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_InspectionTypes_TypeCode' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
BEGIN
    DROP INDEX IX_InspectionTypes_TypeCode ON dbo.InspectionTypes;
    PRINT '  Dropped index: IX_InspectionTypes_TypeCode';
END

-- Drop all constraints using a cursor approach
DECLARE @ConstraintName NVARCHAR(200);
DECLARE @SQL NVARCHAR(500);

DECLARE constraint_cursor CURSOR FOR
SELECT name
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('dbo.InspectionTypes')
  AND type IN ('UQ', 'D')
  AND name LIKE '%TypeCode%'
  OR name LIKE '%IntervalMonths%'
  OR name LIKE '%RequiresPhotos%'
  OR name LIKE '%RequiresPressureCheck%'
  OR name LIKE '%RequiresWeightCheck%';

OPEN constraint_cursor;
FETCH NEXT FROM constraint_cursor INTO @ConstraintName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER TABLE dbo.InspectionTypes DROP CONSTRAINT ' + @ConstraintName;
    EXEC sp_executesql @SQL;
    PRINT '  Dropped constraint: ' + @ConstraintName;
    FETCH NEXT FROM constraint_cursor INTO @ConstraintName;
END;

CLOSE constraint_cursor;
DEALLOCATE constraint_cursor;

-- Now drop the columns
IF EXISTS (SELECT * FROM sys.columns WHERE name = 'TypeCode' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
BEGIN
    ALTER TABLE dbo.InspectionTypes DROP COLUMN TypeCode;
    PRINT '  Dropped column: TypeCode';
END

IF EXISTS (SELECT * FROM sys.columns WHERE name = 'IntervalMonths' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes DROP COLUMN IntervalMonths;

IF EXISTS (SELECT * FROM sys.columns WHERE name = 'RequiresPhotos' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes DROP COLUMN RequiresPhotos;

IF EXISTS (SELECT * FROM sys.columns WHERE name = 'RequiresPressureCheck' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes DROP COLUMN RequiresPressureCheck;

IF EXISTS (SELECT * FROM sys.columns WHERE name = 'RequiresWeightCheck' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes DROP COLUMN RequiresWeightCheck;

-- Add new columns that match DTOs
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'TenantId' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes ADD TenantId UNIQUEIDENTIFIER NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'RequiresServiceTechnician' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes ADD RequiresServiceTechnician BIT NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'FrequencyDays' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    ALTER TABLE dbo.InspectionTypes ADD FrequencyDays INT NOT NULL DEFAULT 365;

-- Add foreign key to Tenants
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_InspectionTypes_Tenants')
    ALTER TABLE dbo.InspectionTypes
    ADD CONSTRAINT FK_InspectionTypes_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId);

-- Add index on TenantId
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_InspectionTypes_TenantId' AND object_id = OBJECT_ID('dbo.InspectionTypes'))
    CREATE INDEX IX_InspectionTypes_TenantId ON dbo.InspectionTypes(TenantId);

PRINT '✓ dbo.InspectionTypes altered to match InspectionTypeDto';

-- ============================================================================
-- ALTER LOCATIONS TO MATCH LocationDto
-- ============================================================================

PRINT 'Altering dbo.Locations...';

-- Add Latitude and Longitude
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Latitude' AND object_id = OBJECT_ID('dbo.Locations'))
    ALTER TABLE dbo.Locations ADD Latitude DECIMAL(10,7) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Longitude' AND object_id = OBJECT_ID('dbo.Locations'))
    ALTER TABLE dbo.Locations ADD Longitude DECIMAL(10,7) NULL;

-- Add LocationBarcodeData
IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'LocationBarcodeData' AND object_id = OBJECT_ID('dbo.Locations'))
    ALTER TABLE dbo.Locations ADD LocationBarcodeData NVARCHAR(500) NULL;

PRINT '✓ dbo.Locations altered to match LocationDto';

-- ============================================================================
-- VERIFY FINAL SCHEMA
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'Verification: InspectionTypes Columns';
PRINT '========================================';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'InspectionTypes' AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT '========================================';
PRINT 'Verification: Locations Columns';
PRINT '========================================';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Locations' AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT '✓ Schema alterations complete!';
PRINT '';

GO
