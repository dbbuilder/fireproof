/*============================================================================
  File:     FIX_ADD_INSPECTION_TYPES_TABLE.sql
  Summary:  Adds missing InspectionTypes table to DEMO001 tenant schema
  Date:     October 15, 2025

  Description:
    This script creates the InspectionTypes table that was missing from the
    tenant schema. Run this once to fix the issue, then run seed-base-data.js
============================================================================*/

USE FireProofDB
GO

-- Create InspectionTypes table for DEMO001 tenant
DECLARE @SchemaName NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'

PRINT 'Creating InspectionTypes table for schema: ' + @SchemaName

-- Check if table already exists
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName AND t.name = 'InspectionTypes'
)
BEGIN
    PRINT '  Table already exists. Skipping creation.'
END
ELSE
BEGIN
    -- Create the table
    DECLARE @Sql NVARCHAR(MAX) = '
        CREATE TABLE [' + @SchemaName + '].InspectionTypes (
            InspectionTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            TypeName NVARCHAR(100) NOT NULL,
            Description NVARCHAR(1000) NULL,
            RequiresServiceTechnician BIT NOT NULL DEFAULT 0,
            FrequencyDays INT NOT NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + REPLACE(@SchemaName, '-', '_') + '_InspectionTypes PRIMARY KEY CLUSTERED (InspectionTypeId)
        )'

    EXEC sp_executesql @Sql

    PRINT '  ✓ InspectionTypes table created successfully'
END

-- Verify table was created
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = @SchemaName AND t.name = 'InspectionTypes'
)
BEGIN
    PRINT ''
    PRINT '============================================================================'
    PRINT '✓ SUCCESS: InspectionTypes table is now available'
    PRINT '============================================================================'
    PRINT ''
    PRINT 'You can now run the seed script:'
    PRINT '  cd /mnt/d/Dev2/fireproof/scripts'
    PRINT '  node seed-base-data.js'
    PRINT ''
END
ELSE
BEGIN
    PRINT ''
    PRINT '============================================================================'
    PRINT '✗ ERROR: InspectionTypes table was not created'
    PRINT '============================================================================'
    PRINT ''
END

GO
