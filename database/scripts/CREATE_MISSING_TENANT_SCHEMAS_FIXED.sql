/*============================================================================
  File:     CREATE_MISSING_TENANT_SCHEMAS_FIXED.sql
  Purpose:  Create schemas and tables for DEMO001 and DEMO002 tenants
  Date:     October 13, 2025
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Tenant Schemas for DEMO001 and DEMO002'
PRINT '============================================================================'
PRINT ''

-- Get tenant info
DECLARE @TenantsTable TABLE (
    TenantId UNIQUEIDENTIFIER,
    TenantCode NVARCHAR(50),
    SchemaName NVARCHAR(128)
)

INSERT INTO @TenantsTable (TenantId, TenantCode, SchemaName)
SELECT TenantId, TenantCode, DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode IN ('DEMO001', 'DEMO002')

-- Process each tenant
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @TenantCode NVARCHAR(50)
DECLARE @SchemaName NVARCHAR(128)
DECLARE @Sql NVARCHAR(MAX)

DECLARE tenant_cursor CURSOR FOR
SELECT TenantId, TenantCode, SchemaName FROM @TenantsTable

OPEN tenant_cursor
FETCH NEXT FROM tenant_cursor INTO @TenantId, @TenantCode, @SchemaName

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing ' + @TenantCode + ' tenant...'
    PRINT '  Tenant ID: ' + CAST(@TenantId AS NVARCHAR(36))
    PRINT '  Schema Name: ' + @SchemaName
    PRINT ''

    -- Create schema
    SET @Sql = N'
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = @SchemaName)
    BEGIN
        DECLARE @CreateSchemaSQL NVARCHAR(500) = N''CREATE SCHEMA ['' + @SchemaName + '']''
        EXEC sp_executesql @CreateSchemaSQL
        PRINT ''  ✓ Schema created: '' + @SchemaName
    END
    ELSE
        PRINT ''  - Schema already exists: '' + @SchemaName'

    EXEC sp_executesql @Sql, N'@SchemaName NVARCHAR(128)', @SchemaName

    -- Create Locations table
    SET @Sql = N'
    DECLARE @FullTableName NVARCHAR(300) = QUOTENAME(@SchemaName) + ''.Locations''
    IF OBJECT_ID(@FullTableName, ''U'') IS NULL
    BEGIN
        DECLARE @CreateSQL NVARCHAR(MAX) = N''
        CREATE TABLE '' + QUOTENAME(@SchemaName) + ''.Locations (
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
            CONSTRAINT PK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Locations PRIMARY KEY CLUSTERED (LocationId),
            CONSTRAINT UQ_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Locations_Code UNIQUE (LocationCode)
        )

        CREATE NONCLUSTERED INDEX IX_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Locations_Code
            ON '' + QUOTENAME(@SchemaName) + ''.Locations(LocationCode)
        CREATE NONCLUSTERED INDEX IX_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Locations_Barcode
            ON '' + QUOTENAME(@SchemaName) + ''.Locations(LocationBarcodeData)''

        EXEC sp_executesql @CreateSQL
        PRINT ''  ✓ Created Locations table''
    END
    ELSE
        PRINT ''  - Locations table already exists'''

    EXEC sp_executesql @Sql, N'@SchemaName NVARCHAR(128)', @SchemaName

    -- Create ExtinguisherTypes table
    SET @Sql = N'
    DECLARE @FullTableName NVARCHAR(300) = QUOTENAME(@SchemaName) + ''.ExtinguisherTypes''
    IF OBJECT_ID(@FullTableName, ''U'') IS NULL
    BEGIN
        DECLARE @CreateSQL NVARCHAR(MAX) = N''
        CREATE TABLE '' + QUOTENAME(@SchemaName) + ''.ExtinguisherTypes (
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
            CONSTRAINT PK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_ExtTypes PRIMARY KEY CLUSTERED (ExtinguisherTypeId)
        )

        CREATE NONCLUSTERED INDEX IX_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_ExtTypes_Code
            ON '' + QUOTENAME(@SchemaName) + ''.ExtinguisherTypes(TypeCode)''

        EXEC sp_executesql @CreateSQL
        PRINT ''  ✓ Created ExtinguisherTypes table''
    END
    ELSE
        PRINT ''  - ExtinguisherTypes table already exists'''

    EXEC sp_executesql @Sql, N'@SchemaName NVARCHAR(128)', @SchemaName

    -- Create Extinguishers table
    SET @Sql = N'
    DECLARE @FullTableName NVARCHAR(300) = QUOTENAME(@SchemaName) + ''.Extinguishers''
    IF OBJECT_ID(@FullTableName, ''U'') IS NULL
    BEGIN
        DECLARE @CreateSQL NVARCHAR(MAX) = N''
        CREATE TABLE '' + QUOTENAME(@SchemaName) + ''.Extinguishers (
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
            CONSTRAINT PK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext PRIMARY KEY CLUSTERED (ExtinguisherId),
            CONSTRAINT FK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Loc
                FOREIGN KEY (LocationId) REFERENCES '' + QUOTENAME(@SchemaName) + ''.Locations(LocationId),
            CONSTRAINT FK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Type
                FOREIGN KEY (ExtinguisherTypeId) REFERENCES '' + QUOTENAME(@SchemaName) + ''.ExtinguisherTypes(ExtinguisherTypeId),
            CONSTRAINT UQ_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Asset UNIQUE (AssetTag),
            CONSTRAINT UQ_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Barcode UNIQUE (BarcodeData)
        )

        CREATE NONCLUSTERED INDEX IX_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Location
            ON '' + QUOTENAME(@SchemaName) + ''.Extinguishers(LocationId)
        CREATE NONCLUSTERED INDEX IX_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_Ext_Barcode
            ON '' + QUOTENAME(@SchemaName) + ''.Extinguishers(BarcodeData)''

        EXEC sp_executesql @CreateSQL
        PRINT ''  ✓ Created Extinguishers table''
    END
    ELSE
        PRINT ''  - Extinguishers table already exists'''

    EXEC sp_executesql @Sql, N'@SchemaName NVARCHAR(128)', @SchemaName

    -- Create InspectionTypes table
    SET @Sql = N'
    DECLARE @FullTableName NVARCHAR(300) = QUOTENAME(@SchemaName) + ''.InspectionTypes''
    IF OBJECT_ID(@FullTableName, ''U'') IS NULL
    BEGIN
        DECLARE @CreateSQL NVARCHAR(MAX) = N''
        CREATE TABLE '' + QUOTENAME(@SchemaName) + ''.InspectionTypes (
            InspectionTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            TypeName NVARCHAR(100) NOT NULL,
            Description NVARCHAR(1000) NULL,
            RequiresServiceTechnician BIT NOT NULL DEFAULT 0,
            FrequencyDays INT NOT NULL,
            IsActive BIT NOT NULL DEFAULT 1,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            CONSTRAINT PK_'' + REPLACE(@SchemaName, ''-'', ''_'') + ''_InspTypes PRIMARY KEY CLUSTERED (InspectionTypeId)
        )''

        EXEC sp_executesql @CreateSQL
        PRINT ''  ✓ Created InspectionTypes table''
    END
    ELSE
        PRINT ''  - InspectionTypes table already exists'''

    EXEC sp_executesql @Sql, N'@SchemaName NVARCHAR(128)', @SchemaName

    PRINT '  ✓ ' + @TenantCode + ' schema creation completed'
    PRINT ''

    FETCH NEXT FROM tenant_cursor INTO @TenantId, @TenantCode, @SchemaName
END

CLOSE tenant_cursor
DEALLOCATE tenant_cursor

PRINT '============================================================================'
PRINT 'Schema creation script completed!'
PRINT '============================================================================'
PRINT ''

GO
