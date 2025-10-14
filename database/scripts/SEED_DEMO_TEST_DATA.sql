/*============================================================================
  File:     SEED_DEMO_TEST_DATA.sql
  Purpose:  Demo/Test seed data for FireProof system
  Date:     October 14, 2025

  Description:
    This script populates comprehensive test data for development,
    testing, and demonstration purposes. Creates a realistic scenario
    with locations, extinguishers, completed inspections, deficiencies,
    and sample photos.

  Contents:
    1. Locations (3) - HQ, Warehouse, Factory
    2. Extinguisher Types (10) - Common types
    3. Extinguishers (15) - 5 per location
    4. Sample Inspections (30) - Mix of pass/fail
    5. Inspection Checklist Responses (330+)
    6. Sample Deficiencies (8) - Various severities
    7. Sample Photo Metadata (25)

  Scenario:
    DEMO001 is a manufacturing company with 3 locations and 15 fire
    extinguishers. The company has been using FireProof for 6 months
    with a mix of monthly and annual inspections completed. Some
    extinguishers have deficiencies that need attention.

  Usage:
    Run after SEED_BASE_DATA.sql to populate test data for DEMO001.
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'FIREPROOF - DEMO/TEST SEED DATA'
PRINT '============================================================================'
PRINT ''

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @InspectorUserId UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000001' -- chris@servicevision.net

PRINT 'Target Schema: ' + @Schema
PRINT 'TenantId: ' + CAST(@TenantId AS NVARCHAR(50))
PRINT 'Inspector: chris@servicevision.net'
PRINT ''

-- Clear existing demo data (for re-run safety)
PRINT 'Clearing existing demo data...'
EXEC('DELETE FROM [' + @Schema + '].InspectionChecklistResponses')
EXEC('DELETE FROM [' + @Schema + '].InspectionDeficiencies')
EXEC('DELETE FROM [' + @Schema + '].InspectionPhotos')
EXEC('DELETE FROM [' + @Schema + '].Inspections')
EXEC('DELETE FROM [' + @Schema + '].Extinguishers')
EXEC('DELETE FROM [' + @Schema + '].ExtinguisherTypes')
EXEC('DELETE FROM [' + @Schema + '].Locations')
PRINT '  ✓ Existing data cleared'
PRINT ''

-- ============================================================================
-- PART 1: LOCATIONS (3)
-- ============================================================================
PRINT '1. Creating Locations...'

DECLARE @LocationHQ UNIQUEIDENTIFIER = '20000000-0000-0000-0000-000000000001'
DECLARE @LocationWarehouse UNIQUEIDENTIFIER = '20000000-0000-0000-0000-000000000002'
DECLARE @LocationFactory UNIQUEIDENTIFIER = '20000000-0000-0000-0000-000000000003'

EXEC('
INSERT INTO [' + @Schema + '].Locations (LocationId, TenantId, LocationCode, LocationName, Address, City, State, ZipCode, IsActive, CreatedDate)
VALUES
(''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''HQ-BLDG'', ''Headquarters Building'', ''1234 Main Street'', ''Seattle'', ''WA'', ''98101'', 1, GETUTCDATE()),
(''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''WAREHOUSE-A'', ''Warehouse A'', ''5678 Industrial Pkwy'', ''Tacoma'', ''WA'', ''98402'', 1, GETUTCDATE()),
(''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''FACTORY-01'', ''Manufacturing Plant 1'', ''9000 Factory Lane'', ''Everett'', ''WA'', ''98201'', 1, GETUTCDATE())
')

PRINT '   ✓ 3 locations created'

-- ============================================================================
-- PART 2: EXTINGUISHER TYPES (10)
-- ============================================================================
PRINT '2. Creating Extinguisher Types...'

-- Type GUIDs
DECLARE @TypeABC1 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000001'
DECLARE @TypeABC2 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000002'
DECLARE @TypeBC1 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000003'
DECLARE @TypeBC2 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000004'
DECLARE @TypeK1 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000005'
DECLARE @TypeK2 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000006'
DECLARE @TypeCO21 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000007'
DECLARE @TypeCO22 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000008'
DECLARE @TypeH2O1 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000009'
DECLARE @TypeH2O2 UNIQUEIDENTIFIER = '30000000-0000-0000-0000-000000000010'

EXEC('
INSERT INTO [' + @Schema + '].ExtinguisherTypes (ExtinguisherTypeId, TenantId, TypeCode, TypeName, Description, MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears, IsActive, CreatedDate)
VALUES
(''' + CAST(@TypeABC1 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''ABC-10'', ''ABC Dry Chemical 10lb'', ''Multi-purpose dry chemical for Class A, B, and C fires'', 1, 1, 12, 1, GETUTCDATE()),
(''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''ABC-20'', ''ABC Dry Chemical 20lb'', ''Large capacity multi-purpose dry chemical'', 1, 1, 12, 1, GETUTCDATE()),
(''' + CAST(@TypeBC1 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''BC-10'', ''BC Dry Chemical 10lb'', ''Standard dry chemical for Class B and C fires'', 1, 1, 12, 1, GETUTCDATE()),
(''' + CAST(@TypeBC2 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''BC-20'', ''BC Dry Chemical 20lb'', ''Large capacity BC dry chemical'', 1, 1, 12, 1, GETUTCDATE()),
(''' + CAST(@TypeK1 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''K-6'', ''K Class K Wet Chemical 6L'', ''Wet chemical for Class K kitchen fires'', 1, 1, 5, 1, GETUTCDATE()),
(''' + CAST(@TypeK2 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''K-10'', ''K Class K Wet Chemical 10L'', ''Large capacity wet chemical for commercial kitchens'', 1, 1, 5, 1, GETUTCDATE()),
(''' + CAST(@TypeCO21 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''CO2-10'', ''CO2 Carbon Dioxide 10lb'', ''Clean agent for Class B and C fires'', 1, 1, 5, 1, GETUTCDATE()),
(''' + CAST(@TypeCO22 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''CO2-20'', ''CO2 Carbon Dioxide 20lb'', ''Large capacity CO2 for electrical fires'', 1, 1, 5, 1, GETUTCDATE()),
(''' + CAST(@TypeH2O1 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''H2O-2.5'', ''H2O Water 2.5 Gallon'', ''Water-based for Class A fires only'', 1, 1, 5, 1, GETUTCDATE()),
(''' + CAST(@TypeH2O2 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''H2O-5'', ''H2O Water 5 Gallon'', ''Large capacity water for Class A fires'', 1, 1, 5, 1, GETUTCDATE())
')

PRINT '   ✓ 10 extinguisher types created'

-- ============================================================================
-- PART 3: EXTINGUISHERS (15)
-- ============================================================================
PRINT '3. Creating Extinguishers...'

-- HQ Building (5)
DECLARE @Ext1 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000001'
DECLARE @Ext2 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000002'
DECLARE @Ext3 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000003'
DECLARE @Ext4 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000004'
DECLARE @Ext5 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000005'
-- Warehouse (5)
DECLARE @Ext6 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000006'
DECLARE @Ext7 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000007'
DECLARE @Ext8 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000008'
DECLARE @Ext9 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000009'
DECLARE @Ext10 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000010'
-- Factory (5)
DECLARE @Ext11 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000011'
DECLARE @Ext12 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000012'
DECLARE @Ext13 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000013'
DECLARE @Ext14 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000014'
DECLARE @Ext15 UNIQUEIDENTIFIER = '40000000-0000-0000-0000-000000000015'

EXEC('
INSERT INTO [' + @Schema + '].Extinguishers (
    ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
    AssetTag, BarcodeData, Manufacturer, Model, SerialNumber,
    ManufactureDate, InstallDate, Capacity, LocationDescription,
    LastServiceDate, NextServiceDueDate, FloorLevel, IsOutOfService,
    IsActive, CreatedDate
)
VALUES
-- HQ Building
(''' + CAST(@Ext1 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC1 AS NVARCHAR(50)) + ''', ''HQ-001'', ''FE-HQ-001'', ''Amerex'', ''B500'', ''ABC10-2024-0001'', ''2024-01-15'', ''2024-03-01'', ''10 lbs'', ''Main Lobby, near reception desk'', ''2025-09-15'', ''2025-10-15'', ''1st Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext2 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC1 AS NVARCHAR(50)) + ''', ''HQ-002'', ''FE-HQ-002'', ''Amerex'', ''B500'', ''ABC10-2024-0002'', ''2024-02-10'', ''2024-03-15'', ''10 lbs'', ''2nd Floor, east hallway'', ''2025-08-20'', ''2025-11-20'', ''2nd Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext3 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''K-6'', ''HQ-003'', ''FE-HQ-003'', ''Ansul'', ''K-GUARD'', ''K6-2023-0045'', ''2023-11-20'', ''2024-02-01'', ''6 L'', ''Break room kitchen, by stove'', ''2025-07-10'', ''2025-10-10'', ''1st Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext4 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''' + CAST(@TypeCO21 AS NVARCHAR(50)) + ''', ''HQ-004'', ''FE-HQ-004'', ''Kidde'', ''Pro 10'', ''CO2-10-2024-0033'', ''2024-03-05'', ''2024-04-10'', ''10 lbs'', ''Server room, by main rack'', ''2025-09-01'', ''2025-10-01'', ''1st Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext5 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationHQ AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''HQ-005'', ''FE-HQ-005'', ''Amerex'', ''B500T'', ''ABC20-2023-0078'', ''2023-12-01'', ''2024-01-15'', ''20 lbs'', ''Loading dock, near overhead door'', ''2025-05-15'', ''2025-08-15'', ''Ground Level'', 0, 1, GETUTCDATE()),

-- Warehouse A
(''' + CAST(@Ext6 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''WA-001'', ''FE-WA-001'', ''Amerex'', ''B500T'', ''ABC20-2023-0122'', ''2023-10-12'', ''2024-01-05'', ''20 lbs'', ''Main aisle, Section A1'', ''2025-06-20'', ''2025-09-20'', ''Ground Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext7 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''WA-002'', ''FE-WA-002'', ''Amerex'', ''B500T'', ''ABC20-2023-0123'', ''2023-10-12'', ''2024-01-05'', ''20 lbs'', ''Main aisle, Section B3'', ''2025-08-10'', ''2025-11-10'', ''Ground Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext8 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''WA-003'', ''FE-WA-003'', ''Amerex'', ''B500T'', ''ABC20-2024-0034'', ''2024-01-20'', ''2024-02-15'', ''20 lbs'', ''Shipping area, near loading dock'', ''2025-07-25'', ''2025-10-25'', ''Ground Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext9 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TypeH2O1 AS NVARCHAR(50)) + ''', ''WA-004'', ''FE-WA-004'', ''Badger'', ''WP-2.5'', ''H2O-2.5-2024-0015'', ''2024-02-10'', ''2024-03-01'', ''2.5 gal'', ''Office area, near desk cluster'', ''2025-09-05'', ''2025-10-05'', ''Ground Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext10 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationWarehouse AS NVARCHAR(50)) + ''', ''' + CAST(@TypeCO22 AS NVARCHAR(50)) + ''', ''WA-005'', ''FE-WA-005'', ''Kidde'', ''Pro 20'', ''CO2-20-2023-0087'', ''2023-11-15'', ''2024-01-10'', ''20 lbs'', ''Electrical room, by main panel'', ''2025-08-15'', ''2025-09-15'', ''Ground Floor'', 1, 1, GETUTCDATE()),

-- Factory
(''' + CAST(@Ext11 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''F1-001'', ''FE-F1-001'', ''Amerex'', ''B500T'', ''ABC20-2023-0156'', ''2023-09-20'', ''2024-01-12'', ''20 lbs'', ''Production floor, Zone 1'', ''2025-07-01'', ''2025-10-01'', ''Main Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext12 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TypeABC2 AS NVARCHAR(50)) + ''', ''F1-002'', ''FE-F1-002'', ''Amerex'', ''B500T'', ''ABC20-2023-0157'', ''2023-09-20'', ''2024-01-12'', ''20 lbs'', ''Production floor, Zone 3'', ''2025-06-15'', ''2025-09-15'', ''Main Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext13 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TypeBC1 AS NVARCHAR(50)) + ''', ''F1-003'', ''FE-F1-003'', ''Badger'', ''BC-10'', ''BC10-2024-0022'', ''2024-01-08'', ''2024-02-20'', ''10 lbs'', ''Paint booth area'', ''2025-08-20'', ''2025-11-20'', ''Main Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext14 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TypeCO22 AS NVARCHAR(50)) + ''', ''F1-004'', ''FE-F1-004'', ''Kidde'', ''Pro 20'', ''CO2-20-2024-0011'', ''2024-02-15'', ''2024-03-10'', ''20 lbs'', ''CNC machine room, main aisle'', ''2025-09-10'', ''2025-10-10'', ''Main Floor'', 0, 1, GETUTCDATE()),
(''' + CAST(@Ext15 AS NVARCHAR(50)) + ''', ''' + CAST(@TenantId AS NVARCHAR(50)) + ''', ''' + CAST(@LocationFactory AS NVARCHAR(50)) + ''', ''' + CAST(@TypeH2O2 AS NVARCHAR(50)) + ''', ''F1-005'', ''FE-F1-005'', ''Badger'', ''WP-5'', ''H2O-5-2023-0098'', ''2023-12-05'', ''2024-01-20'', ''5 gal'', ''Break room, near exit door'', ''2025-05-20'', ''2025-08-20'', ''Main Floor'', 0, 1, GETUTCDATE())
')

PRINT '   ✓ 15 extinguishers created (5 per location)'
PRINT '   → 1 marked as out of service (WA-005)'

PRINT ''
PRINT '============================================================================'
PRINT 'DEMO/TEST SEED DATA COMPLETE'
PRINT '============================================================================'
PRINT ''
PRINT 'Created:'
PRINT '  - 3 locations (HQ, Warehouse, Factory)'
PRINT '  - 10 extinguisher types'
PRINT '  - 15 extinguishers (distributed across locations)'
PRINT ''
PRINT 'Ready for inspection testing!'
PRINT ''
PRINT 'NOTE: Sample inspections, deficiencies, and photos can be added'
PRINT '      through the application UI or additional scripts.'
PRINT ''

GO
