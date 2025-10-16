-- ================================================
-- SEED TEST DATA FOR E2E TESTING (SIMPLIFIED)
-- ================================================
USE FireProofDB
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'

PRINT 'Starting seed data creation...'
PRINT 'Tenant ID: 634F2B52-D32A-46DD-A045-D158E793ADCB'
PRINT ''

-- Get existing IDs
DECLARE @LocationId1 UNIQUEIDENTIFIER
DECLARE @LocationId2 UNIQUEIDENTIFIER = NEWID()
DECLARE @LocationId3 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtinguisherTypeId UNIQUEIDENTIFIER
DECLARE @UserId UNIQUEIDENTIFIER

-- Get first location
SELECT TOP 1 @LocationId1 = LocationId
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
WHERE TenantId = @TenantId

-- Get extinguisher type
SELECT TOP 1 @ExtinguisherTypeId = ExtinguisherTypeId
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes
WHERE TenantId = @TenantId

-- Get inspector user
SELECT TOP 1 @UserId = UserId
FROM dbo.Users

-- Create additional locations
IF NOT EXISTS (SELECT 1 FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations WHERE LocationCode = 'WW-02')
BEGIN
    INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    (LocationId, TenantId, LocationName, LocationCode, AddressLine1, City, StateProvince, PostalCode, Country, IsActive)
    VALUES
    (@LocationId2, @TenantId, 'West Wing - Building B', 'WW-02', '456 Industrial Blvd', 'Portland', 'OR', '97201', 'USA', 1)

    PRINT 'Created location: West Wing - Building B'
END
ELSE
BEGIN
    SELECT @LocationId2 = LocationId FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations WHERE LocationCode = 'WW-02'
    PRINT 'Location already exists: West Wing - Building B'
END

IF NOT EXISTS (SELECT 1 FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations WHERE LocationCode = 'SF-03')
BEGIN
    INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    (LocationId, TenantId, LocationName, LocationCode, AddressLine1, City, StateProvince, PostalCode, Country, IsActive)
    VALUES
    (@LocationId3, @TenantId, 'Storage Facility', 'SF-03', '789 Warehouse Way', 'Eugene', 'OR', '97401', 'USA', 1)

    PRINT 'Created location: Storage Facility'
END
ELSE
BEGIN
    SELECT @LocationId3 = LocationId FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations WHERE LocationCode = 'SF-03'
    PRINT 'Location already exists: Storage Facility'
END

-- Create extinguishers
DECLARE @ExtId1 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId2 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId3 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId4 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId5 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId6 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId7 UNIQUEIDENTIFIER = NEWID()
DECLARE @ExtId8 UNIQUEIDENTIFIER = NEWID()

-- Clear existing test extinguishers
DELETE FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers WHERE AssetTag LIKE 'TEST-%'
PRINT 'Cleared existing test extinguishers'

INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
(ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId, AssetTag, SerialNumber, Manufacturer, ManufactureDate, InstallDate, LocationDescription, FloorLevel, IsActive, IsOutOfService, CreatedDate, ModifiedDate)
VALUES
-- Location 1: Main Office
(@ExtId1, @TenantId, @LocationId1, @ExtinguisherTypeId, 'TEST-MO-001', 'SN-2024-001', 'Amerex', '2024-01-15', '2024-02-01', 'Main entrance, left wall', '1st Floor', 1, 0, GETDATE(), GETDATE()),
(@ExtId2, @TenantId, @LocationId1, @ExtinguisherTypeId, 'TEST-MO-002', 'SN-2024-002', 'Buckeye', '2024-01-20', '2024-02-01', 'Kitchen area', '1st Floor', 1, 0, GETDATE(), GETDATE()),
(@ExtId3, @TenantId, @LocationId1, @ExtinguisherTypeId, 'TEST-MO-003', 'SN-2024-003', 'Ansul', '2024-02-01', '2024-02-15', 'Server room', '2nd Floor', 1, 0, GETDATE(), GETDATE()),
-- Location 2: West Wing
(@ExtId4, @TenantId, @LocationId2, @ExtinguisherTypeId, 'TEST-WW-001', 'SN-2024-004', 'Amerex', '2024-01-10', '2024-02-01', 'Main hallway', '1st Floor', 1, 0, GETDATE(), GETDATE()),
(@ExtId5, @TenantId, @LocationId2, @ExtinguisherTypeId, 'TEST-WW-002', 'SN-2024-005', 'Kidde', '2024-01-25', '2024-02-01', 'Break room', '1st Floor', 1, 0, GETDATE(), GETDATE()),
(@ExtId6, @TenantId, @LocationId2, @ExtinguisherTypeId, 'TEST-WW-003', 'SN-2024-006', 'Buckeye', '2024-02-05', '2024-02-20', 'Electrical room', 'Basement', 1, 0, GETDATE(), GETDATE()),
-- Location 3: Storage Facility
(@ExtId7, @TenantId, @LocationId3, @ExtinguisherTypeId, 'TEST-SF-001', 'SN-2024-007', 'Ansul', '2024-01-30', '2024-02-15', 'Loading dock', 'Ground Floor', 1, 0, GETDATE(), GETDATE()),
(@ExtId8, @TenantId, @LocationId3, @ExtinguisherTypeId, 'TEST-SF-002', 'SN-2024-008', 'Amerex', '2024-02-10', '2024-03-01', 'Storage area A', 'Ground Floor', 1, 0, GETDATE(), GETDATE())

PRINT 'Created 8 fire extinguishers'

-- Create inspections with varied data
DECLARE @InspDate1 DATE = DATEADD(DAY, -60, GETDATE())
DECLARE @InspDate2 DATE = DATEADD(DAY, -55, GETDATE())
DECLARE @InspDate3 DATE = DATEADD(DAY, -50, GETDATE())
DECLARE @InspDate4 DATE = DATEADD(DAY, -45, GETDATE())
DECLARE @InspDate5 DATE = DATEADD(DAY, -40, GETDATE())
DECLARE @InspDate6 DATE = DATEADD(DAY, -35, GETDATE())
DECLARE @InspDate7 DATE = DATEADD(DAY, -30, GETDATE())
DECLARE @InspDate8 DATE = DATEADD(DAY, -25, GETDATE())
DECLARE @InspDate9 DATE = DATEADD(DAY, -20, GETDATE())
DECLARE @InspDate10 DATE = DATEADD(DAY, -15, GETDATE())
DECLARE @InspDate11 DATE = DATEADD(DAY, -10, GETDATE())
DECLARE @InspDate12 DATE = DATEADD(DAY, -5, GETDATE())
DECLARE @InspDate13 DATE = DATEADD(DAY, -2, GETDATE())

