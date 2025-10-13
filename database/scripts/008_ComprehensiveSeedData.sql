/*============================================================================
  File:     comprehensive_seed_data.sql
  Summary:  Comprehensive seed data for FireProof testing
  Date:     October 13, 2025

  Description:
    Creates a test tenant with complete sample data including:
    - Test tenant (Test Company)
    - Multiple users with different roles
    - Multiple locations (3 buildings)
    - Multiple extinguishers per location (15 total)
    - Sample inspections
    - Sample maintenance records

  Usage:
    Run this script after schema creation (001 and 002 scripts)

============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'FireProof Comprehensive Seed Data Script'
PRINT 'Creating test tenant with full sample data...'
PRINT '============================================================================'
PRINT ''

/*============================================================================
  PART 1: CREATE TEST TENANT
============================================================================*/
PRINT 'PART 1: Creating test tenant...'

DECLARE @TestTenantId UNIQUEIDENTIFIER = NEWID()
DECLARE @TenantCode NVARCHAR(50) = 'TEST001'
DECLARE @CompanyName NVARCHAR(200) = 'Test Company Inc'
DECLARE @SchemaName NVARCHAR(128) = 'tenant_' + REPLACE(CAST(@TestTenantId AS NVARCHAR(36)), '-', '')

-- Delete existing test tenant if it exists
IF EXISTS (SELECT 1 FROM dbo.Tenants WHERE TenantCode = @TenantCode)
BEGIN
    DECLARE @OldTenantId UNIQUEIDENTIFIER
    DECLARE @OldSchemaName NVARCHAR(128)

    SELECT @OldTenantId = TenantId, @OldSchemaName = DatabaseSchema
    FROM dbo.Tenants
    WHERE TenantCode = @TenantCode

    PRINT '  - Found existing test tenant, cleaning up...'
    PRINT '    Old Tenant ID: ' + CAST(@OldTenantId AS NVARCHAR(36))
    PRINT '    Old Schema: ' + @OldSchemaName

    -- Drop the old tenant schema and all its objects
    IF EXISTS (SELECT * FROM sys.schemas WHERE name = @OldSchemaName)
    BEGIN
        -- Step 1: Drop all foreign key constraints in the schema
        DECLARE @DropFKsSql NVARCHAR(MAX) = ''
        SELECT @DropFKsSql = @DropFKsSql +
            'ALTER TABLE [' + @OldSchemaName + '].[' + OBJECT_NAME(fk.parent_object_id) + '] DROP CONSTRAINT [' + fk.name + ']; '
        FROM sys.foreign_keys fk
        INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @OldSchemaName

        IF LEN(@DropFKsSql) > 0
        BEGIN
            EXEC sp_executesql @DropFKsSql
            PRINT '    - Dropped foreign key constraints'
        END

        -- Step 2: Drop all tables in the schema
        DECLARE @DropTablesSql NVARCHAR(MAX) = ''
        SELECT @DropTablesSql = @DropTablesSql + 'DROP TABLE [' + @OldSchemaName + '].[' + t.name + ']; '
        FROM sys.tables t
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @OldSchemaName

        IF LEN(@DropTablesSql) > 0
        BEGIN
            EXEC sp_executesql @DropTablesSql
            PRINT '    - Dropped tenant tables'
        END

        -- Step 3: Drop the schema
        DECLARE @DropSchemaSql NVARCHAR(MAX) = 'DROP SCHEMA [' + @OldSchemaName + ']'
        EXEC sp_executesql @DropSchemaSql
        PRINT '    - Dropped tenant schema'
    END

    -- Delete test users (they're test-only accounts)
    DELETE FROM dbo.Users
    WHERE Email IN (
        'admin@testcompany.local',
        'manager@testcompany.local',
        'inspector1@testcompany.local',
        'inspector2@testcompany.local',
        'inspector3@testcompany.local',
        'viewer@testcompany.local'
    )
    PRINT '    - Deleted test users'

    -- Delete user tenant roles for this tenant
    DELETE FROM dbo.UserTenantRoles WHERE TenantId = @OldTenantId
    PRINT '    - Deleted user tenant roles'

    -- Delete tenant record
    DELETE FROM dbo.Tenants WHERE TenantId = @OldTenantId
    PRINT '    - Deleted tenant record'

    PRINT '  ✓ Cleanup completed successfully'
    PRINT ''
END

-- Insert new test tenant
INSERT INTO dbo.Tenants (
    TenantId,
    TenantCode,
    CompanyName,
    SubscriptionTier,
    IsActive,
    MaxLocations,
    MaxUsers,
    MaxExtinguishers,
    DatabaseSchema,
    CreatedDate,
    ModifiedDate
)
VALUES (
    @TestTenantId,
    @TenantCode,
    @CompanyName,
    'Premium',
    1,
    100,
    50,
    1000,
    @SchemaName,
    GETUTCDATE(),
    GETUTCDATE()
)

PRINT '  ✓ Test tenant created:'
PRINT '    Tenant ID: ' + CAST(@TestTenantId AS NVARCHAR(36))
PRINT '    Tenant Code: ' + @TenantCode
PRINT '    Company Name: ' + @CompanyName
PRINT '    Schema: ' + @SchemaName
PRINT ''

/*============================================================================
  PART 2: CREATE USERS WITH DIFFERENT ROLES
============================================================================*/
PRINT 'PART 2: Creating users with different roles...'

-- TenantAdmin User
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID()
INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES (@AdminUserId, 'admin@testcompany.local', 'Alice', 'Admin', 1, GETUTCDATE(), GETUTCDATE())

INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
VALUES (@AdminUserId, @TestTenantId, 'TenantAdmin', 1, GETUTCDATE())

PRINT '  ✓ Created TenantAdmin: Alice Admin (admin@testcompany.local)'

-- LocationManager User
DECLARE @ManagerUserId UNIQUEIDENTIFIER = NEWID()
INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES (@ManagerUserId, 'manager@testcompany.local', 'Bob', 'Manager', 1, GETUTCDATE(), GETUTCDATE())

INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
VALUES (@ManagerUserId, @TestTenantId, 'LocationManager', 1, GETUTCDATE())

PRINT '  ✓ Created LocationManager: Bob Manager (manager@testcompany.local)'

-- Inspector Users (3)
DECLARE @Inspector1UserId UNIQUEIDENTIFIER = NEWID()
DECLARE @Inspector2UserId UNIQUEIDENTIFIER = NEWID()
DECLARE @Inspector3UserId UNIQUEIDENTIFIER = NEWID()

INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES
    (@Inspector1UserId, 'inspector1@testcompany.local', 'Charlie', 'Inspector', 1, GETUTCDATE(), GETUTCDATE()),
    (@Inspector2UserId, 'inspector2@testcompany.local', 'Diana', 'Checker', 1, GETUTCDATE(), GETUTCDATE()),
    (@Inspector3UserId, 'inspector3@testcompany.local', 'Edward', 'Validator', 1, GETUTCDATE(), GETUTCDATE())

INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
VALUES
    (@Inspector1UserId, @TestTenantId, 'Inspector', 1, GETUTCDATE()),
    (@Inspector2UserId, @TestTenantId, 'Inspector', 1, GETUTCDATE()),
    (@Inspector3UserId, @TestTenantId, 'Inspector', 1, GETUTCDATE())

PRINT '  ✓ Created Inspector: Charlie Inspector (inspector1@testcompany.local)'
PRINT '  ✓ Created Inspector: Diana Checker (inspector2@testcompany.local)'
PRINT '  ✓ Created Inspector: Edward Validator (inspector3@testcompany.local)'

-- Viewer User
DECLARE @ViewerUserId UNIQUEIDENTIFIER = NEWID()
INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES (@ViewerUserId, 'viewer@testcompany.local', 'Frank', 'Viewer', 1, GETUTCDATE(), GETUTCDATE())

INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive, CreatedDate)
VALUES (@ViewerUserId, @TestTenantId, 'Viewer', 1, GETUTCDATE())

