/*============================================================================
  File:     FIX_INSPECTIONS_SCHEMA.sql
  Purpose:  Add missing columns to dbo.Inspections table to match service code expectations
  Date:     October 18, 2025
  Issue:    InspectionService expects many columns that don't exist in current schema
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Adding Missing Columns to dbo.Inspections'
PRINT '============================================================================'

-- Add InspectionType (string value, not just InspectionTypeId)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'InspectionType'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD InspectionType NVARCHAR(50) NULL;
    PRINT '✓ Added InspectionType column';
END
ELSE
    PRINT '- InspectionType column already exists';

-- Add DamageDescription
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'DamageDescription'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD DamageDescription NVARCHAR(MAX) NULL;
    PRINT '✓ Added DamageDescription column';
END
ELSE
    PRINT '- DamageDescription column already exists';

-- Add WeightPounds
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'WeightPounds'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD WeightPounds DECIMAL(6, 2) NULL;
    PRINT '✓ Added WeightPounds column';
END
ELSE
    PRINT '- WeightPounds column already exists';

-- Add WeightWithinSpec
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'WeightWithinSpec'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD WeightWithinSpec BIT NOT NULL DEFAULT 1;
    PRINT '✓ Added WeightWithinSpec column';
END
ELSE
    PRINT '- WeightWithinSpec column already exists';

-- Add PreviousInspectionDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'PreviousInspectionDate'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD PreviousInspectionDate NVARCHAR(50) NULL;
    PRINT '✓ Added PreviousInspectionDate column';
END
ELSE
    PRINT '- PreviousInspectionDate column already exists';

-- Add PhotoUrls
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'PhotoUrls'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD PhotoUrls NVARCHAR(MAX) NULL;
    PRINT '✓ Added PhotoUrls column';
END
ELSE
    PRINT '- PhotoUrls column already exists';

-- Add DataHash (for tamper-proofing)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'DataHash'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD DataHash NVARCHAR(100) NULL;
    PRINT '✓ Added DataHash column';
END
ELSE
    PRINT '- DataHash column already exists';

-- Add InspectorSignature
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'InspectorSignature'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD InspectorSignature NVARCHAR(MAX) NOT NULL DEFAULT '';
    PRINT '✓ Added InspectorSignature column';
END
ELSE
    PRINT '- InspectorSignature column already exists';

-- Add SignedDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'SignedDate'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD SignedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT '✓ Added SignedDate column';
END
ELSE
    PRINT '- SignedDate column already exists';

-- Add IsVerified
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'IsVerified'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD IsVerified BIT NOT NULL DEFAULT 0;
    PRINT '✓ Added IsVerified column';
END
ELSE
    PRINT '- IsVerified column already exists';

-- Add ModifiedDate
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'ModifiedDate'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE();
    PRINT '✓ Added ModifiedDate column';
END
ELSE
    PRINT '- ModifiedDate column already exists';

-- Add LocationVerified
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'LocationVerified'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD LocationVerified BIT NOT NULL DEFAULT 0;
    PRINT '✓ Added LocationVerified column';
END
ELSE
    PRINT '- LocationVerified column already exists';

-- Add camelCase GPS columns (GpsLatitude, GpsLongitude, GpsAccuracyMeters)
-- Note: If GPSLatitude exists, we'll rename it to GpsLatitude for consistency
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GPSLatitude'
)
AND NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GpsLatitude'
)
BEGIN
    EXEC sp_rename 'dbo.Inspections.GPSLatitude', 'GpsLatitude', 'COLUMN';
    PRINT '✓ Renamed GPSLatitude to GpsLatitude';
END
ELSE IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GpsLatitude'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD GpsLatitude DECIMAL(10, 7) NULL;
    PRINT '✓ Added GpsLatitude column';
END
ELSE
    PRINT '- GpsLatitude column already exists';

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GPSLongitude'
)
AND NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GpsLongitude'
)
BEGIN
    EXEC sp_rename 'dbo.Inspections.GPSLongitude', 'GpsLongitude', 'COLUMN';
    PRINT '✓ Renamed GPSLongitude to GpsLongitude';
END
ELSE IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GpsLongitude'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD GpsLongitude DECIMAL(10, 7) NULL;
    PRINT '✓ Added GpsLongitude column';
END
ELSE
    PRINT '- GpsLongitude column already exists';

-- Add GpsAccuracyMeters
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'Inspections'
    AND COLUMN_NAME = 'GpsAccuracyMeters'
)
BEGIN
    ALTER TABLE dbo.Inspections
    ADD GpsAccuracyMeters INT NULL;
    PRINT '✓ Added GpsAccuracyMeters column';
END
ELSE
    PRINT '- GpsAccuracyMeters column already exists';

PRINT ''
PRINT '============================================================================'
PRINT 'Schema Updates Complete!'
PRINT '============================================================================'

GO
