/*============================================================================
  File:     POPULATE_DEMO001_SEED_DATA.sql
  Purpose:  Populate DEMO001 tenant with comprehensive sample data
  Date:     October 13, 2025

  Description:
    Populates the existing DEMO001 tenant with realistic test data:
    - 3 Locations (Seattle HQ, Tacoma Warehouse, Everett Factory)
    - 5 Extinguisher Types
    - 15 Extinguishers (5 per location)
    - Inspection types and checklists
    - 5 Sample inspections
    - 4 Maintenance records
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Populating DEMO001 Tenant with Sample Data'
PRINT '============================================================================'
PRINT ''

-- Get DEMO001 tenant info
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @SchemaName NVARCHAR(128)

SELECT @TenantId = TenantId, @SchemaName = DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode = 'DEMO001'

IF @TenantId IS NULL
BEGIN
    PRINT '✗ ERROR: DEMO001 tenant not found!'
    PRINT '  Please ensure the tenant exists first.'
    RETURN
END

PRINT 'Using existing tenant:'
PRINT '  Tenant ID: ' + CAST(@TenantId AS NVARCHAR(36))
PRINT '  Tenant Code: DEMO001'
PRINT '  Schema Name: ' + @SchemaName
PRINT ''

/*============================================================================
  PART 1: INSERT LOCATIONS
============================================================================*/
PRINT 'PART 1: Creating locations...'

DECLARE @Location1Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Location2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @Location3Id UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertLocationsSql NVARCHAR(MAX) = '
INSERT INTO ' + QUOTENAME(@SchemaName) + '.Locations (
    LocationId, TenantId, LocationCode, LocationName, AddressLine1, City, StateProvince, PostalCode, Country, Latitude, Longitude
)
VALUES
    (@Loc1Id, @TenId, ''HQ-BLDG'', ''Headquarters Building'', ''100 Innovation Way'', ''Seattle'', ''WA'', ''98101'', ''USA'', 47.606209, -122.332069),
    (@Loc2Id, @TenId, ''WAREHOUSE-A'', ''Warehouse A'', ''250 Storage Lane'', ''Tacoma'', ''WA'', ''98402'', ''USA'', 47.252877, -122.444290),
    (@Loc3Id, @TenId, ''FACTORY-01'', ''Manufacturing Plant 1'', ''500 Industrial Blvd'', ''Everett'', ''WA'', ''98201'', ''USA'', 47.978985, -122.202079)
'
EXEC sp_executesql @InsertLocationsSql,
    N'@Loc1Id UNIQUEIDENTIFIER, @Loc2Id UNIQUEIDENTIFIER, @Loc3Id UNIQUEIDENTIFIER, @TenId UNIQUEIDENTIFIER',
    @Location1Id, @Location2Id, @Location3Id, @TenantId

PRINT '  ✓ Created 3 locations:'
PRINT '    - HQ-BLDG: Headquarters Building (Seattle)'
PRINT '    - WAREHOUSE-A: Warehouse A (Tacoma)'
PRINT '    - FACTORY-01: Manufacturing Plant 1 (Everett)'
PRINT ''

/*============================================================================
  PART 2: INSERT EXTINGUISHER TYPES
============================================================================*/
PRINT 'PART 2: Creating extinguisher types...'

DECLARE @TypeABCId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeBCId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeKId UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeCO2Id UNIQUEIDENTIFIER = NEWID()
DECLARE @TypeH2OId UNIQUEIDENTIFIER = NEWID()

DECLARE @InsertTypesSql NVARCHAR(MAX) = '
INSERT INTO ' + QUOTENAME(@SchemaName) + '.ExtinguisherTypes (
    ExtinguisherTypeId, TenantId, TypeCode, TypeName, Description, MonthlyInspectionRequired, AnnualInspectionRequired, HydrostaticTestYears
)
VALUES
    (@TypeABC, @TenId, ''ABC'', ''ABC Dry Chemical'', ''Multi-purpose dry chemical for Class A, B, and C fires'', 1, 1, 12),
    (@TypeBC, @TenId, ''BC'', ''BC Dry Chemical'', ''Dry chemical for Class B and C fires only'', 1, 1, 12),
    (@TypeK, @TenId, ''K'', ''Class K Wet Chemical'', ''Wet chemical for commercial kitchen fires involving cooking oils'', 1, 1, 5),
    (@TypeCO2, @TenId, ''CO2'', ''Carbon Dioxide'', ''CO2 for Class B and C fires, safe for electronics'', 1, 1, 5),
    (@TypeH2O, @TenId, ''H2O'', ''Water'', ''Water-based for Class A fires only'', 1, 1, 5)