PRINT '  ✓ Created Viewer: Frank Viewer (viewer@testcompany.local)'
PRINT ''

/*============================================================================
  PART 3: CREATE TENANT SCHEMA
============================================================================*/
PRINT 'PART 3: Creating tenant schema...'

-- Create schema
DECLARE @CreateSchemaSql NVARCHAR(MAX) = 'CREATE SCHEMA [' + @SchemaName + ']'
EXEC sp_executesql @CreateSchemaSql

PRINT '  ✓ Schema created: ' + @SchemaName
PRINT ''

/*============================================================================
  PART 4: CREATE TENANT TABLES
============================================================================*/
PRINT 'PART 4: Creating tenant tables...'

-- Create Locations table
DECLARE @CreateLocationsSql NVARCHAR(MAX) = '
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
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Locations_Barcode ON [' + @SchemaName + '].Locations(LocationBarcodeData) WHERE LocationBarcodeData IS NOT NULL
'
EXEC sp_executesql @CreateLocationsSql
PRINT '  ✓ Created Locations table'

-- Create ExtinguisherTypes table
DECLARE @CreateExtTypeSql NVARCHAR(MAX) = '
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
'
EXEC sp_executesql @CreateExtTypeSql
PRINT '  ✓ Created ExtinguisherTypes table'