INSERT INTO [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
(InspectionId, TenantId, ExtinguisherId, InspectorUserId, InspectionDate, InspectionType,
 Passed, IsAccessible, HasObstructions, SignageVisible, SealIntact, PinInPlace, NozzleClear,
 HoseConditionGood, GaugeInGreenZone, GaugePressurePsi, PhysicalDamagePresent, InspectionTagAttached,
 RequiresService, RequiresReplacement, Notes, CreatedDate, ModifiedDate)
VALUES
-- Monthly inspections (Passed)
(NEWID(), @TenantId, @ExtId1, @UserId, @InspDate1, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 150.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId2, @UserId, @InspDate2, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 145.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId3, @UserId, @InspDate3, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 152.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId4, @UserId, @InspDate4, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 148.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId5, @UserId, @InspDate5, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 151.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId6, @UserId, @InspDate6, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 147.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId7, @UserId, @InspDate7, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 149.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId8, @UserId, @InspDate8, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 150.5, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
-- More monthly inspections (Passed)
(NEWID(), @TenantId, @ExtId1, @UserId, @InspDate9, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 148.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId2, @UserId, @InspDate10, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 149.5, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId3, @UserId, @InspDate11, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 151.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId4, @UserId, @InspDate12, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 150.0, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId5, @UserId, @InspDate13, 'Monthly', 1, 1, 0, 1, 1, 1, 1, 1, 1, 148.5, 0, 1, 0, 0, 'Routine monthly inspection - All checks passed', GETDATE(), GETDATE()),

-- Monthly inspections (Failed - requires service)
(NEWID(), @TenantId, @ExtId6, @UserId, @InspDate9, 'Monthly', 0, 1, 0, 1, 1, 1, 1, 0, 1, 148.0, 0, 1, 1, 0, 'Hose showing wear - requires service', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId7, @UserId, @InspDate10, 'Monthly', 0, 1, 1, 1, 1, 1, 1, 1, 1, 150.0, 0, 1, 1, 0, 'Obstruction in front - requires clearing', GETDATE(), GETDATE()),

-- Monthly inspections (Failed - requires replacement)
(NEWID(), @TenantId, @ExtId8, @UserId, @InspDate11, 'Monthly', 0, 1, 0, 1, 0, 1, 1, 1, 0, 120.0, 1, 1, 0, 1, 'Seal broken, gauge in red zone, physical damage - requires replacement', GETDATE(), GETDATE()),

-- Annual inspections (Passed)
(NEWID(), @TenantId, @ExtId1, @UserId, @InspDate2, 'Annual', 1, 1, 0, 1, 1, 1, 1, 1, 1, 150.0, 0, 1, 0, 0, 'Annual inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId2, @UserId, @InspDate4, 'Annual', 1, 1, 0, 1, 1, 1, 1, 1, 1, 148.0, 0, 1, 0, 0, 'Annual inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId3, @UserId, @InspDate6, 'Annual', 1, 1, 0, 1, 1, 1, 1, 1, 1, 151.5, 0, 1, 0, 0, 'Annual inspection - All checks passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId4, @UserId, @InspDate8, 'Annual', 1, 1, 0, 1, 1, 1, 1, 1, 1, 149.0, 0, 1, 0, 0, 'Annual inspection - All checks passed', GETDATE(), GETDATE()),

-- Annual inspections (Failed)
(NEWID(), @TenantId, @ExtId5, @UserId, @InspDate10, 'Annual', 0, 1, 0, 1, 1, 1, 0, 1, 1, 150.0, 0, 1, 1, 0, 'Nozzle partially blocked - requires cleaning', GETDATE(), GETDATE()),

-- 5-Year inspections
(NEWID(), @TenantId, @ExtId6, @UserId, @InspDate3, '5-Year', 1, 1, 0, 1, 1, 1, 1, 1, 1, 148.0, 0, 1, 0, 0, '5-year internal examination completed - passed', GETDATE(), GETDATE()),
(NEWID(), @TenantId, @ExtId7, @UserId, @InspDate7, '5-Year', 1, 1, 0, 1, 1, 1, 1, 1, 1, 150.0, 0, 1, 0, 0, '5-year internal examination completed - passed', GETDATE(), GETDATE()),

-- 12-Year hydrostatic test
(NEWID(), @TenantId, @ExtId8, @UserId, @InspDate5, '12-Year', 1, 1, 0, 1, 1, 1, 1, 1, 1, 152.0, 0, 1, 0, 0, '12-year hydrostatic test completed - passed', GETDATE(), GETDATE())

PRINT 'Created 24 inspections with varied data'
PRINT '  - Multiple inspection types (Monthly, Annual, 5-Year, 12-Year)'
PRINT '  - ~83% pass rate (20 passed, 4 failed)'
PRINT '  - Distributed across past 60 days'
PRINT '  - Multiple locations and extinguishers'
PRINT ''
PRINT 'Seed data creation completed successfully!'
GO

-- Display summary
SELECT 'Summary Statistics:' AS Info
SELECT 'Locations' AS [Type], COUNT(*) AS [Count]
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB'
UNION ALL
SELECT 'Extinguishers', COUNT(*)
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB'
UNION ALL
SELECT 'Inspections', COUNT(*)
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB'
UNION ALL
SELECT 'Passed Inspections', COUNT(*)
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB' AND Passed = 1
UNION ALL
SELECT 'Failed Inspections', COUNT(*)
FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
WHERE TenantId = '634F2B52-D32A-46DD-A045-D158E793ADCB' AND Passed = 0

PRINT 'Test data is ready for E2E testing!'
GO
