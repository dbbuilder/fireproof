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

EXEC sp_executesql @CreateLocationsSql

-- Create indexes
DECLARE @CreateLocationsIndexesSql NVARCHAR(MAX) = '
PRINT ''  - Creating indexes on ' + @SchemaName + '.Locations''
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Code ON [' + @SchemaName + '].Locations(LocationCode) INCLUDE (IsActive)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Barcode ON [' + @SchemaName + '].Locations(LocationBarcodeData) WHERE LocationBarcodeData IS NOT NULL
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_IsActive ON [' + @SchemaName + '].Locations(IsActive)
'
EXEC sp_executesql @CreateLocationsIndexesSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: ExtinguisherTypes
  Description: Types of fire extinguishers (ABC, BC, K, CO2, etc)
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ExtinguisherTypes'

DECLARE @CreateExtinguisherTypesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ExtinguisherTypes'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].ExtinguisherTypes
END

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

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_ExtinguisherTypes_Code ON [' + @SchemaName + '].ExtinguisherTypes(TypeCode) INCLUDE (IsActive)
'
EXEC sp_executesql @CreateExtinguisherTypesSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: Extinguishers
  Description: Individual fire extinguisher assets
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Extinguishers'

DECLARE @CreateExtinguishersSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Extinguishers'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].Extinguishers
END

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
    CONSTRAINT FK_' + @SchemaName + '_Extinguishers_Locations FOREIGN KEY (LocationId) REFERENCES [' + @SchemaName + '].Locations(LocationId),
    CONSTRAINT FK_' + @SchemaName + '_Extinguishers_Types FOREIGN KEY (ExtinguisherTypeId) REFERENCES [' + @SchemaName + '].ExtinguisherTypes(ExtinguisherTypeId),
    CONSTRAINT UQ_' + @SchemaName + '_Extinguishers_AssetTag UNIQUE (AssetTag),
    CONSTRAINT UQ_' + @SchemaName + '_Extinguishers_Barcode UNIQUE (BarcodeData)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Extinguishers_Location ON [' + @SchemaName + '].Extinguishers(LocationId) INCLUDE (IsActive)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Extinguishers_Barcode ON [' + @SchemaName + '].Extinguishers(BarcodeData) INCLUDE (IsActive)
'
EXEC sp_executesql @CreateExtinguishersSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionTypes
  Description: Types of inspections (Monthly, Annual, Hydrostatic)
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionTypes'

DECLARE @CreateInspectionTypesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionTypes'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionTypes
END

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
EXEC sp_executesql @CreateInspectionTypesSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistTemplates
  Description: Templates for inspection checklists
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistTemplates'

DECLARE @CreateChecklistTemplatesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistTemplates'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionChecklistTemplates
END

CREATE TABLE [' + @SchemaName + '].InspectionChecklistTemplates (
    ChecklistTemplateId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    TemplateName NVARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_ChecklistTemplates PRIMARY KEY CLUSTERED (ChecklistTemplateId),
    CONSTRAINT FK_' + @SchemaName + '_ChecklistTemplates_InspectionTypes FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId)
)
'
EXEC sp_executesql @CreateChecklistTemplatesSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: ChecklistItems
  Description: Individual items in a checklist template
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ChecklistItems'