-- Create Extinguishers table
DECLARE @CreateExtSql NVARCHAR(MAX) = '
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
EXEC sp_executesql @CreateExtSql
PRINT '  ✓ Created Extinguishers table'

-- Create InspectionTypes table
DECLARE @CreateInspTypeSql NVARCHAR(MAX) = '
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
PRINT '  ✓ Created InspectionTypes table'

-- Create InspectionChecklistTemplates table
DECLARE @CreateCheckTempSql NVARCHAR(MAX) = '
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
PRINT '  ✓ Created InspectionChecklistTemplates table'

-- Create ChecklistItems table
DECLARE @CreateCheckItemsSql NVARCHAR(MAX) = '
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
PRINT '  ✓ Created ChecklistItems table'

-- Create Inspections table
DECLARE @CreateInspSql NVARCHAR(MAX) = '
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

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Ext_Start ON [' + @SchemaName + '].Inspections(ExtinguisherId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_StartTime ON [' + @SchemaName + '].Inspections(InspectionStartTime DESC)
'
EXEC sp_executesql @CreateInspSql
PRINT '  ✓ Created Inspections table'

-- Create MaintenanceRecords table
DECLARE @CreateMaintSql NVARCHAR(MAX) = '
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
PRINT '  ✓ Created MaintenanceRecords table'
PRINT ''

/*============================================================================
  PART 5: INSERT LOCATIONS
============================================================================*/
PRINT 'PART 5: Creating locations...'

DECLARE @Location1Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Location2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Location3Id UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertLocationsSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].Locations (
    LocationId, TenantId, LocationCode, LocationName, AddressLine1, City, StateProvince, PostalCode, Country, Latitude, Longitude
)
VALUES
    (''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''HQ-BLDG'', ''Headquarters Building'', ''100 Innovation Way'', ''Seattle'', ''WA'', ''98101'', ''USA'', 47.606209, -122.332069),
    (''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''WAREHOUSE-A'', ''Warehouse A'', ''250 Storage Lane'', ''Tacoma'', ''WA'', ''98402'', ''USA'', 47.252877, -122.444290),
    (''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''FACTORY-01'', ''Manufacturing Plant 1'', ''500 Industrial Blvd'', ''Everett'', ''WA'', ''98201'', ''USA'', 47.978985, -122.202079)
'
EXEC sp_executesql @InsertLocationsSql

PRINT '  ✓ Created 3 locations:'
PRINT '    - HQ-BLDG: Headquarters Building (Seattle)'
PRINT '    - WAREHOUSE-A: Warehouse A (Tacoma)'
PRINT '    - FACTORY-01: Manufacturing Plant 1 (Everett)'
PRINT ''

/*============================================================================
  PART 6: INSERT EXTINGUISHER TYPES
============================================================================*/
PRINT 'PART 6: Creating extinguisher types...'

