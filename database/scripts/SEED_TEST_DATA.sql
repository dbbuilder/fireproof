-- ================================================
-- SEED TEST DATA FOR E2E TESTING
-- ================================================
-- This script creates fire extinguishers and inspections
-- for the test tenant (Demo Company Inc) to support E2E testing
-- with rich data for charts and analytics.
--
-- Tenant: tenant_634F2B52-D32A-46DD-A045-D158E793ADCB (Demo Company Inc)
-- ================================================

USE FireProofDB
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @SchemaName NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'

-- Get existing data IDs
DECLARE @LocationId1 UNIQUEIDENTIFIER
DECLARE @LocationId2 UNIQUEIDENTIFIER
DECLARE @LocationId3 UNIQUEIDENTIFIER
DECLARE @ExtinguisherTypeId1 UNIQUEIDENTIFIER
DECLARE @ExtinguisherTypeId2 UNIQUEIDENTIFIER
DECLARE @ExtinguisherTypeId3 UNIQUEIDENTIFIER
DECLARE @UserId UNIQUEIDENTIFIER

-- Get location IDs
EXEC('
SELECT TOP 1 @LocationId1 = LocationId
FROM [' + @SchemaName + '].Locations
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''
ORDER BY LocationName
')

-- Get extinguisher type IDs
EXEC('
SELECT TOP 1 @ExtinguisherTypeId1 = ExtinguisherTypeId
FROM [' + @SchemaName + '].ExtinguisherTypes
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''
AND TypeCode = ''ABC''
')

EXEC('
SELECT TOP 1 @ExtinguisherTypeId2 = ExtinguisherTypeId
FROM [' + @SchemaName + '].ExtinguisherTypes
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''
AND TypeCode = ''CO2''
')

-- Get a test user ID
SELECT TOP 1 @UserId = UserId
FROM dbo.Users
WHERE Email = 'inspector@democompany.com'

PRINT '========================================='
PRINT 'Starting seed data creation...'
PRINT '========================================='
PRINT 'Tenant ID: ' + CAST(@TenantId AS NVARCHAR(50))
PRINT ''

-- ================================================
-- CREATE ADDITIONAL LOCATIONS
-- ================================================
PRINT 'Creating additional locations...'

-- Location 2: West Wing
IF NOT EXISTS (
    SELECT 1 FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE LocationCode = 'WW-02' AND TenantId = @TenantId
)
BEGIN
    SET @LocationId2 = NEWID()

    EXEC('
    INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    (LocationId, TenantId, LocationName, LocationCode, AddressLine1, City, StateProvince, PostalCode, Country, IsActive)
    VALUES
    (''' + CAST(@LocationId2 AS NVARCHAR(36)) + ''',
     ''' + CAST(@TenantId AS NVARCHAR(36)) + ''',
     ''West Wing - Building B'', ''WW-02'', ''456 Industrial Blvd'', ''Portland'', ''OR'', ''97201'', ''USA'', 1)
    ')

    PRINT '  ✓ Created location: West Wing - Building B'
END
ELSE
BEGIN
    SELECT @LocationId2 = LocationId
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE LocationCode = 'WW-02' AND TenantId = @TenantId

    PRINT '  → Location already exists: West Wing - Building B'
END

-- Location 3: Storage Facility
IF NOT EXISTS (
    SELECT 1 FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE LocationCode = 'SF-03' AND TenantId = @TenantId
)
BEGIN
    SET @LocationId3 = NEWID()

    EXEC('
    INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    (LocationId, TenantId, LocationName, LocationCode, AddressLine1, City, StateProvince, PostalCode, Country, IsActive)
    VALUES
    (''' + CAST(@LocationId3 AS NVARCHAR(36)) + ''',
     ''' + CAST(@TenantId AS NVARCHAR(36)) + ''',
     ''Storage Facility'', ''SF-03'', ''789 Warehouse Way'', ''Eugene'', ''OR'', ''97401'', ''USA'', 1)
    ')

    PRINT '  ✓ Created location: Storage Facility'
END
ELSE
BEGIN
    SELECT @LocationId3 = LocationId
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE LocationCode = 'SF-03' AND TenantId = @TenantId

    PRINT '  → Location already exists: Storage Facility'
END

PRINT ''

-- Get final location IDs
IF @LocationId1 IS NULL
    SELECT TOP 1 @LocationId1 = LocationId FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations WHERE TenantId = @TenantId ORDER BY CreatedDate

IF @ExtinguisherTypeId1 IS NULL
    SELECT TOP 1 @ExtinguisherTypeId1 = ExtinguisherTypeId FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes WHERE TenantId = @TenantId

IF @ExtinguisherTypeId2 IS NULL
    SELECT @ExtinguisherTypeId2 = @ExtinguisherTypeId1

IF @ExtinguisherTypeId3 IS NULL
    SET @ExtinguisherTypeId3 = @ExtinguisherTypeId1

-- ================================================
-- CREATE FIRE EXTINGUISHERS
-- ================================================
PRINT 'Creating fire extinguishers...'

-- Location 1 - Main Office - Extinguishers
DECLARE @ExtId1 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId2 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId3 UNIQUEIDENTIFIER = NEWID()

-- Location 2 - West Wing - Extinguishers
DECLARE @ExtId4 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId5 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId6 UNIQUEIDENTIFIER = NEWID()

-- Location 3 - Storage - Extinguishers
DECLARE @ExtId7 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId8 UNIQUEIDENTIFIER = NEWID()

-- Clear existing test extinguishers (optional - comment out if you want to keep existing data)
-- EXEC('DELETE FROM [' + @SchemaName + '].Extinguishers WHERE AssetTag LIKE ''TEST-%''')

EXEC('
-- Location 1: Main Office
INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
(ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId, AssetTag, SerialNumber, Manufacturer, ManufactureDate, InstallDate, LocationDescription, FloorLevel, IsActive, IsOutOfService, CreatedDate, ModifiedDate)
VALUES
(''' + CAST(@ExtId1 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId1 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId1 AS NVARCHAR(36)) + ''',
 ''TEST-MO-001'', ''SN-2024-001'', ''Amerex'', ''2024-01-15'', ''2024-02-01'', ''Main entrance, left wall'', ''1st Floor'', 1, 0, GETDATE(), GETDATE()),

(''' + CAST(@ExtId2 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId1 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId1 AS NVARCHAR(36)) + ''',
 ''TEST-MO-002'', ''SN-2024-002'', ''Buckeye'', ''2024-01-20'', ''2024-02-01'', ''Kitchen area'', ''1st Floor'', 1, 0, GETDATE(), GETDATE()),

(''' + CAST(@ExtId3 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId1 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId2 AS NVARCHAR(36)) + ''',
 ''TEST-MO-003'', ''SN-2024-003'', ''Ansul'', ''2024-02-01'', ''2024-02-15'', ''Server room'', ''2nd Floor'', 1, 0, GETDATE(), GETDATE()),

-- Location 2: West Wing
(''' + CAST(@ExtId4 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId2 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId1 AS NVARCHAR(36)) + ''',
 ''TEST-WW-001'', ''SN-2024-004'', ''Amerex'', ''2024-01-10'', ''2024-02-01'', ''Main hallway'', ''1st Floor'', 1, 0, GETDATE(), GETDATE()),

(''' + CAST(@ExtId5 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId2 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId1 AS NVARCHAR(36)) + ''',
 ''TEST-WW-002'', ''SN-2024-005'', ''Kidde'', ''2024-01-25'', ''2024-02-01'', ''Break room'', ''1st Floor'', 1, 0, GETDATE(), GETDATE()),

(''' + CAST(@ExtId6 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId2 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId2 AS NVARCHAR(36)) + ''',
 ''TEST-WW-003'', ''SN-2024-006'', ''Buckeye'', ''2024-02-05'', ''2024-02-20'', ''Electrical room'', ''Basement'', 1, 0, GETDATE(), GETDATE()),

-- Location 3: Storage Facility
(''' + CAST(@ExtId7 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId3 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId1 AS NVARCHAR(36)) + ''',
 ''TEST-SF-001'', ''SN-2024-007'', ''Ansul'', ''2024-01-30'', ''2024-02-15'', ''Loading dock'', ''Ground Floor'', 1, 0, GETDATE(), GETDATE()),

(''' + CAST(@ExtId8 AS NVARCHAR(36)) + ''', ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@LocationId3 AS NVARCHAR(36)) + ''', ''' + CAST(@ExtinguisherTypeId2 AS NVARCHAR(36)) + ''',
 ''TEST-SF-002'', ''SN-2024-008'', ''Amerex'', ''2024-02-10'', ''2024-03-01'', ''Storage area A'', ''Ground Floor'', 1, 0, GETDATE(), GETDATE())
')

PRINT '  ✓ Created 8 fire extinguishers across 3 locations'
PRINT ''

-- ================================================
-- CREATE INSPECTIONS
-- ================================================
PRINT 'Creating inspections with varied data...'

-- Helper function to create inspections across multiple dates and types
-- We'll create inspections for the past 60 days with varied pass/fail rates

DECLARE @InspectionDate DATE = DATEADD(DAY, -60, GETDATE())
DECLARE @Counter INT = 0

WHILE @Counter < 40
BEGIN
    DECLARE @RandomExtId UNIQUEIDENTIFIER
    DECLARE @InspType NVARCHAR(20)
    DECLARE @Passed BIT
    DECLARE @RequiresService BIT = 0
    DECLARE @RequiresReplacement BIT = 0

    -- Randomly select extinguisher
    DECLARE @ExtNum INT = (ABS(CHECKSUM(NEWID())) % 8) + 1
    SELECT @RandomExtId = CASE @ExtNum
        WHEN 1 THEN @ExtId1
        WHEN 2 THEN @ExtId2
        WHEN 3 THEN @ExtId3
        WHEN 4 THEN @ExtId4
        WHEN 5 THEN @ExtId5
        WHEN 6 THEN @ExtId6
        WHEN 7 THEN @ExtId7
        ELSE @ExtId8
    END

    -- Randomly select inspection type (weighted toward Monthly)
    DECLARE @TypeNum INT = (ABS(CHECKSUM(NEWID())) % 10) + 1
    SELECT @InspType = CASE
        WHEN @TypeNum <= 6 THEN 'Monthly'
        WHEN @TypeNum <= 8 THEN 'Annual'
        WHEN @TypeNum = 9 THEN '5-Year'
        ELSE '12-Year'
    END

    -- 80% pass rate
    DECLARE @PassNum INT = (ABS(CHECKSUM(NEWID())) % 10) + 1
    SET @Passed = CASE WHEN @PassNum <= 8 THEN 1 ELSE 0 END

    -- If failed, 50% require service, 30% require replacement
    IF @Passed = 0
    BEGIN
        DECLARE @FailNum INT = (ABS(CHECKSUM(NEWID())) % 10) + 1
        SET @RequiresService = CASE WHEN @FailNum <= 5 THEN 1 ELSE 0 END
        SET @RequiresReplacement = CASE WHEN @FailNum > 7 THEN 1 ELSE 0 END
    END

    -- Insert inspection
    DECLARE @InspId UNIQUEIDENTIFIER = NEWID()
    DECLARE @SQL NVARCHAR(MAX) = '
    INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    (InspectionId, TenantId, ExtinguisherId, InspectorUserId, InspectionDate, InspectionType,
     Passed, IsAccessible, HasObstructions, SignageVisible, SealIntact, PinInPlace, NozzleClear,
     HoseConditionGood, GaugeInGreenZone, GaugePressurePsi, PhysicalDamagePresent, InspectionTagAttached,
     RequiresService, RequiresReplacement, Notes, CreatedDate, ModifiedDate)
    VALUES
    (''' + CAST(@InspId AS NVARCHAR(36)) + ''',
     ''' + CAST(@TenantId AS NVARCHAR(36)) + ''',
     ''' + CAST(@RandomExtId AS NVARCHAR(36)) + ''',
     ' + ISNULL('''' + CAST(@UserId AS NVARCHAR(36)) + '''', 'NULL') + ',
     ''' + CAST(@InspectionDate AS NVARCHAR(20)) + ''',
     ''' + @InspType + ''',
     ' + CAST(@Passed AS NVARCHAR(1)) + ',
     1, 0, 1, 1, 1, 1, 1, 1, 150.0, 0, 1,
     ' + CAST(@RequiresService AS NVARCHAR(1)) + ',
     ' + CAST(@RequiresReplacement AS NVARCHAR(1)) + ',
     ''Routine inspection - ' + CASE WHEN @Passed = 1 THEN 'All checks passed' ELSE 'Issues found' END + ''',
     GETDATE(), GETDATE())
    '

    EXEC(@SQL)

    -- Increment date by 1-2 days
    SET @InspectionDate = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 2) + 1, @InspectionDate)
    SET @Counter = @Counter + 1
END

PRINT '  ✓ Created 40 inspections with varied data'
PRINT '    - Multiple inspection types (Monthly, Annual, 5-Year, 12-Year)'
PRINT '    - ~80% pass rate'
PRINT '    - Distributed across past 60 days'
PRINT '    - Multiple locations and extinguishers'
PRINT ''

-- ================================================
-- SUMMARY
-- ================================================
PRINT '========================================='
PRINT 'Seed data creation completed!'
PRINT '========================================='
PRINT ''

-- Display summary statistics
PRINT 'Summary:'
EXEC('
SELECT
    ''Locations'' AS [Type],
    COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''

UNION ALL

SELECT
    ''Extinguishers'' AS [Type],
    COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''

UNION ALL

SELECT
    ''Inspections'' AS [Type],
    COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + '''

UNION ALL

SELECT
    ''Passed Inspections'' AS [Type],
    COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + ''' AND Passed = 1

UNION ALL

SELECT
    ''Failed Inspections'' AS [Type],
    COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = ''' + CAST(@TenantId AS NVARCHAR(36)) + ''' AND Passed = 0
')

PRINT ''
PRINT 'Test data is ready for E2E testing!'
PRINT '========================================='
GO