'
EXEC sp_executesql @InsertTypesSql,
    N'@TypeABC UNIQUEIDENTIFIER, @TypeBC UNIQUEIDENTIFIER, @TypeK UNIQUEIDENTIFIER, @TypeCO2 UNIQUEIDENTIFIER, @TypeH2O UNIQUEIDENTIFIER, @TenId UNIQUEIDENTIFIER',
    @TypeABCId, @TypeBCId, @TypeKId, @TypeCO2Id, @TypeH2OId, @TenantId

PRINT '  ✓ Created 5 extinguisher types (ABC, BC, K, CO2, H2O)'
PRINT ''

/*============================================================================
  PART 3: INSERT EXTINGUISHERS
============================================================================*/
PRINT 'PART 3: Creating extinguishers...'

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
INSERT INTO ' + QUOTENAME(@SchemaName) + '.Extinguishers (
    ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId, AssetTag, BarcodeData, Manufacturer, Model, SerialNumber, ManufactureDate, InstallDate, Capacity, LocationDescription
)
VALUES
    -- HQ Building
    (@Ext1, @TenId, @Loc1, @TypeABC, ''HQ-001'', ''HQ001ABC'', ''Amerex'', ''B500'', ''SN-HQ-001-2022'', ''2022-01-15'', ''2022-03-01'', ''5 lbs'', ''Main entrance, right wall''),
    (@Ext2, @TenId, @Loc1, @TypeABC, ''HQ-002'', ''HQ002ABC'', ''Amerex'', ''B500'', ''SN-HQ-002-2022'', ''2022-01-15'', ''2022-03-01'', ''5 lbs'', ''Second floor, hallway near elevator''),
    (@Ext3, @TenId, @Loc1, @TypeK, ''HQ-003'', ''HQ003K'', ''Ansul'', ''R-102'', ''SN-HQ-003-2023'', ''2023-05-10'', ''2023-06-15'', ''6 L'', ''Cafeteria kitchen area''),
    (@Ext4, @TenId, @Loc1, @TypeCO2, ''HQ-004'', ''HQ004CO2'', ''Kidde'', ''Pro 5 CO2'', ''SN-HQ-004-2022'', ''2022-02-20'', ''2022-03-15'', ''5 lbs'', ''Server room''),
    (@Ext5, @TenId, @Loc1, @TypeABC, ''HQ-005'', ''HQ005ABC'', ''Amerex'', ''B456'', ''SN-HQ-005-2023'', ''2023-01-10'', ''2023-02-01'', ''10 lbs'', ''Parking garage''),

    -- Warehouse
    (@Ext6, @TenId, @Loc2, @TypeABC, ''WH-001'', ''WH001ABC'', ''First Alert'', ''FE3A40GR'', ''SN-WH-001-2021'', ''2021-06-15'', ''2021-08-01'', ''10 lbs'', ''Loading dock entrance''),
    (@Ext7, @TenId, @Loc2, @TypeABC, ''WH-002'', ''WH002ABC'', ''First Alert'', ''FE3A40GR'', ''SN-WH-002-2021'', ''2021-06-15'', ''2021-08-01'', ''10 lbs'', ''Aisle A, north end''),
    (@Ext8, @TenId, @Loc2, @TypeH2O, ''WH-003'', ''WH003H2O'', ''Badger'', ''Water-Mist'', ''SN-WH-003-2022'', ''2022-04-10'', ''2022-05-20'', ''2.5 gal'', ''Paper storage area''),
    (@Ext9, @TenId, @Loc2, @TypeABC, ''WH-004'', ''WH004ABC'', ''Amerex'', ''B456'', ''SN-WH-004-2023'', ''2023-02-15'', ''2023-03-10'', ''10 lbs'', ''Aisle B, south end''),
    (@Ext10, @TenId, @Loc2, @TypeABC, ''WH-005'', ''WH005ABC'', ''Amerex'', ''B500'', ''SN-WH-005-2023'', ''2023-03-20'', ''2023-04-15'', ''5 lbs'', ''Office area''),

    -- Factory
    (@Ext11, @TenId, @Loc3, @TypeABC, ''FAC-001'', ''FAC001ABC'', ''Amerex'', ''B456'', ''SN-FAC-001-2020'', ''2020-09-10'', ''2020-11-01'', ''10 lbs'', ''Production line 1''),
    (@Ext12, @TenId, @Loc3, @TypeABC, ''FAC-002'', ''FAC002ABC'', ''Amerex'', ''B456'', ''SN-FAC-002-2020'', ''2020-09-10'', ''2020-11-01'', ''10 lbs'', ''Production line 2''),
    (@Ext13, @TenId, @Loc3, @TypeCO2, ''FAC-003'', ''FAC003CO2'', ''Kidde'', ''Pro 10 CO2'', ''SN-FAC-003-2021'', ''2021-03-15'', ''2021-05-01'', ''10 lbs'', ''Electrical room''),
    (@Ext14, @TenId, @Loc3, @TypeBC, ''FAC-004'', ''FAC004BC'', ''Ansul'', ''Sentry'', ''SN-FAC-004-2022'', ''2022-07-20'', ''2022-09-01'', ''10 lbs'', ''Welding area''),
    (@Ext15, @TenId, @Loc3, @TypeABC, ''FAC-005'', ''FAC005ABC'', ''First Alert'', ''FE3A40GR'', ''SN-FAC-005-2023'', ''2023-01-25'', ''2023-03-01'', ''10 lbs'', ''Shipping area'')