DECLARE @TypeABCId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeBCId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeKId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeCO2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeH2OId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertTypesSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].ExtinguisherTypes (
    ExtinguisherTypeId, TenantId, TypeCode, TypeName, Description, MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears
)
VALUES
    (''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''ABC'', ''ABC Dry Chemical'', ''Multi-purpose dry chemical for Class A, B, and C fires'', 1, 1, 12),
    (''' + CAST(@TypeBCId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''BC'', ''BC Dry Chemical'', ''Dry chemical for Class B and C fires only'', 1, 1, 12),
    (''' + CAST(@TypeKId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''K'', ''Class K Wet Chemical'', ''Wet chemical for commercial kitchen fires involving cooking oils'', 1, 1, 5),
    (''' + CAST(@TypeCO2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''CO2'', ''Carbon Dioxide'', ''CO2 for Class B and C fires, safe for electronics'', 1, 1, 5),
    (''' + CAST(@TypeH2OId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''H2O'', ''Water'', ''Water-based for Class A fires only'', 1, 1, 5)
'
EXEC sp_executesql @InsertTypesSql

PRINT '  ✓ Created 5 extinguisher types (ABC, BC, K, CO2, H2O)'
PRINT ''

/*============================================================================
  PART 7: INSERT EXTINGUISHERS
============================================================================*/
PRINT 'PART 7: Creating extinguishers...'

-- HQ Building: 5 extinguishers
DECLARE @Ext1Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext3Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext4Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext5Id UNIQUEIDENTIFIER = NEWID()

-- Warehouse: 5 extinguishers
DECLARE @Ext6Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext7Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext8Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext9Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext10Id UNIQUEIDENTIFIER = NEWID()

-- Factory: 5 extinguishers
DECLARE @Ext11Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext12Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext13Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext14Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Ext15Id UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertExtSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].Extinguishers (
    ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId, AssetTag, BarcodeData, Manufacturer, Model, SerialNumber, ManufactureDate, InstallDate, Capacity, LocationDescription
)
VALUES
    -- HQ Building
    (''' + CAST(@Ext1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''HQ-001'', ''HQ001ABC'', ''Amerex'', ''B500'', ''SN-HQ-001-2022'', ''2022-01-15'', ''2022-03-01'', ''5 lbs'', ''Main entrance, right wall''),
    (''' + CAST(@Ext2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''HQ-002'', ''HQ002ABC'', ''Amerex'', ''B500'', ''SN-HQ-002-2022'', ''2022-01-15'', ''2022-03-01'', ''5 lbs'', ''Second floor, hallway near elevator''),
    (''' + CAST(@Ext3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeKId AS NVARCHAR(36)) + ''', ''HQ-003'', ''HQ003K'', ''Ansul'', ''R-102'', ''SN-HQ-003-2023'', ''2023-05-10'', ''2023-06-15'', ''6 L'', ''Cafeteria kitchen area''),
    (''' + CAST(@Ext4Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeCO2Id AS NVARCHAR(36)) + ''', ''HQ-004'', ''HQ004CO2'', ''Kidde'', ''Pro 5 CO2'', ''SN-HQ-004-2022'', ''2022-02-20'', ''2022-03-15'', ''5 lbs'', ''Server room''),
    (''' + CAST(@Ext5Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''HQ-005'', ''HQ005ABC'', ''Amerex'', ''B456'', ''SN-HQ-005-2023'', ''2023-01-10'', ''2023-02-01'', ''10 lbs'', ''Parking garage''),

    -- Warehouse
    (''' + CAST(@Ext6Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''WH-001'', ''WH001ABC'', ''First Alert'', ''FE3A40GR'', ''SN-WH-001-2021'', ''2021-06-15'', ''2021-08-01'', ''10 lbs'', ''Loading dock entrance''),
    (''' + CAST(@Ext7Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''WH-002'', ''WH002ABC'', ''First Alert'', ''FE3A40GR'', ''SN-WH-002-2021'', ''2021-06-15'', ''2021-08-01'', ''10 lbs'', ''Aisle A, north end''),
    (''' + CAST(@Ext8Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeH2OId AS NVARCHAR(36)) + ''', ''WH-003'', ''WH003H2O'', ''Badger'', ''Water-Mist'', ''SN-WH-003-2022'', ''2022-04-10'', ''2022-05-20'', ''2.5 gal'', ''Paper storage area''),
    (''' + CAST(@Ext9Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''WH-004'', ''WH004ABC'', ''Amerex'', ''B456'', ''SN-WH-004-2023'', ''2023-02-15'', ''2023-03-10'', ''10 lbs'', ''Aisle B, south end''),
    (''' + CAST(@Ext10Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''WH-005'', ''WH005ABC'', ''Amerex'', ''B500'', ''SN-WH-005-2023'', ''2023-03-20'', ''2023-04-15'', ''5 lbs'', ''Office area''),

    -- Factory
    (''' + CAST(@Ext11Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''FAC-001'', ''FAC001ABC'', ''Amerex'', ''B456'', ''SN-FAC-001-2020'', ''2020-09-10'', ''2020-11-01'', ''10 lbs'', ''Production line 1''),
    (''' + CAST(@Ext12Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''FAC-002'', ''FAC002ABC'', ''Amerex'', ''B456'', ''SN-FAC-002-2020'', ''2020-09-10'', ''2020-11-01'', ''10 lbs'', ''Production line 2''),
    (''' + CAST(@Ext13Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeCO2Id AS NVARCHAR(36)) + ''', ''FAC-003'', ''FAC003CO2'', ''Kidde'', ''Pro 10 CO2'', ''SN-FAC-003-2021'', ''2021-03-15'', ''2021-05-01'', ''10 lbs'', ''Electrical room''),
    (''' + CAST(@Ext14Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeBCId AS NVARCHAR(36)) + ''', ''FAC-004'', ''FAC004BC'', ''Ansul'', ''Sentry'', ''SN-FAC-004-2022'', ''2022-07-20'', ''2022-09-01'', ''10 lbs'', ''Welding area''),
    (''' + CAST(@Ext15Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Location3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TypeABCId AS NVARCHAR(36)) + ''', ''FAC-005'', ''FAC005ABC'', ''First Alert'', ''FE3A40GR'', ''SN-FAC-005-2023'', ''2023-01-25'', ''2023-03-01'', ''10 lbs'', ''Shipping area'')
'
EXEC sp_executesql @InsertExtSql

PRINT '  ✓ Created 15 extinguishers:'
PRINT '    - HQ Building: 5 extinguishers'
PRINT '    - Warehouse A: 5 extinguishers'
PRINT '    - Manufacturing Plant: 5 extinguishers'
PRINT ''

/*============================================================================
  PART 8: INSERT INSPECTION TYPES AND CHECKLISTS
============================================================================*/
PRINT 'PART 8: Creating inspection types and checklists...'

DECLARE @MonthlyInspTypeId UNIQUEIDENTIFIER = NEWID()
DECLARE @AnnualInspTypeId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertInspTypesSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].InspectionTypes (
    InspectionTypeId, TenantId, TypeName, Description, RequiresServiceTechnician, FrequencyDays
)
VALUES
    (''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''Monthly Visual'', ''Monthly visual inspection per NFPA 10 requirements'', 0, 30),
    (''' + CAST(@AnnualInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''Annual Service'', ''Annual maintenance by certified fire safety technician'', 1, 365)
'
EXEC sp_executesql @InsertInspTypesSql

PRINT '  ✓ Created inspection types (Monthly Visual, Annual Service)'

-- Create checklist template
DECLARE @MonthlyTemplateId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertTemplateSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].InspectionChecklistTemplates (
    ChecklistTemplateId, TenantId, InspectionTypeId, TemplateName
)
VALUES
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''Standard Monthly Inspection Checklist'')
'
EXEC sp_executesql @InsertTemplateSql

-- Create checklist items
DECLARE @InsertCheckItemsSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].ChecklistItems (
    ChecklistTemplateId, ItemText, ItemOrder, IsRequired, RequiresPhoto
)
VALUES
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Extinguisher is in its designated location'', 1, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Access to extinguisher is unobstructed and clearly visible'', 2, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Pressure gauge shows proper pressure (needle in green zone)'', 3, 1, 1),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Safety pin and tamper seal are intact and undamaged'', 4, 1, 1),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Hose and nozzle are in good condition with no damage'', 5, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Operating instructions on nameplate are legible'', 6, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''No visible damage, dents, rust, chemical deposits, or leakage'', 7, 1, 0),
    (''' + CAST(@MonthlyTemplateId AS NVARCHAR(36)) + ''', ''Service tag is current, filled out, and legible'', 8, 1, 1)
