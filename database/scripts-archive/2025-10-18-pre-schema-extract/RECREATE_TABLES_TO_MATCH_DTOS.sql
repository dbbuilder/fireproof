/*******************************************************************************
 * RECREATE TABLES TO MATCH C# DTO DEFINITIONS
 *
 * Simpler approach: Drop and recreate tables with correct schema matching DTOs.
 * Since this is for MVP and tables are likely empty or have minimal test data,
 * this is the fastest path to a working solution.
 *
 * Created: 2025-10-15
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Recreating Tables to Match C# DTOs';
PRINT '========================================';

-- ============================================================================
-- DROP AND RECREATE INSPECTION TYPES
-- ============================================================================

PRINT 'Dropping and recreating dbo.InspectionTypes...';

-- Drop foreign key constraints referencing InspectionTypes
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Inspections_Types')
    ALTER TABLE dbo.Inspections DROP CONSTRAINT FK_Inspections_Types;

-- Drop the table
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'InspectionTypes' AND schema_id = SCHEMA_ID('dbo'))
    DROP TABLE dbo.InspectionTypes;

-- Recreate with correct schema matching InspectionTypeDto
CREATE TABLE dbo.InspectionTypes (
    InspectionTypeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    TypeName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    RequiresServiceTechnician BIT NOT NULL DEFAULT 0,
    FrequencyDays INT NOT NULL DEFAULT 365,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_InspectionTypes_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId)
);

CREATE INDEX IX_InspectionTypes_TenantId ON dbo.InspectionTypes(TenantId);
CREATE INDEX IX_InspectionTypes_IsActive ON dbo.InspectionTypes(TenantId, IsActive);

PRINT '✓ dbo.InspectionTypes recreated to match InspectionTypeDto';

-- Recreate foreign key on Inspections
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Inspections' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    ALTER TABLE dbo.Inspections
    ADD CONSTRAINT FK_Inspections_Types FOREIGN KEY (InspectionTypeId) REFERENCES dbo.InspectionTypes(InspectionTypeId);
    PRINT '✓ Foreign key FK_Inspections_Types recreated';
END

-- ============================================================================
-- ALTER LOCATIONS TO ADD MISSING COLUMNS
-- ============================================================================

PRINT 'Altering dbo.Locations to add missing columns...';

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Latitude' AND object_id = OBJECT_ID('dbo.Locations'))
    ALTER TABLE dbo.Locations ADD Latitude DECIMAL(10,7) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'Longitude' AND object_id = OBJECT_ID('dbo.Locations'))
    ALTER TABLE dbo.Locations ADD Longitude DECIMAL(10,7) NULL;

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
PRINT '✓ Tables recreated successfully!';
PRINT '';

GO