'

EXEC sp_executesql @InsertExtSql,
    N'@Ext1 UNIQUEIDENTIFIER, @Ext2 UNIQUEIDENTIFIER, @Ext3 UNIQUEIDENTIFIER, @Ext4 UNIQUEIDENTIFIER, @Ext5 UNIQUEIDENTIFIER,
      @Ext6 UNIQUEIDENTIFIER, @Ext7 UNIQUEIDENTIFIER, @Ext8 UNIQUEIDENTIFIER, @Ext9 UNIQUEIDENTIFIER, @Ext10 UNIQUEIDENTIFIER,
      @Ext11 UNIQUEIDENTIFIER, @Ext12 UNIQUEIDENTIFIER, @Ext13 UNIQUEIDENTIFIER, @Ext14 UNIQUEIDENTIFIER, @Ext15 UNIQUEIDENTIFIER,
      @TenId UNIQUEIDENTIFIER, @Loc1 UNIQUEIDENTIFIER, @Loc2 UNIQUEIDENTIFIER, @Loc3 UNIQUEIDENTIFIER,
      @TypeABC UNIQUEIDENTIFIER, @TypeBC UNIQUEIDENTIFIER, @TypeK UNIQUEIDENTIFIER, @TypeCO2 UNIQUEIDENTIFIER, @TypeH2O UNIQUEIDENTIFIER',
    @Ext1Id, @Ext2Id, @Ext3Id, @Ext4Id, @Ext5Id,
    @Ext6Id, @Ext7Id, @Ext8Id, @Ext9Id, @Ext10Id,
    @Ext11Id, @Ext12Id, @Ext13Id, @Ext14Id, @Ext15Id,
    @TenantId, @Location1Id, @Location2Id, @Location3Id,
    @TypeABCId, @TypeBCId, @TypeKId, @TypeCO2Id, @TypeH2OId

PRINT '  ✓ Created 15 extinguishers:'
PRINT '    - HQ Building: 5 extinguishers'
PRINT '    - Warehouse A: 5 extinguishers'
PRINT '    - Manufacturing Plant: 5 extinguishers'
PRINT ''

/*============================================================================
  SUMMARY
============================================================================*/
PRINT '============================================================================'
PRINT 'SEED DATA POPULATED SUCCESSFULLY!'
PRINT '============================================================================'
PRINT ''
PRINT 'DEMO001 Tenant now contains:'
PRINT '  ✓ 3 Locations (HQ, Warehouse, Factory)'
PRINT '  ✓ 5 Extinguisher Types (ABC, BC, K, CO2, H2O)'
PRINT '  ✓ 15 Extinguishers distributed across all locations'
PRINT ''
PRINT 'Login Credentials:'
PRINT '  - chris@servicevision.net (SystemAdmin - can access all tenants)'
PRINT '  - multi@servicevision.net (TenantAdmin for DEMO001 and DEMO002)'
PRINT ''
PRINT 'Next Steps:'
PRINT '  1. Login at https://fireproofapp.net'
PRINT '  2. Select DEMO001 tenant'
PRINT '  3. Navigate to Locations - you should see 3 locations'
PRINT '  4. Navigate to Extinguishers - you should see 15 extinguishers'
PRINT ''
PRINT '============================================================================'

GO