DECLARE @CreateChecklistItemsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ChecklistItems'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].ChecklistItems
END

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
    CONSTRAINT FK_' + @SchemaName + '_ChecklistItems_Templates FOREIGN KEY (ChecklistTemplateId) REFERENCES [' + @SchemaName + '].InspectionChecklistTemplates(ChecklistTemplateId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_ChecklistItems_Template ON [' + @SchemaName + '].ChecklistItems(ChecklistTemplateId, ItemOrder)
'
EXEC sp_executesql @CreateChecklistItemsSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: Inspections
  Description: Actual inspection records with tamper-proofing
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Inspections'

DECLARE @CreateInspectionsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Inspections'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].Inspections
END

CREATE TABLE [' + @SchemaName + '].Inspections (
    InspectionId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    InspectorUserId UNIQUEIDENTIFIER NOT NULL,
    InspectionStartTime DATETIME2 NOT NULL,
    InspectionEndTime DATETIME2 NULL,
    InspectionStatus NVARCHAR(50) NOT NULL,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL,
    GpsAccuracy DECIMAL(10,2) NULL,
    DeviceFingerprint NVARCHAR(500) NULL,
    OverallResult NVARCHAR(50) NULL,
    InspectorNotes NVARCHAR(MAX) NULL,
    TamperHash NVARCHAR(128) NOT NULL,
    PreviousInspectionHash NVARCHAR(128) NULL,
    IsOfflineInspection BIT NOT NULL DEFAULT 0,
    SyncedDate DATETIME2 NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Inspections PRIMARY KEY CLUSTERED (InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_Inspections_Extinguishers FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId),
    CONSTRAINT FK_' + @SchemaName + '_Inspections_InspectionTypes FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId),
    CONSTRAINT CK_' + @SchemaName + '_Inspections_Status CHECK (InspectionStatus IN (''InProgress'', ''Completed'', ''Failed'')),
    CONSTRAINT CK_' + @SchemaName + '_Inspections_Result CHECK (OverallResult IN (''Pass'', ''Fail'', ''NeedsService'') OR OverallResult IS NULL)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Inspections_Extinguisher ON [' + @SchemaName + '].Inspections(ExtinguisherId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Inspections_StartTime ON [' + @SchemaName + '].Inspections(InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Inspections_Inspector ON [' + @SchemaName + '].Inspections(InspectorUserId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Inspections_Status ON [' + @SchemaName + '].Inspections(InspectionStatus) INCLUDE (InspectionStartTime)
'
EXEC sp_executesql @CreateInspectionsSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistResponses
  Description: Responses to each checklist item during inspection
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistResponses'

DECLARE @CreateChecklistResponsesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistResponses'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionChecklistResponses
END

CREATE TABLE [' + @SchemaName + '].InspectionChecklistResponses (
    ResponseId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    ChecklistItemId UNIQUEIDENTIFIER NOT NULL,
    ResponseValue NVARCHAR(50) NOT NULL,
    Notes NVARCHAR(MAX) NULL,
    PhotoBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_ChecklistResponses PRIMARY KEY CLUSTERED (ResponseId),
    CONSTRAINT FK_' + @SchemaName + '_ChecklistResponses_Inspections FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_ChecklistResponses_Items FOREIGN KEY (ChecklistItemId) REFERENCES [' + @SchemaName + '].ChecklistItems(ChecklistItemId),
    CONSTRAINT CK_' + @SchemaName + '_ChecklistResponses_Value CHECK (ResponseValue IN (''Pass'', ''Fail'', ''NA''))
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_ChecklistResponses_Inspection ON [' + @SchemaName + '].InspectionChecklistResponses(InspectionId)
'
EXEC sp_executesql @CreateChecklistResponsesSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionPhotos
  Description: Photos captured during inspections
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionPhotos'

DECLARE @CreateInspectionPhotosSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionPhotos'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionPhotos
END

CREATE TABLE [' + @SchemaName + '].InspectionPhotos (
    PhotoId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    BlobPath NVARCHAR(500) NOT NULL,
    FileName NVARCHAR(255) NOT NULL,
    FileSize BIGINT NOT NULL,
    ContentType NVARCHAR(100) NOT NULL,
    CaptureDate DATETIME2 NOT NULL,
    ExifData NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_InspectionPhotos PRIMARY KEY CLUSTERED (PhotoId),
    CONSTRAINT FK_' + @SchemaName + '_InspectionPhotos_Inspections FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_InspectionPhotos_Inspection ON [' + @SchemaName + '].InspectionPhotos(InspectionId)
'
EXEC sp_executesql @CreateInspectionPhotosSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: MaintenanceRecords
  Description: Maintenance and service records for extinguishers
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.MaintenanceRecords'

DECLARE @CreateMaintenanceRecordsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.MaintenanceRecords'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].MaintenanceRecords
END

CREATE TABLE [' + @SchemaName + '].MaintenanceRecords (
    MaintenanceRecordId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    MaintenanceType NVARCHAR(100) NOT NULL,
    MaintenanceDate DATE NOT NULL,
    TechnicianName NVARCHAR(200) NULL,
    ServiceCompany NVARCHAR(200) NULL,
    Cost DECIMAL(10,2) NULL,
    Notes NVARCHAR(MAX) NULL,
    ReceiptBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_MaintenanceRecords PRIMARY KEY CLUSTERED (MaintenanceRecordId),
    CONSTRAINT FK_' + @SchemaName + '_MaintenanceRecords_Extinguishers FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_MaintenanceRecords_Extinguisher ON [' + @SchemaName + '].MaintenanceRecords(ExtinguisherId, MaintenanceDate DESC)
'
EXEC sp_executesql @CreateMaintenanceRecordsSql

PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  SEED DATA: Insert sample data for this tenant
============================================================================*/
PRINT 'Inserting seed data for tenant schema...'

-- Insert sample extinguisher types
DECLARE @InsertTypesSql NVARCHAR(MAX) = '
DECLARE @Type1 UNIQUEIDENTIFIER = NEWID()
DECLARE @Type2 UNIQUEIDENTIFIER = NEWID()
DECLARE @Type3 UNIQUEIDENTIFIER = NEWID()

INSERT INTO [' + @SchemaName + '].ExtinguisherTypes (ExtinguisherTypeId, TenantId, TypeCode, TypeName, Description, MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears)
VALUES 
    (@Type1, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''ABC'', ''ABC Dry Chemical'', ''Multi-purpose dry chemical for Class A, B, and C fires'', 1, 1, 12),
    (@Type2, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''CO2'', ''Carbon Dioxide'', ''For Class B and C fires, safe for electronics'', 1, 1, 5),
    (@Type3, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''K'', ''Class K Wet Chemical'', ''For commercial kitchen fires involving cooking oils'', 1, 1, 5)

PRINT ''  - Inserted extinguisher types''
'
EXEC sp_executesql @InsertTypesSql

-- Insert sample inspection types
DECLARE @InsertInspectionTypesSql NVARCHAR(MAX) = '
DECLARE @Monthly UNIQUEIDENTIFIER = NEWID()
DECLARE @Annual UNIQUEIDENTIFIER = NEWID()

INSERT INTO [' + @SchemaName + '].InspectionTypes (InspectionTypeId, TenantId, TypeName, Description, RequiresServiceTechnician, FrequencyDays)
VALUES 
    (@Monthly, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''Monthly Visual'', ''Monthly visual inspection per NFPA 10'', 0, 30),
    (@Annual, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''Annual Maintenance'', ''Annual maintenance by certified technician'', 1, 365)

PRINT ''  - Inserted inspection types''

-- Insert sample checklist template for monthly inspection
DECLARE @MonthlyTemplate UNIQUEIDENTIFIER = NEWID()

INSERT INTO [' + @SchemaName + '].InspectionChecklistTemplates (ChecklistTemplateId, TenantId, InspectionTypeId, TemplateName)
VALUES (@MonthlyTemplate, ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', @Monthly, ''Standard Monthly Inspection'')

-- Insert checklist items
INSERT INTO [' + @SchemaName + '].ChecklistItems (ChecklistTemplateId, ItemText, ItemOrder, IsRequired, RequiresPhoto)
VALUES 
    (@MonthlyTemplate, ''Extinguisher is in designated location'', 1, 1, 0),
    (@MonthlyTemplate, ''Access to extinguisher is unobstructed'', 2, 1, 0),
    (@MonthlyTemplate, ''Pressure gauge shows in operable range (green zone)'', 3, 1, 1),
    (@MonthlyTemplate, ''Safety seal/tamper indicator is intact'', 4, 1, 1),
    (@MonthlyTemplate, ''Operating instructions are legible'', 5, 1, 0),
    (@MonthlyTemplate, ''Hose and nozzle are in good condition'', 6, 1, 0),
    (@MonthlyTemplate, ''Extinguisher has no visible damage or corrosion'', 7, 1, 0),
    (@MonthlyTemplate, ''Service tag is current and legible'', 8, 1, 1)

PRINT ''  - Inserted checklist template and items''
'
EXEC sp_executesql @InsertInspectionTypesSql

PRINT ''  - Seed data inserted successfully''
PRINT ''

/*============================================================================
  VERIFICATION: Verify all tables were created
============================================================================*/
PRINT 'Verifying tenant schema creation...'

DECLARE @VerifySql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Locations'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.Locations exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.Locations missing''

IF OBJECT_ID(''' + @SchemaName + '.ExtinguisherTypes'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.ExtinguisherTypes exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.ExtinguisherTypes missing''

IF OBJECT_ID(''' + @SchemaName + '.Extinguishers'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.Extinguishers exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.Extinguishers missing''

IF OBJECT_ID(''' + @SchemaName + '.InspectionTypes'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.InspectionTypes exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.InspectionTypes missing''

IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistTemplates'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.InspectionChecklistTemplates exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.InspectionChecklistTemplates missing''

IF OBJECT_ID(''' + @SchemaName + '.ChecklistItems'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.ChecklistItems exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.ChecklistItems missing''

IF OBJECT_ID(''' + @SchemaName + '.Inspections'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.Inspections exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.Inspections missing''

IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistResponses'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.InspectionChecklistResponses exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.InspectionChecklistResponses missing''

IF OBJECT_ID(''' + @SchemaName + '.InspectionPhotos'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.InspectionPhotos exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.InspectionPhotos missing''

IF OBJECT_ID(''' + @SchemaName + '.MaintenanceRecords'', ''U'') IS NOT NULL
    PRINT ''  ✓ ' + @SchemaName + '.MaintenanceRecords exists''
ELSE
    PRINT ''  ✗ ERROR: ' + @SchemaName + '.MaintenanceRecords missing''
'
EXEC sp_executesql @VerifySql

PRINT ''
PRINT '============================================================================'
PRINT 'Tenant schema creation completed successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT 'Next step: Run 003_CreateStoredProcedures.sql to create data access procedures'
PRINT '============================================================================'

GO
EXEC sp_executesql @CreateLocationsSql

DECLARE @CreateLocationsIndexesSql NVARCHAR(MAX) = '
PRINT ''  - Creating indexes on ' + @SchemaName + '.Locations''
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Code ON [' + @SchemaName + '].Locations(LocationCode)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_BarcodeData ON [' + @SchemaName + '].Locations(LocationBarcodeData) WHERE LocationBarcodeData IS NOT NULL
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_IsActive ON [' + @SchemaName + '].Locations(IsActive) INCLUDE (LocationName, City)
'
EXEC sp_executesql @CreateLocationsIndexesSql
PRINT '  - Table ' + @SchemaName + '.Locations created successfully'
PRINT ''

/*============================================================================
  TABLE: ExtinguisherTypes
  Description: Types of fire extinguishers (ABC, BC, K, CO2, etc.)
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ExtinguisherTypes'

DECLARE @CreateExtTypeSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ExtinguisherTypes'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].ExtinguisherTypes
END

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
    CONSTRAINT PK_' + @SchemaName + '_ExtinguisherTypes PRIMARY KEY CLUSTERED (ExtinguisherTypeId),
    CONSTRAINT UQ_' + @SchemaName + '_ExtinguisherTypes_TypeCode UNIQUE (TypeCode)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_ExtinguisherTypes_TypeCode ON [' + @SchemaName + '].ExtinguisherTypes(TypeCode) INCLUDE (TypeName)
'
EXEC sp_executesql @CreateExtTypeSql
PRINT '  - Table ' + @SchemaName + '.ExtinguisherTypes created successfully'
PRINT ''

/*============================================================================
  TABLE: Extinguishers
  Description: Individual fire extinguisher assets
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Extinguishers'

DECLARE @CreateExtSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Extinguishers'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].Extinguishers
END

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
    CONSTRAINT UQ_' + @SchemaName + '_Ext_BarcodeData UNIQUE (BarcodeData)
)
'
EXEC sp_executesql @CreateExtSql

DECLARE @CreateExtIndexesSql NVARCHAR(MAX) = '
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Ext_AssetTag ON [' + @SchemaName + '].Extinguishers(AssetTag)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Ext_BarcodeData ON [' + @SchemaName + '].Extinguishers(BarcodeData)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Ext_LocationId ON [' + @SchemaName + '].Extinguishers(LocationId) WHERE IsActive = 1
'
EXEC sp_executesql @CreateExtIndexesSql
PRINT '  - Table ' + @SchemaName + '.Extinguishers created successfully'
PRINT ''
/*============================================================================
  TABLE: InspectionTypes
  Description: Types of inspections (Monthly, Annual, Hydrostatic)
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionTypes'

DECLARE @CreateInspTypeSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionTypes'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionTypes
END

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
PRINT '  - Table ' + @SchemaName + '.InspectionTypes created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistTemplates
  Description: Templates for inspection checklists
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistTemplates'

DECLARE @CreateCheckTempSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistTemplates'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionChecklistTemplates
END

CREATE TABLE [' + @SchemaName + '].InspectionChecklistTemplates (
    ChecklistTemplateId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    TemplateName NVARCHAR(200) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_ChecklistTemplates PRIMARY KEY CLUSTERED (ChecklistTemplateId),
    CONSTRAINT FK_' + @SchemaName + '_CheckTemp_InspType FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId)
)
'
EXEC sp_executesql @CreateCheckTempSql
PRINT '  - Table ' + @SchemaName + '.InspectionChecklistTemplates created successfully'
PRINT ''

/*============================================================================
  TABLE: ChecklistItems
  Description: Individual items in checklist templates
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.ChecklistItems'

DECLARE @CreateCheckItemsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.ChecklistItems'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].ChecklistItems
END

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
    CONSTRAINT FK_' + @SchemaName + '_CheckItem_Template FOREIGN KEY (ChecklistTemplateId) REFERENCES [' + @SchemaName + '].InspectionChecklistTemplates(ChecklistTemplateId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_CheckItems_Template ON [' + @SchemaName + '].ChecklistItems(ChecklistTemplateId, ItemOrder)
'
EXEC sp_executesql @CreateCheckItemsSql
PRINT '  - Table ' + @SchemaName + '.ChecklistItems created successfully'
PRINT ''
/*============================================================================
  TABLE: Inspections
  Description: Inspection records with tamper-proof hashing
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Inspections'

DECLARE @CreateInspSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Inspections'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].Inspections
END

CREATE TABLE [' + @SchemaName + '].Inspections (
    InspectionId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    InspectorUserId UNIQUEIDENTIFIER NOT NULL,
    InspectionStartTime DATETIME2 NOT NULL,
    InspectionEndTime DATETIME2 NULL,
    InspectionStatus NVARCHAR(50) NOT NULL,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL,
    GpsAccuracy DECIMAL(10,2) NULL,
    DeviceFingerprint NVARCHAR(500) NULL,
    OverallResult NVARCHAR(50) NULL,
    InspectorNotes NVARCHAR(MAX) NULL,
    TamperHash NVARCHAR(128) NOT NULL,
    PreviousInspectionHash NVARCHAR(128) NULL,
    IsOfflineInspection BIT NOT NULL DEFAULT 0,
    SyncedDate DATETIME2 NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Inspections PRIMARY KEY CLUSTERED (InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_Insp_Extinguisher FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId),
    CONSTRAINT FK_' + @SchemaName + '_Insp_Type FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId),
    CONSTRAINT CK_' + @SchemaName + '_Insp_Status CHECK (InspectionStatus IN (''InProgress'', ''Completed'', ''Failed'')),
    CONSTRAINT CK_' + @SchemaName + '_Insp_Result CHECK (OverallResult IN (''Pass'', ''Fail'', ''NeedsService'') OR OverallResult IS NULL)
)
'
EXEC sp_executesql @CreateInspSql

DECLARE @CreateInspIndexesSql NVARCHAR(MAX) = '
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Ext_Start ON [' + @SchemaName + '].Inspections(ExtinguisherId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_StartTime ON [' + @SchemaName + '].Inspections(InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Inspector ON [' + @SchemaName + '].Inspections(InspectorUserId) INCLUDE (InspectionStatus, InspectionStartTime)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Status ON [' + @SchemaName + '].Inspections(InspectionStatus) WHERE InspectionStatus = ''InProgress''
'
EXEC sp_executesql @CreateInspIndexesSql
PRINT '  - Table ' + @SchemaName + '.Inspections created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistResponses
  Description: Responses to checklist items during inspection
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistResponses'

DECLARE @CreateRespSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistResponses'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionChecklistResponses
END

CREATE TABLE [' + @SchemaName + '].InspectionChecklistResponses (
    ResponseId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    ChecklistItemId UNIQUEIDENTIFIER NOT NULL,
    ResponseValue NVARCHAR(50) NOT NULL,
    Notes NVARCHAR(MAX) NULL,
    PhotoBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Responses PRIMARY KEY CLUSTERED (ResponseId),
    CONSTRAINT FK_' + @SchemaName + '_Resp_Inspection FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_Resp_CheckItem FOREIGN KEY (ChecklistItemId) REFERENCES [' + @SchemaName + '].ChecklistItems(ChecklistItemId),
    CONSTRAINT CK_' + @SchemaName + '_Resp_Value CHECK (ResponseValue IN (''Pass'', ''Fail'', ''NA''))
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Resp_Inspection ON [' + @SchemaName + '].InspectionChecklistResponses(InspectionId)
'
EXEC sp_executesql @CreateRespSql
PRINT '  - Table ' + @SchemaName + '.InspectionChecklistResponses created successfully'
PRINT ''
/*============================================================================
  TABLE: InspectionPhotos
  Description: Photos captured during inspections
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionPhotos'

DECLARE @CreatePhotosSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionPhotos'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionPhotos
END

CREATE TABLE [' + @SchemaName + '].InspectionPhotos (
    PhotoId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    BlobPath NVARCHAR(500) NOT NULL,
    FileName NVARCHAR(255) NOT NULL,
    FileSize BIGINT NOT NULL,
    ContentType NVARCHAR(100) NOT NULL,
    CaptureDate DATETIME2 NOT NULL,
    ExifData NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Photos PRIMARY KEY CLUSTERED (PhotoId),
    CONSTRAINT FK_' + @SchemaName + '_Photos_Inspection FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Photos_Inspection ON [' + @SchemaName + '].InspectionPhotos(InspectionId)
'
EXEC sp_executesql @CreatePhotosSql
PRINT '  - Table ' + @SchemaName + '.InspectionPhotos created successfully'
PRINT ''

/*============================================================================
  TABLE: MaintenanceRecords
  Description: Maintenance and service history for extinguishers
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.MaintenanceRecords'

DECLARE @CreateMaintSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.MaintenanceRecords'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].MaintenanceRecords
END

CREATE TABLE [' + @SchemaName + '].MaintenanceRecords (
    MaintenanceRecordId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    MaintenanceType NVARCHAR(100) NOT NULL,
    MaintenanceDate DATE NOT NULL,
    TechnicianName NVARCHAR(200) NULL,
    ServiceCompany NVARCHAR(200) NULL,
    Cost DECIMAL(10,2) NULL,
    Notes NVARCHAR(MAX) NULL,
    ReceiptBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Maintenance PRIMARY KEY CLUSTERED (MaintenanceRecordId),
    CONSTRAINT FK_' + @SchemaName + '_Maint_Extinguisher FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Maint_Ext_Date ON [' + @SchemaName + '].MaintenanceRecords(ExtinguisherId, MaintenanceDate DESC)
'
EXEC sp_executesql @CreateMaintSql
PRINT '  - Table ' + @SchemaName + '.MaintenanceRecords created successfully'
PRINT ''

/*============================================================================
  SEED DATA: Insert sample data for the tenant
============================================================================*/
PRINT 'Inserting seed data for tenant...'

-- Insert extinguisher types
DECLARE @InsertExtTypesSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].ExtinguisherTypes (TenantId, TypeCode, TypeName, Description, MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears)
VALUES
    (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''ABC'', ''ABC Dry Chemical'', ''Multi-purpose dry chemical for Class A, B, and C fires'', 1, 1, 12),
    (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''BC'', ''BC Dry Chemical'', ''Dry chemical for Class B and C fires'', 1, 1, 12),
    (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''K'', ''Class K Wet Chemical'', ''Wet chemical for kitchen/cooking fires'', 1, 1, 5),
    (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''CO2'', ''Carbon Dioxide'', ''CO2 for Class B and C fires'', 1, 1, 5),
    (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''H2O'', ''Water'', ''Water-based for Class A fires only'', 1, 1, 5)

PRINT ''  - Inserted extinguisher types''
'
EXEC sp_executesql @InsertExtTypesSql

-- Insert sample location
DECLARE @SampleLocationId UNIQUEIDENTIFIER = NEWID()
DECLARE @InsertLocationSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].Locations (LocationId, TenantId, LocationCode, LocationName, AddressLine1, City, StateProvince, PostalCode, Country, Latitude, Longitude)
VALUES
    (''' + CAST(@SampleLocationId AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''LOC001'', ''Main Office Building'', ''123 Main Street'', ''Seattle'', ''WA'', ''98101'', ''USA'', 47.606209, -122.332069)

PRINT ''  - Inserted sample location''
'
EXEC sp_executesql @InsertLocationSql

-- Insert inspection types
DECLARE @MonthlyInspTypeId UNIQUEIDENTIFIER = NEWID()
DECLARE @AnnualInspTypeId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertInspTypesSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].InspectionTypes (InspectionTypeId, TenantId, TypeName, Description, RequiresServiceTechnician, FrequencyDays)
VALUES
    (''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''Monthly Visual'', ''Monthly visual inspection per NFPA 10'', 0, 30),
    (''' + CAST(@AnnualInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''Annual Service'', ''Annual inspection by certified technician'', 1, 365)

PRINT ''  - Inserted inspection types''
'
EXEC sp_executesql @InsertInspTypesSql

-- Insert checklist template for monthly inspection
DECLARE @MonthlyTemplateId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertTemplateSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].InspectionChecklistTemplates (ChecklistTemplateId, TenantId, InspectionTypeId, TemplateName)
VALUES
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''Standard Monthly Checklist'')

PRINT ''  - Inserted checklist template''
'
EXEC sp_executesql @InsertTemplateSql

-- Insert checklist items
DECLARE @InsertCheckItemsSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].ChecklistItems (ChecklistTemplateId, ItemText, ItemOrder, IsRequired, RequiresPhoto)
VALUES
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Extinguisher is accessible and unobstructed'', 1, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Pressure gauge shows proper pressure (green zone)'', 2, 1, 1),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Safety pin and tamper seal are intact'', 3, 1, 1),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Hose and nozzle are in good condition'', 4, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Operating instructions are legible'', 5, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''No visible damage, corrosion, or leakage'', 6, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Inspection tag is current and legible'', 7, 1, 1)

PRINT ''  - Inserted checklist items''
'
EXEC sp_executesql @InsertCheckItemsSql

PRINT ''  - Seed data insertion completed''
PRINT ''

/*============================================================================
  VERIFICATION
============================================================================*/
PRINT 'Verifying tenant schema creation...'

-- Verify all tables exist
DECLARE @TableCount INT
SELECT @TableCount = COUNT(*) 
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = @SchemaName

PRINT '  - Tables created: ' + CAST(@TableCount AS NVARCHAR(10))

IF @TableCount >= 11
    PRINT '  ✓ All expected tables created successfully'
ELSE
    PRINT '  ⚠ Warning: Expected 11 tables, found ' + CAST(@TableCount AS NVARCHAR(10))

PRINT ''
PRINT '============================================================================'
PRINT 'Tenant schema creation completed successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT 'Next step: Run 003_CreateStoredProcedures.sql'
PRINT '============================================================================'

GO
