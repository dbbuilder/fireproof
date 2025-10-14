/*============================================================================
  File:     CREATE_MISSING_TENANT_SCHEMAS.sql
  Purpose:  Create schemas and tables for DEMO001 and DEMO002 tenants
  Date:     October 13, 2025

  Instructions:
  1. Connect to FireProofDB using Azure Data Studio, SSMS, or sqlcmd
  2. Run this entire script
  3. Verify that both tenant schemas are created successfully
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Tenant Schemas for DEMO001 and DEMO002'
PRINT '============================================================================'
PRINT ''

-- Process DEMO001 tenant
DECLARE @Tenant1Id UNIQUEIDENTIFIER
DECLARE @Schema1Name NVARCHAR(128)

SELECT @Tenant1Id = TenantId, @Schema1Name = DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode = 'DEMO001'

IF @Tenant1Id IS NOT NULL
BEGIN
    PRINT 'Processing DEMO001 tenant...'
    PRINT '  Tenant ID: ' + CAST(@Tenant1Id AS NVARCHAR(36))
    PRINT '  Schema Name: ' + @Schema1Name
    PRINT ''

    -- Create schema
    DECLARE @CreateSchema1Sql NVARCHAR(MAX) =
        'IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''' + @Schema1Name + ''')
        BEGIN
            EXEC(''CREATE SCHEMA [' + @Schema1Name + ']'')
            PRINT ''  ✓ Schema created: ' + @Schema1Name + '''
        END
        ELSE
            PRINT ''  - Schema already exists: ' + @Schema1Name + ''''

    EXEC sp_executesql @CreateSchema1Sql

    -- Create Locations table
    DECLARE @CreateLoc1Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''[' + @Schema1Name + '].Locations'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema1Name + '].Locations (
            LocationId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            LocationCode NVARCHAR(50) NOT NULL,
            LocationName NVARCHAR(200) NOT NULL,
            AddressLine1 NVARCHAR(200) NULL,
            AddressLine2 NVARCHAR(200) NULL,
            City NVARCHAR(100) NULL,
            StateProvince NVARCHAR(100) NULL,
            PostalCode NVARCHAR(20) NULL,
            Country NVARCHAR(100) NULL,
            Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL,
            LocationBarcodeData NVARCHAR(200) NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema1Name + '_Locations PRIMARY KEY CLUSTERED (LocationId),
            CONSTRAINT UQ_' + @Schema1Name + '_Locations_Code UNIQUE (LocationCode)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema1Name + '_Locations_Code ON [' + @Schema1Name + '].Locations(LocationCode)
        CREATE NONCLUSTERED INDEX IX_' + @Schema1Name + '_Locations_Barcode ON [' + @Schema1Name + '].Locations(LocationBarcodeData)

        PRINT ''  ✓ Created Locations table''
    END
    ELSE
        PRINT ''  - Locations table already exists'''

    EXEC sp_executesql @CreateLoc1Sql

    -- Create ExtinguisherTypes table
    DECLARE @CreateExtType1Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @Schema1Name + '.ExtinguisherTypes'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema1Name + '].ExtinguisherTypes (
            ExtinguisherTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            TypeCode NVARCHAR(50) NOT NULL,
            TypeName NVARCHAR(200) NOT NULL,
            Description NVARCHAR(1000) NULL,
            MonthlyInspectionRequired BIT NOT NULL DEFAULT 1,
            AnnualInspectionRequired BIT NOT NULL DEFAULT 1,
            HydrostaticTestYears INT NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema1Name + '_ExtTypes PRIMARY KEY CLUSTERED (ExtinguisherTypeId)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema1Name + '_ExtTypes_Code ON [' + @Schema1Name + '].ExtinguisherTypes(TypeCode)

        PRINT ''  ✓ Created ExtinguisherTypes table''
    END
    ELSE
        PRINT ''  - ExtinguisherTypes table already exists'''

    EXEC sp_executesql @CreateExtType1Sql

    -- Create Extinguishers table
    DECLARE @CreateExt1Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @Schema1Name + '.Extinguishers'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema1Name + '].Extinguishers (
            ExtinguisherId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            LocationId UNIQUEIDENTIFIER NOT NULL,
            ExtinguisherTypeId UNIQUEIDENTIFIER NOT NULL,
            AssetTag NVARCHAR(100) NOT NULL,
            BarcodeData NVARCHAR(200) NOT NULL,
            Manufacturer NVARCHAR(200) NULL,
            Model NVARCHAR(200) NULL,
            SerialNumber NVARCHAR(200) NULL,
            ManufactureDate DATE NULL,
            InstallDate DATE NULL,
            LastHydrostaticTestDate DATE NULL,
            Capacity NVARCHAR(50) NULL,
            LocationDescription NVARCHAR(500) NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema1Name + '_Ext PRIMARY KEY CLUSTERED (ExtinguisherId),
            CONSTRAINT FK_' + @Schema1Name + '_Ext_Loc FOREIGN KEY (LocationId) REFERENCES [' + @Schema1Name + '].Locations(LocationId),
            CONSTRAINT FK_' + @Schema1Name + '_Ext_Type FOREIGN KEY (ExtinguisherTypeId) REFERENCES [' + @Schema1Name + '].ExtinguisherTypes(ExtinguisherTypeId),
            CONSTRAINT UQ_' + @Schema1Name + '_Ext_Asset UNIQUE (AssetTag),
            CONSTRAINT UQ_' + @Schema1Name + '_Ext_Barcode UNIQUE (BarcodeData)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema1Name + '_Ext_Location ON [' + @Schema1Name + '].Extinguishers(LocationId)
        CREATE NONCLUSTERED INDEX IX_' + @Schema1Name + '_Ext_Barcode ON [' + @Schema1Name + '].Extinguishers(BarcodeData)

        PRINT ''  ✓ Created Extinguishers table''
    END
    ELSE
        PRINT ''  - Extinguishers table already exists'''

    EXEC sp_executesql @CreateExt1Sql

    PRINT '  ✓ DEMO001 schema creation completed'
    PRINT ''
END
ELSE
BEGIN
    PRINT '⚠ DEMO001 tenant not found in dbo.Tenants table'
    PRINT ''
END

-- Process DEMO002 tenant
DECLARE @Tenant2Id UNIQUEIDENTIFIER
DECLARE @Schema2Name NVARCHAR(128)

SELECT @Tenant2Id = TenantId, @Schema2Name = DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode = 'DEMO002'

IF @Tenant2Id IS NOT NULL
BEGIN
    PRINT 'Processing DEMO002 tenant...'
    PRINT '  Tenant ID: ' + CAST(@Tenant2Id AS NVARCHAR(36))
    PRINT '  Schema Name: ' + @Schema2Name
    PRINT ''

    -- Create schema
    DECLARE @CreateSchema2Sql NVARCHAR(MAX) =
        'IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''' + @Schema2Name + ''')
        BEGIN
            EXEC(''CREATE SCHEMA [' + @Schema2Name + ']'')
            PRINT ''  ✓ Schema created: ' + @Schema2Name + '''
        END
        ELSE
            PRINT ''  - Schema already exists: ' + @Schema2Name + ''''

    EXEC sp_executesql @CreateSchema2Sql

    -- Create Locations table
    DECLARE @CreateLoc2Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @Schema2Name + '.Locations'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema2Name + '].Locations (
            LocationId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            LocationCode NVARCHAR(50) NOT NULL,
            LocationName NVARCHAR(200) NOT NULL,
            AddressLine1 NVARCHAR(200) NULL,
            AddressLine2 NVARCHAR(200) NULL,
            City NVARCHAR(100) NULL,
            StateProvince NVARCHAR(100) NULL,
            PostalCode NVARCHAR(20) NULL,
            Country NVARCHAR(100) NULL,
            Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL,
            LocationBarcodeData NVARCHAR(200) NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema2Name + '_Locations PRIMARY KEY CLUSTERED (LocationId),
            CONSTRAINT UQ_' + @Schema2Name + '_Locations_Code UNIQUE (LocationCode)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema2Name + '_Locations_Code ON [' + @Schema2Name + '].Locations(LocationCode)
        CREATE NONCLUSTERED INDEX IX_' + @Schema2Name + '_Locations_Barcode ON [' + @Schema2Name + '].Locations(LocationBarcodeData)

        PRINT ''  ✓ Created Locations table''
    END
    ELSE
        PRINT ''  - Locations table already exists'''

    EXEC sp_executesql @CreateLoc2Sql

    -- Create ExtinguisherTypes table
    DECLARE @CreateExtType2Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @Schema2Name + '.ExtinguisherTypes'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema2Name + '].ExtinguisherTypes (
            ExtinguisherTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            TypeCode NVARCHAR(50) NOT NULL,
            TypeName NVARCHAR(200) NOT NULL,
            Description NVARCHAR(1000) NULL,
            MonthlyInspectionRequired BIT NOT NULL DEFAULT 1,
            AnnualInspectionRequired BIT NOT NULL DEFAULT 1,
            HydrostaticTestYears INT NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema2Name + '_ExtTypes PRIMARY KEY CLUSTERED (ExtinguisherTypeId)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema2Name + '_ExtTypes_Code ON [' + @Schema2Name + '].ExtinguisherTypes(TypeCode)

        PRINT ''  ✓ Created ExtinguisherTypes table''
    END
    ELSE
        PRINT ''  - ExtinguisherTypes table already exists'''

    EXEC sp_executesql @CreateExtType2Sql

    -- Create Extinguishers table
    DECLARE @CreateExt2Sql NVARCHAR(MAX) = '
    IF OBJECT_ID(''' + @Schema2Name + '.Extinguishers'', ''U'') IS NULL
    BEGIN
        CREATE TABLE [' + @Schema2Name + '].Extinguishers (
            ExtinguisherId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            LocationId UNIQUEIDENTIFIER NOT NULL,
            ExtinguisherTypeId UNIQUEIDENTIFIER NOT NULL,
            AssetTag NVARCHAR(100) NOT NULL,
            BarcodeData NVARCHAR(200) NOT NULL,
            Manufacturer NVARCHAR(200) NULL,
            Model NVARCHAR(200) NULL,
            SerialNumber NVARCHAR(200) NULL,
            ManufactureDate DATE NULL,
            InstallDate DATE NULL,
            LastHydrostaticTestDate DATE NULL,
            Capacity NVARCHAR(50) NULL,
            LocationDescription NVARCHAR(500) NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_' + @Schema2Name + '_Ext PRIMARY KEY CLUSTERED (ExtinguisherId),
            CONSTRAINT FK_' + @Schema2Name + '_Ext_Loc FOREIGN KEY (LocationId) REFERENCES [' + @Schema2Name + '].Locations(LocationId),
            CONSTRAINT FK_' + @Schema2Name + '_Ext_Type FOREIGN KEY (ExtinguisherTypeId) REFERENCES [' + @Schema2Name + '].ExtinguisherTypes(ExtinguisherTypeId),
            CONSTRAINT UQ_' + @Schema2Name + '_Ext_Asset UNIQUE (AssetTag),
            CONSTRAINT UQ_' + @Schema2Name + '_Ext_Barcode UNIQUE (BarcodeData)
        )

        CREATE NONCLUSTERED INDEX IX_' + @Schema2Name + '_Ext_Location ON [' + @Schema2Name + '].Extinguishers(LocationId)
        CREATE NONCLUSTERED INDEX IX_' + @Schema2Name + '_Ext_Barcode ON [' + @Schema2Name + '].Extinguishers(BarcodeData)

        PRINT ''  ✓ Created Extinguishers table''
    END
    ELSE
        PRINT ''  - Extinguishers table already exists'''

    EXEC sp_executesql @CreateExt2Sql

    PRINT '  ✓ DEMO002 schema creation completed'
    PRINT ''
END
ELSE
BEGIN
    PRINT '⚠ DEMO002 tenant not found in dbo.Tenants table'
    PRINT ''
END

PRINT '============================================================================'
PRINT 'Schema creation script completed!'
PRINT '============================================================================'
PRINT ''
PRINT 'Verification:'

-- Verify schemas exist
IF EXISTS (SELECT * FROM sys.schemas WHERE name LIKE 'tenant_%')
BEGIN
    PRINT '  ✓ Tenant schemas found:'
    SELECT '    - ' + name AS SchemaName FROM sys.schemas WHERE name LIKE 'tenant_%' ORDER BY name
END
ELSE
BEGIN
    PRINT '  ✗ No tenant schemas found'
END

PRINT ''
PRINT 'Next steps:'
PRINT '  1. Test locations API: GET /api/locations'
PRINT '  2. If working, you can now create locations via the UI'
PRINT ''

GO
