/*============================================================================
  File:     ADD_MISSING_EXTINGUISHER_COLUMNS.sql
  Purpose:  Add missing columns to Extinguishers table
  Date:     October 14, 2025

  Adds the following columns expected by ExtinguisherService:
  - LastServiceDate
  - NextServiceDueDate
  - NextHydroTestDueDate
  - FloorLevel
  - Notes
  - QrCodeData
  - IsOutOfService
  - OutOfServiceReason
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Adding Missing Columns to Extinguishers Tables'
PRINT '============================================================================'
PRINT ''

-- Process each tenant
DECLARE @TenantCursor CURSOR
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @TenantCode NVARCHAR(50)
DECLARE @SchemaName NVARCHAR(128)

SET @TenantCursor = CURSOR FOR
SELECT TenantId, TenantCode, DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode IN ('DEMO001', 'DEMO002')

OPEN @TenantCursor
FETCH NEXT FROM @TenantCursor INTO @TenantId, @TenantCode, @SchemaName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing ' + @TenantCode + ' (Schema: ' + @SchemaName + ')...'

    -- Check and add LastServiceDate
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'LastServiceDate'
    )
    BEGIN
        DECLARE @AddLastServiceDate NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD LastServiceDate DATE NULL'
        EXEC sp_executesql @AddLastServiceDate
        PRINT '  ✓ Added LastServiceDate'
    END
    ELSE
        PRINT '  - LastServiceDate already exists'

    -- Check and add NextServiceDueDate
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'NextServiceDueDate'
    )
    BEGIN
        DECLARE @AddNextServiceDueDate NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD NextServiceDueDate DATE NULL'
        EXEC sp_executesql @AddNextServiceDueDate
        PRINT '  ✓ Added NextServiceDueDate'
    END
    ELSE
        PRINT '  - NextServiceDueDate already exists'

    -- Check and add NextHydroTestDueDate
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'NextHydroTestDueDate'
    )
    BEGIN
        DECLARE @AddNextHydroTestDueDate NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD NextHydroTestDueDate DATE NULL'
        EXEC sp_executesql @AddNextHydroTestDueDate
        PRINT '  ✓ Added NextHydroTestDueDate'
    END
    ELSE
        PRINT '  - NextHydroTestDueDate already exists'

    -- Check and add FloorLevel
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'FloorLevel'
    )
    BEGIN
        DECLARE @AddFloorLevel NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD FloorLevel NVARCHAR(50) NULL'
        EXEC sp_executesql @AddFloorLevel
        PRINT '  ✓ Added FloorLevel'
    END
    ELSE
        PRINT '  - FloorLevel already exists'

    -- Check and add Notes
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'Notes'
    )
    BEGIN
        DECLARE @AddNotes NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD Notes NVARCHAR(MAX) NULL'
        EXEC sp_executesql @AddNotes
        PRINT '  ✓ Added Notes'
    END
    ELSE
        PRINT '  - Notes already exists'

    -- Check and add QrCodeData
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'QrCodeData'
    )
    BEGIN
        DECLARE @AddQrCodeData NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD QrCodeData NVARCHAR(MAX) NULL'
        EXEC sp_executesql @AddQrCodeData
        PRINT '  ✓ Added QrCodeData'
    END
    ELSE
        PRINT '  - QrCodeData already exists'

    -- Check and add IsOutOfService
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'IsOutOfService'
    )
    BEGIN
        DECLARE @AddIsOutOfService NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD IsOutOfService BIT NOT NULL DEFAULT 0'
        EXEC sp_executesql @AddIsOutOfService
        PRINT '  ✓ Added IsOutOfService'
    END
    ELSE
        PRINT '  - IsOutOfService already exists'

    -- Check and add OutOfServiceReason
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'OutOfServiceReason'
    )
    BEGIN
        DECLARE @AddOutOfServiceReason NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD OutOfServiceReason NVARCHAR(500) NULL'
        EXEC sp_executesql @AddOutOfServiceReason
        PRINT '  ✓ Added OutOfServiceReason'
    END
    ELSE
        PRINT '  - OutOfServiceReason already exists'

    -- Add ExtinguisherCode as computed column
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = @SchemaName
        AND TABLE_NAME = 'Extinguishers'
        AND COLUMN_NAME = 'ExtinguisherCode'
    )
    BEGIN
        DECLARE @AddExtinguisherCode NVARCHAR(MAX) = '
        ALTER TABLE [' + @SchemaName + '].Extinguishers
        ADD ExtinguisherCode AS ISNULL(AssetTag, BarcodeData) PERSISTED'
        EXEC sp_executesql @AddExtinguisherCode
        PRINT '  ✓ Added ExtinguisherCode (computed column)'
    END
    ELSE
        PRINT '  - ExtinguisherCode already exists'

    PRINT '  ✓ ' + @TenantCode + ' completed'
    PRINT ''

    FETCH NEXT FROM @TenantCursor INTO @TenantId, @TenantCode, @SchemaName
END

CLOSE @TenantCursor
DEALLOCATE @TenantCursor

PRINT '============================================================================'
PRINT 'Missing Columns Added Successfully!'
PRINT '============================================================================'
PRINT ''

GO
