-- Direct SQL seeding to bypass API issues
USE FireProofDB;
GO

PRINT 'Clearing existing test data...';
DELETE FROM dbo.Inspections WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';
DELETE FROM dbo.Extinguishers WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';
DELETE FROM dbo.Locations WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';
DELETE FROM dbo.InspectionTypes WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';
PRINT '✓ Test data cleared';

-- Seed Locations for test tenant
PRINT 'Seeding Locations...';
INSERT INTO dbo.Locations (LocationId, TenantId, LocationCode, LocationName, AddressLine1, City, StateProvince, PostalCode, Country, IsActive, CreatedDate)
VALUES
  (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', 'MO-01', 'Main Office', '123 Main St', 'Seattle', 'WA', '98101', 'USA', 1, GETUTCDATE()),
  (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', 'WW-02', 'West Wing - Building B', '456 West Ave', 'Seattle', 'WA', '98102', 'USA', 1, GETUTCDATE()),
  (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', 'SF-03', 'Storage Facility', '789 Storage Rd', 'Tacoma', 'WA', '98401', 'USA', 1, GETUTCDATE());
PRINT '✓ 3 Locations seeded';

-- Seed InspectionTypes for test tenant
PRINT 'Seeding InspectionTypes...';
INSERT INTO dbo.InspectionTypes (InspectionTypeId, TenantId, TypeName, Description, RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate)
VALUES
  (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', 'Monthly Test', 'Monthly visual inspection', 0, 30, 1, GETUTCDATE()),
  (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', 'Annual Test', 'Annual comprehensive inspection', 1, 365, 1, GETUTCDATE());
PRINT '✓ 2 InspectionTypes seeded';

-- Get ExtinguisherType IDs (shared data)
DECLARE @ABCTypeId UNIQUEIDENTIFIER = (SELECT TOP 1 ExtinguisherTypeId FROM dbo.ExtinguisherTypes WHERE TypeCode = 'ABC');
DECLARE @CO2TypeId UNIQUEIDENTIFIER = (SELECT TOP 1 ExtinguisherTypeId FROM dbo.ExtinguisherTypes WHERE TypeCode = 'CO2');

-- Get Location IDs
DECLARE @MainOfficeId UNIQUEIDENTIFIER = (SELECT LocationId FROM dbo.Locations WHERE LocationCode = 'MO-01' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');
DECLARE @WestWingId UNIQUEIDENTIFIER = (SELECT LocationId FROM dbo.Locations WHERE LocationCode = 'WW-02' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');

-- Seed Extinguishers
PRINT 'Seeding Extinguishers...';
IF @ABCTypeId IS NOT NULL AND @CO2TypeId IS NOT NULL AND @MainOfficeId IS NOT NULL AND @WestWingId IS NOT NULL
BEGIN
    INSERT INTO dbo.Extinguishers (ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId, AssetTag, Manufacturer, Model, SerialNumber, ManufactureDate, IsActive, CreatedDate)
    VALUES
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @MainOfficeId, @ABCTypeId, 'TEST-MO-001', 'Ansul', 'A-10', 'ABC12345', '2023-01-15', 1, GETUTCDATE()),
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @MainOfficeId, @CO2TypeId, 'TEST-MO-002', 'Kidde', 'ProLine 5 CO2', 'CO2-67890', '2023-02-20', 1, GETUTCDATE()),
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @WestWingId, @ABCTypeId, 'TEST-WW-001', 'Amerex', 'B456', 'AMX-11111', '2023-03-10', 1, GETUTCDATE());
    PRINT '✓ 3 Extinguishers seeded';
END
ELSE
BEGIN
    PRINT '⚠️  Missing ExtinguisherType or Location IDs - skipping extinguishers';
    PRINT '  ABCTypeId: ' + ISNULL(CAST(@ABCTypeId AS NVARCHAR(50)), 'NULL');
    PRINT '  CO2TypeId: ' + ISNULL(CAST(@CO2TypeId AS NVARCHAR(50)), 'NULL');
    PRINT '  MainOfficeId: ' + ISNULL(CAST(@MainOfficeId AS NVARCHAR(50)), 'NULL');
    PRINT '  WestWingId: ' + ISNULL(CAST(@WestWingId AS NVARCHAR(50)), 'NULL');
END

-- Get InspectionType IDs
DECLARE @MonthlyTypeId UNIQUEIDENTIFIER = (SELECT InspectionTypeId FROM dbo.InspectionTypes WHERE TypeName = 'Monthly Test' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');
DECLARE @AnnualTypeId UNIQUEIDENTIFIER = (SELECT InspectionTypeId FROM dbo.InspectionTypes WHERE TypeName = 'Annual Test' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');

-- Get Extinguisher IDs
DECLARE @Ext1Id UNIQUEIDENTIFIER = (SELECT ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-MO-001' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');
DECLARE @Ext2Id UNIQUEIDENTIFIER = (SELECT ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-MO-002' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');
DECLARE @Ext3Id UNIQUEIDENTIFIER = (SELECT ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-WW-001' AND TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb');

-- Get User ID (using chris@servicevision.net)
DECLARE @InspectorUserId UNIQUEIDENTIFIER = (SELECT TOP 1 UserId FROM dbo.Users WHERE Email = 'chris@servicevision.net');

-- Seed Inspections
PRINT 'Seeding Inspections...';
IF @MonthlyTypeId IS NOT NULL AND @Ext1Id IS NOT NULL AND @InspectorUserId IS NOT NULL
BEGIN
    INSERT INTO dbo.Inspections (
        InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
        InspectionDate, IsPressureGaugeNormal, IsAccessible, IsSignageVisible,
        IsPinSealed, Notes, InspectionStatus, CreatedDate
    )
    VALUES
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @Ext1Id, @MonthlyTypeId, @InspectorUserId,
       DATEADD(DAY, -15, GETUTCDATE()), 1, 1, 1, 1, 'Routine monthly inspection - all checks passed', 'Completed', DATEADD(DAY, -15, GETUTCDATE())),
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @Ext2Id, @MonthlyTypeId, @InspectorUserId,
       DATEADD(DAY, -10, GETUTCDATE()), 1, 1, 1, 1, 'Monthly inspection - unit in good condition', 'Completed', DATEADD(DAY, -10, GETUTCDATE())),
      (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @Ext3Id, @MonthlyTypeId, @InspectorUserId,
       DATEADD(DAY, -5, GETUTCDATE()), 1, 1, 1, 1, 'Monthly inspection - no issues found', 'Completed', DATEADD(DAY, -5, GETUTCDATE()));

    -- Add one annual inspection
    IF @AnnualTypeId IS NOT NULL
    BEGIN
        INSERT INTO dbo.Inspections (
            InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, IsPressureGaugeNormal, IsAccessible, IsSignageVisible,
            IsPinSealed, Notes, InspectionStatus, CreatedDate
        )
        VALUES
          (NEWID(), '634f2b52-d32a-46dd-a045-d158e793adcb', @Ext1Id, @AnnualTypeId, @InspectorUserId,
           DATEADD(DAY, -30, GETUTCDATE()), 1, 1, 1, 1, 'Annual comprehensive inspection - passed all checks', 'Completed', DATEADD(DAY, -30, GETUTCDATE()));
    END

    PRINT '✓ Inspections seeded';
END
ELSE
BEGIN
    PRINT '⚠️  Missing required IDs for Inspections - skipping';
    PRINT '  MonthlyTypeId: ' + ISNULL(CAST(@MonthlyTypeId AS NVARCHAR(50)), 'NULL');
    PRINT '  Ext1Id: ' + ISNULL(CAST(@Ext1Id AS NVARCHAR(50)), 'NULL');
    PRINT '  InspectorUserId: ' + ISNULL(CAST(@InspectorUserId AS NVARCHAR(50)), 'NULL');
END

-- Summary
SELECT
  (SELECT COUNT(*) FROM dbo.ExtinguisherTypes WHERE IsActive = 1) as TotalExtinguisherTypes,
  (SELECT COUNT(*) FROM dbo.InspectionTypes WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb') as TestTenantInspectionTypes,
  (SELECT COUNT(*) FROM dbo.Locations WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb') as TestTenantLocations,
  (SELECT COUNT(*) FROM dbo.Extinguishers WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb') as TestTenantExtinguishers,
  (SELECT COUNT(*) FROM dbo.Inspections WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb') as TestTenantInspections;

PRINT '✓ Data seeding complete!';