'
EXEC sp_executesql @InsertCheckItemsSql

PRINT '  ✓ Created inspection checklist with 8 items'
PRINT ''

/*============================================================================
  PART 9: INSERT SAMPLE INSPECTIONS
============================================================================*/
PRINT 'PART 9: Creating sample inspections...'

-- Create 10 sample inspections (recent and historical)
DECLARE @Insp1Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Insp2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Insp3Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Insp4Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Insp5Id UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertInspSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].Inspections (
    InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
    InspectionStartTime, InspectionEndTime, InspectionStatus, Latitude, Longitude,
    GpsAccuracy, OverallResult, InspectorNotes, TamperHash
)
VALUES
    -- Recent inspections (last 30 days)
    (''' + CAST(@Insp1Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Ext1Id AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@Inspector1UserId AS NVARCHAR(36)) + ''',
     DATEADD(DAY, -5, GETUTCDATE()), DATEADD(DAY, -5, DATEADD(MINUTE, 8, GETUTCDATE())), ''Completed'', 47.606209, -122.332069,
     5.2, ''Pass'', ''All checks passed. Equipment in good condition.'', CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', ''INSP1''), 2)),

    (''' + CAST(@Insp2Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Ext2Id AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@Inspector1UserId AS NVARCHAR(36)) + ''',
     DATEADD(DAY, -5, DATEADD(MINUTE, 15, GETUTCDATE())), DATEADD(DAY, -5, DATEADD(MINUTE, 23, GETUTCDATE())), ''Completed'', 47.606209, -122.332069,
     4.8, ''Pass'', ''Minor dust on gauge, cleaned. Otherwise good.'', CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', ''INSP2''), 2)),

    (''' + CAST(@Insp3Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Ext6Id AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@Inspector2UserId AS NVARCHAR(36)) + ''',
     DATEADD(DAY, -3, GETUTCDATE()), DATEADD(DAY, -3, DATEADD(MINUTE, 10, GETUTCDATE())), ''Completed'', 47.252877, -122.444290,
     6.1, ''Pass'', ''Routine inspection completed successfully.'', CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', ''INSP3''), 2)),

    (''' + CAST(@Insp4Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Ext11Id AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@Inspector3UserId AS NVARCHAR(36)) + ''',
     DATEADD(DAY, -2, GETUTCDATE()), DATEADD(DAY, -2, DATEADD(MINUTE, 12, GETUTCDATE())), ''Completed'', 47.978985, -122.202079,
     5.7, ''Fail'', ''Pressure gauge in red zone. Needs recharge immediately.'', CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', ''INSP4''), 2)),

    (''' + CAST(@Insp5Id AS NVARCHAR(36)) + ''', ''' + CAST(@TestTenantId AS NVARCHAR(36)) + ''', ''' + CAST(@Ext12Id AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', ''' + CAST(@Inspector3UserId AS NVARCHAR(36)) + ''',
     DATEADD(DAY, -2, DATEADD(MINUTE, 20, GETUTCDATE())), DATEADD(DAY, -2, DATEADD(MINUTE, 28, GETUTCDATE())), ''Completed'', 47.978985, -122.202079,
     5.9, ''NeedsService'', ''Service tag expired. Annual service required.'', CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', ''INSP5''), 2))
'
EXEC sp_executesql @InsertInspSql

PRINT '  ✓ Created 5 sample inspections:'
PRINT '    - 3 Pass'
PRINT '    - 1 Fail (needs recharge)'
PRINT '    - 1 Needs Service (annual service due)'
PRINT ''

/*============================================================================
  PART 10: INSERT MAINTENANCE RECORDS
============================================================================*/
PRINT 'PART 10: Creating maintenance records...'

DECLARE @InsertMaintSql NVARCHAR(MAX) = '
INSERT INTO [' + @SchemaName + '].MaintenanceRecords (
    ExtinguisherId, MaintenanceType, MaintenanceDate, TechnicianName, ServiceCompany, Cost, Notes
)
VALUES
    (''' + CAST(@Ext1Id AS NVARCHAR(36)) + ''', ''Annual Service'', ''2024-03-15'', ''John Smith'', ''ABC Fire Safety Inc'', 75.00, ''Full annual maintenance completed. All components checked and verified.''),
    (''' + CAST(@Ext6Id AS NVARCHAR(36)) + ''', ''Recharge'', ''2024-08-20'', ''Mike Johnson'', ''ABC Fire Safety Inc'', 45.00, ''Refilled and pressure tested after accidental discharge.''),
    (''' + CAST(@Ext11Id AS NVARCHAR(36)) + ''', ''Hydrostatic Test'', ''2023-11-10'', ''Sarah Williams'', ''FireTech Services LLC'', 125.00, ''5-year hydrostatic test completed. Passed all tests.''),
    (''' + CAST(@Ext3Id AS NVARCHAR(36)) + ''', ''Annual Service'', ''2024-06-20'', ''John Smith'', ''ABC Fire Safety Inc'', 95.00, ''Kitchen suppression system annual service.'')
'
EXEC sp_executesql @InsertMaintSql

PRINT '  ✓ Created 4 maintenance records (annual services, recharge, hydrostatic test)'
PRINT ''

/*============================================================================
  VERIFICATION AND SUMMARY
============================================================================*/
PRINT '============================================================================'
PRINT 'SEED DATA CREATION COMPLETED SUCCESSFULLY!'
PRINT '============================================================================'
PRINT ''
PRINT 'Summary:'
PRINT '--------'
PRINT '✓ Tenant: Test Company Inc (TEST001)'
PRINT '  - TenantId: ' + CAST(@TestTenantId AS NVARCHAR(36))
PRINT '  - Schema: ' + @SchemaName
PRINT ''
PRINT '✓ Users: 7 total'
PRINT '  - 1 TenantAdmin'
PRINT '  - 1 LocationManager'
PRINT '  - 3 Inspectors'
PRINT '  - 1 Viewer'
PRINT ''
PRINT '✓ Locations: 3'
PRINT '  - Headquarters Building (Seattle)'
PRINT '  - Warehouse A (Tacoma)'
PRINT '  - Manufacturing Plant 1 (Everett)'
PRINT ''
PRINT '✓ Extinguisher Types: 5 (ABC, BC, K, CO2, H2O)'
PRINT ''
PRINT '✓ Extinguishers: 15 total'
PRINT '  - HQ: 5'
PRINT '  - Warehouse: 5'
PRINT '  - Factory: 5'
PRINT ''
PRINT '✓ Inspection Types: 2 (Monthly Visual, Annual Service)'
PRINT '✓ Checklist Template: 1 with 8 items'
PRINT '✓ Sample Inspections: 5 (3 Pass, 1 Fail, 1 Needs Service)'
PRINT '✓ Maintenance Records: 4'
PRINT ''
PRINT 'Testing Credentials:'
PRINT '-------------------'
PRINT 'TenantAdmin:     admin@testcompany.local'
PRINT 'LocationManager: manager@testcompany.local'
PRINT 'Inspector 1:     inspector1@testcompany.local'
PRINT 'Inspector 2:     inspector2@testcompany.local'
PRINT 'Inspector 3:     inspector3@testcompany.local'
PRINT 'Viewer:          viewer@testcompany.local'
PRINT ''
PRINT 'API Testing with SystemAdmin:'
PRINT '-----------------------------'
PRINT 'Use query parameter: ?tenantId=' + CAST(@TestTenantId AS NVARCHAR(36))
PRINT 'Example: GET /api/locations?tenantId=' + CAST(@TestTenantId AS NVARCHAR(36))
PRINT ''
PRINT '============================================================================'
PRINT 'Ready for testing!'
PRINT '============================================================================'

GO
