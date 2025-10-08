/*============================================================================
  File:     002_CreateTenantSchema.sql
  Summary:  Creates tenant-specific schema and tables
  Date:     October 8, 2025
  
  Description:
    This script creates a template for tenant-specific tables. Each tenant
    gets their own schema (tenant_<guid>) with isolated tables for locations,
    extinguishers, inspections, and related data.
    
  Notes:
    - This is a template script
    - Replace {tenant_schema} with actual tenant schema name
    - Run for each new tenant during provisioning
    - All foreign keys reference within same tenant schema
============================================================================*/

-- Print script execution start
PRINT 'Starting 002_CreateTenantSchema.sql execution...'
PRINT 'Creating tenant-specific schema and tables'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

/*============================================================================
  VARIABLES: Set tenant-specific values
============================================================================*/
-- Example: Use the sample tenant from previous script
-- In production, this would be dynamically generated during tenant provisioning
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @SchemaName NVARCHAR(128)

-- Get the first (demo) tenant
SELECT TOP 1 @TenantId = TenantId, @SchemaName = DatabaseSchema 
FROM dbo.Tenants 
WHERE TenantCode = 'DEMO001'

IF @TenantId IS NULL
BEGIN
    PRINT 'ERROR: No tenant found. Please run 001_CreateCoreSchema.sql first'
    RETURN
END

PRINT 'Creating schema for tenant:'
PRINT '  Tenant ID: ' + CAST(@TenantId AS NVARCHAR(36))
PRINT '  Schema Name: ' + @SchemaName
PRINT ''

-- Create the schema if it doesn't exist
DECLARE @CreateSchemaSql NVARCHAR(MAX) = 
    'IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = ''' + @SchemaName + ''')
    BEGIN
        EXEC(''CREATE SCHEMA [' + @SchemaName + ']'')
        PRINT ''  - Schema created: ' + @SchemaName + '''
    END
    ELSE
        PRINT ''  - Schema already exists: ' + @SchemaName + ''''

EXEC sp_executesql @CreateSchemaSql
PRINT ''

/*============================================================================
  TABLE: Locations
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Locations'

DECLARE @CreateLocationsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Locations'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].Locations

CREATE TABLE [' + @SchemaName + '].Locations (
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
    CONSTRAINT PK_' + @SchemaName + '_Locations PRIMARY KEY CLUSTERED (LocationId),
    CONSTRAINT UQ_' + @SchemaName + '_Locations_Code UNIQUE (LocationCode)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Code ON [' + @SchemaName + '].Locations(LocationCode)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Barcode ON [' + @SchemaName + '].Locations(LocationBarcodeData)
'
EXEC sp_executesql @CreateLocationsSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: ExtinguisherTypes
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ExtinguisherTypes'

DECLARE @CreateExtTypeSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ExtinguisherTypes'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].ExtinguisherTypes

CREATE TABLE [' + @SchemaName + '].ExtinguisherTypes (
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
    CONSTRAINT PK_' + @SchemaName + '_ExtinguisherTypes PRIMARY KEY CLUSTERED (ExtinguisherTypeId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_ExtTypes_Code ON [' + @SchemaName + '].ExtinguisherTypes(TypeCode)
'
EXEC sp_executesql @CreateExtTypeSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: Extinguishers
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Extinguishers'

DECLARE @CreateExtinguishersSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Extinguishers'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].Extinguishers

CREATE TABLE [' + @SchemaName + '].Extinguishers (
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
    CONSTRAINT PK_' + @SchemaName + '_Extinguishers PRIMARY KEY CLUSTERED (ExtinguisherId),
    CONSTRAINT FK_' + @SchemaName + '_Ext_Location FOREIGN KEY (LocationId) REFERENCES [' + @SchemaName + '].Locations(LocationId),
    CONSTRAINT FK_' + @SchemaName + '_Ext_Type FOREIGN KEY (ExtinguisherTypeId) REFERENCES [' + @SchemaName + '].ExtinguisherTypes(ExtinguisherTypeId),
    CONSTRAINT UQ_' + @SchemaName + '_Ext_AssetTag UNIQUE (AssetTag),
    CONSTRAINT UQ_' + @SchemaName + '_Ext_Barcode UNIQUE (BarcodeData)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Ext_Location ON [' + @SchemaName + '].Extinguishers(LocationId)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Ext_Barcode ON [' + @SchemaName + '].Extinguishers(BarcodeData)
'
EXEC sp_executesql @CreateExtinguishersSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionTypes
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionTypes'

DECLARE @CreateInspTypeSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionTypes'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].InspectionTypes

CREATE TABLE [' + @SchemaName + '].InspectionTypes (
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(1000) NULL,
    RequiresServiceTechnician BIT NOT NULL DEFAULT 0,
    FrequencyDays INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_InspectionTypes PRIMARY KEY CLUSTERED (InspectionTypeId)
)
'
EXEC sp_executesql @CreateInspTypeSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistTemplates
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistTemplates'

DECLARE @CreateChecklistTmplSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistTemplates'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].InspectionChecklistTemplates

CREATE TABLE [' + @SchemaName + '].InspectionChecklistTemplates (
    ChecklistTemplateId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    TemplateName NVARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_ChecklistTemplates PRIMARY KEY CLUSTERED (ChecklistTemplateId),
    CONSTRAINT FK_' + @SchemaName + '_Tmpl_InspType FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId)
)
'
EXEC sp_executesql @CreateChecklistTmplSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: ChecklistItems
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ChecklistItems'

DECLARE @CreateChecklistItemsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ChecklistItems'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].ChecklistItems

CREATE TABLE [' + @SchemaName + '].ChecklistItems (
    ChecklistItemId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ChecklistTemplateId UNIQUEIDENTIFIER NOT NULL,
    ItemText NVARCHAR(500) NOT NULL,
    ItemOrder INT NOT NULL,
    IsRequired BIT NOT NULL DEFAULT 1,
    RequiresPhoto BIT NOT NULL DEFAULT 0,
    RequiresNote BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_ChecklistItems PRIMARY KEY CLUSTERED (ChecklistItemId),
    CONSTRAINT FK_' + @SchemaName + '_Item_Template FOREIGN KEY (ChecklistTemplateId) REFERENCES [' + @SchemaName + '].InspectionChecklistTemplates(ChecklistTemplateId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Items_Template ON [' + @SchemaName + '].ChecklistItems(ChecklistTemplateId, ItemOrder)
'
EXEC sp_executesql @CreateChecklistItemsSql
PRINT '  - Table created successfully'
PRINT ''

PRINT '============================================================================'
PRINT 'Tenant schema creation completed successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT '============================================================================'

GO
