/*******************************************************************************
 * MIGRATION: Schema-Per-Tenant → Standard Schema with TenantId
 *
 * This script migrates from schema-per-tenant to a standard multi-tenant
 * architecture with TenantId columns for row-level security.
 *
 * BEFORE: Each tenant has their own schema with duplicate tables
 * AFTER: Single dbo schema with TenantId columns on tenant-specific tables
 *
 * Execution time: ~5-10 minutes
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Phase 1: Create Standard Schema Tables';
PRINT '========================================';

-- Reference Tables (NO TenantId - shared across all tenants)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExtinguisherTypes' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'Creating dbo.ExtinguisherTypes...';
    CREATE TABLE dbo.ExtinguisherTypes (
        ExtinguisherTypeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TypeCode NVARCHAR(50) NOT NULL UNIQUE,
        TypeName NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        MonthlyInspectionRequired BIT NOT NULL DEFAULT 1,
        AnnualInspectionRequired BIT NOT NULL DEFAULT 1,
        HydrostaticTestYears INT,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
    CREATE INDEX IX_ExtinguisherTypes_TypeCode ON dbo.ExtinguisherTypes(TypeCode);
    CREATE INDEX IX_ExtinguisherTypes_IsActive ON dbo.ExtinguisherTypes(IsActive);
    PRINT '✓ dbo.ExtinguisherTypes created';
END
ELSE
    PRINT '→ dbo.ExtinguisherTypes already exists';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InspectionTypes' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'Creating dbo.InspectionTypes...';
    CREATE TABLE dbo.InspectionTypes (
        InspectionTypeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TypeCode NVARCHAR(50) NOT NULL UNIQUE,
        TypeName NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        IntervalMonths INT,
        RequiresPhotos BIT NOT NULL DEFAULT 0,
        RequiresPressureCheck BIT NOT NULL DEFAULT 0,
        RequiresWeightCheck BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
    CREATE INDEX IX_InspectionTypes_TypeCode ON dbo.InspectionTypes(TypeCode);
    CREATE INDEX IX_InspectionTypes_IsActive ON dbo.InspectionTypes(IsActive);
    PRINT '✓ dbo.InspectionTypes created';
END
ELSE
    PRINT '→ dbo.InspectionTypes already exists';

-- Tenant-Specific Tables (WITH TenantId)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Locations' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'Creating dbo.Locations...';
    CREATE TABLE dbo.Locations (
        LocationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        LocationCode NVARCHAR(50) NOT NULL,
        LocationName NVARCHAR(200) NOT NULL,
        AddressLine1 NVARCHAR(200),
        AddressLine2 NVARCHAR(200),
        City NVARCHAR(100),
        StateProvince NVARCHAR(100),
        PostalCode NVARCHAR(20),
        Country NVARCHAR(100),
        ContactName NVARCHAR(200),
        ContactPhone NVARCHAR(50),
        ContactEmail NVARCHAR(200),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Locations_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT UQ_Locations_TenantCode UNIQUE (TenantId, LocationCode)
    );
    CREATE INDEX IX_Locations_TenantId ON dbo.Locations(TenantId);
    CREATE INDEX IX_Locations_IsActive ON dbo.Locations(TenantId, IsActive);
    PRINT '✓ dbo.Locations created';
END
ELSE
    PRINT '→ dbo.Locations already exists';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Extinguishers' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'Creating dbo.Extinguishers...';
    CREATE TABLE dbo.Extinguishers (
        ExtinguisherId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        LocationId UNIQUEIDENTIFIER NOT NULL,
        ExtinguisherTypeId UNIQUEIDENTIFIER NOT NULL,
        AssetTag NVARCHAR(100) NOT NULL,
        BarcodeData NVARCHAR(500),
        Manufacturer NVARCHAR(200),
        Model NVARCHAR(200),
        SerialNumber NVARCHAR(200),
        ManufactureDate DATE,
        InstallDate DATE,
        LastHydrostaticTestDate DATE,
        Capacity NVARCHAR(50),
        LocationDescription NVARCHAR(500),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Extinguishers_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT FK_Extinguishers_Locations FOREIGN KEY (LocationId) REFERENCES dbo.Locations(LocationId),
        CONSTRAINT FK_Extinguishers_Types FOREIGN KEY (ExtinguisherTypeId) REFERENCES dbo.ExtinguisherTypes(ExtinguisherTypeId),
        CONSTRAINT UQ_Extinguishers_TenantAssetTag UNIQUE (TenantId, AssetTag)
    );
    CREATE INDEX IX_Extinguishers_TenantId ON dbo.Extinguishers(TenantId);
    CREATE INDEX IX_Extinguishers_LocationId ON dbo.Extinguishers(LocationId);
    CREATE INDEX IX_Extinguishers_TypeId ON dbo.Extinguishers(ExtinguisherTypeId);
    CREATE INDEX IX_Extinguishers_AssetTag ON dbo.Extinguishers(TenantId, AssetTag);
    CREATE INDEX IX_Extinguishers_IsActive ON dbo.Extinguishers(TenantId, IsActive);
    PRINT '✓ dbo.Extinguishers created';
END
ELSE
    PRINT '→ dbo.Extinguishers already exists';

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inspections' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    PRINT 'Creating dbo.Inspections...';
    CREATE TABLE dbo.Inspections (
        InspectionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
        InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
        InspectorUserId UNIQUEIDENTIFIER NOT NULL,
        InspectionDate DATETIME2 NOT NULL,
        Passed BIT NOT NULL,
        IsAccessible BIT NOT NULL DEFAULT 1,
        HasObstructions BIT NOT NULL DEFAULT 0,
        SignageVisible BIT NOT NULL DEFAULT 1,
        SealIntact BIT,
        PinInPlace BIT,
        NozzleClear BIT,
        HoseConditionGood BIT,
        GaugeInGreenZone BIT,
        GaugePressurePsi DECIMAL(6, 2),
        PhysicalDamagePresent BIT NOT NULL DEFAULT 0,
        InspectionTagAttached BIT NOT NULL DEFAULT 1,
        RequiresService BIT NOT NULL DEFAULT 0,
        RequiresReplacement BIT NOT NULL DEFAULT 0,
        Notes NVARCHAR(MAX),
        FailureReason NVARCHAR(MAX),
        CorrectiveAction NVARCHAR(MAX),
        GPSLatitude DECIMAL(10, 7),
        GPSLongitude DECIMAL(10, 7),
        DeviceId NVARCHAR(200),
        TamperProofHash NVARCHAR(100),
        PreviousInspectionHash NVARCHAR(100),
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Inspections_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT FK_Inspections_Extinguishers FOREIGN KEY (ExtinguisherId) REFERENCES dbo.Extinguishers(ExtinguisherId),
        CONSTRAINT FK_Inspections_Types FOREIGN KEY (InspectionTypeId) REFERENCES dbo.InspectionTypes(InspectionTypeId),
        CONSTRAINT FK_Inspections_Inspectors FOREIGN KEY (InspectorUserId) REFERENCES dbo.Users(UserId)
    );
    CREATE INDEX IX_Inspections_TenantId ON dbo.Inspections(TenantId);
    CREATE INDEX IX_Inspections_ExtinguisherId ON dbo.Inspections(ExtinguisherId);
    CREATE INDEX IX_Inspections_Date ON dbo.Inspections(TenantId, InspectionDate DESC);
    CREATE INDEX IX_Inspections_Inspector ON dbo.Inspections(InspectorUserId);
    CREATE INDEX IX_Inspections_Hash ON dbo.Inspections(TamperProofHash);
    PRINT '✓ dbo.Inspections created';
END
ELSE
    PRINT '→ dbo.Inspections already exists';

PRINT '';
PRINT '========================================';
PRINT 'Phase 2: Migrate Data from Tenant Schemas';
PRINT '========================================';

-- Get first tenant schema to migrate data from
DECLARE @TenantSchema NVARCHAR(200);
DECLARE @SQL NVARCHAR(MAX);

SELECT TOP 1 @TenantSchema = SCHEMA_NAME(schema_id)
FROM sys.tables
WHERE name = 'ExtinguisherTypes'
  AND SCHEMA_NAME(schema_id) LIKE 'tenant_%'
ORDER BY SCHEMA_NAME(schema_id);

IF @TenantSchema IS NOT NULL
BEGIN
    PRINT 'Found tenant schema: ' + @TenantSchema;

    -- Migrate ExtinguisherTypes (de-duplicate)
    PRINT 'Migrating ExtinguisherTypes...';
    SET @SQL = N'
    INSERT INTO dbo.ExtinguisherTypes (ExtinguisherTypeId, TypeCode, TypeName, Description,
        MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears, IsActive, CreatedDate)
    SELECT DISTINCT ExtinguisherTypeId, TypeCode, TypeName, Description,
        MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears, IsActive, CreatedDate
    FROM [' + @TenantSchema + '].ExtinguisherTypes
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.ExtinguisherTypes
        WHERE TypeCode = [' + @TenantSchema + '].ExtinguisherTypes.TypeCode
    );';
    EXEC sp_executesql @SQL;
    PRINT '✓ ExtinguisherTypes migrated';

    -- Migrate InspectionTypes (de-duplicate)
    PRINT 'Migrating InspectionTypes...';
    SET @SQL = N'
    INSERT INTO dbo.InspectionTypes (InspectionTypeId, TypeCode, TypeName, Description,
        IntervalMonths, RequiresPhotos, RequiresPressureCheck, RequiresWeightCheck, IsActive, CreatedDate)
    SELECT DISTINCT InspectionTypeId, TypeCode, TypeName, Description,
        IntervalMonths, RequiresPhotos, RequiresPressureCheck, RequiresWeightCheck, IsActive, CreatedDate
    FROM [' + @TenantSchema + '].InspectionTypes
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.InspectionTypes
        WHERE TypeCode = [' + @TenantSchema + '].InspectionTypes.TypeCode
    );';
    EXEC sp_executesql @SQL;
    PRINT '✓ InspectionTypes migrated';

    -- Extract TenantId from schema name
    DECLARE @TenantId NVARCHAR(100) = REPLACE(REPLACE(@TenantSchema, 'tenant_', ''), '-', '-');
    PRINT 'Extracted TenantId: ' + @TenantId;

    -- Migrate Locations
    PRINT 'Migrating Locations...';
    SET @SQL = N'
    INSERT INTO dbo.Locations (LocationId, TenantId, LocationCode, LocationName,
        AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
        ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate)
    SELECT LocationId, TenantId, LocationCode, LocationName,
        AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
        ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM [' + @TenantSchema + '].Locations
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Locations
        WHERE LocationId = [' + @TenantSchema + '].Locations.LocationId
    );';
    EXEC sp_executesql @SQL;
    PRINT '✓ Locations migrated';

    -- Check if Extinguishers table exists in tenant schema
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Extinguishers' AND schema_id = SCHEMA_ID(@TenantSchema))
    BEGIN
        PRINT 'Migrating Extinguishers...';
        SET @SQL = N'
        INSERT INTO dbo.Extinguishers (ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
            AssetTag, BarcodeData, Manufacturer, Model, SerialNumber, ManufactureDate, InstallDate,
            LastHydrostaticTestDate, Capacity, LocationDescription, IsActive, CreatedDate, ModifiedDate)
        SELECT ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
            AssetTag, BarcodeData, Manufacturer, Model, SerialNumber, ManufactureDate, InstallDate,
            LastHydrostaticTestDate, Capacity, LocationDescription, IsActive, CreatedDate, ModifiedDate
        FROM [' + @TenantSchema + '].Extinguishers
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Extinguishers
            WHERE ExtinguisherId = [' + @TenantSchema + '].Extinguishers.ExtinguisherId
        );';
        EXEC sp_executesql @SQL;
        PRINT '✓ Extinguishers migrated';
    END

    -- Check if Inspections table exists in tenant schema
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Inspections' AND schema_id = SCHEMA_ID(@TenantSchema))
    BEGIN
        PRINT 'Migrating Inspections...';
        SET @SQL = N'
        INSERT INTO dbo.Inspections (InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, Passed, IsAccessible, HasObstructions, SignageVisible, SealIntact, PinInPlace,
            NozzleClear, HoseConditionGood, GaugeInGreenZone, GaugePressurePsi, PhysicalDamagePresent,
            InspectionTagAttached, RequiresService, RequiresReplacement, Notes, FailureReason, CorrectiveAction,
            GPSLatitude, GPSLongitude, DeviceId, TamperProofHash, PreviousInspectionHash, CreatedDate)
        SELECT InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, Passed, IsAccessible, HasObstructions, SignageVisible, SealIntact, PinInPlace,
            NozzleClear, HoseConditionGood, GaugeInGreenZone, GaugePressurePsi, PhysicalDamagePresent,
            InspectionTagAttached, RequiresService, RequiresReplacement, Notes, FailureReason, CorrectiveAction,
            GPSLatitude, GPSLongitude, DeviceId, TamperProofHash, PreviousInspectionHash, CreatedDate
        FROM [' + @TenantSchema + '].Inspections
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Inspections
            WHERE InspectionId = [' + @TenantSchema + '].Inspections.InspectionId
        );';
        EXEC sp_executesql @SQL;
        PRINT '✓ Inspections migrated';
    END
END
ELSE
BEGIN
    PRINT '⚠ No tenant schemas found to migrate from';
END

PRINT '';
PRINT '========================================';
PRINT 'Phase 3: Create Stored Procedures';
PRINT '========================================';

-- We'll create these in a separate script for better organization
PRINT 'Stored procedures will be created in next script...';

PRINT '';
PRINT '========================================';
PRINT 'Migration Summary';
PRINT '========================================';

SELECT 'ExtinguisherTypes' AS TableName, COUNT(*) AS RecordCount FROM dbo.ExtinguisherTypes
UNION ALL
SELECT 'InspectionTypes', COUNT(*) FROM dbo.InspectionTypes
UNION ALL
SELECT 'Locations', COUNT(*) FROM dbo.Locations
UNION ALL
SELECT 'Extinguishers', COUNT(*) FROM dbo.Extinguishers
UNION ALL
SELECT 'Inspections', COUNT(*) FROM dbo.Inspections;

PRINT '';
PRINT '✓ Migration Phase 1 Complete!';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Run CREATE_STANDARD_STORED_PROCEDURES.sql';
PRINT '2. Update application code to use dbo schema';
PRINT '3. Test thoroughly';
PRINT '4. Drop old tenant schemas (optional)';

GO
