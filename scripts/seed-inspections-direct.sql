-- Direct SQL seeding for Inspections
USE FireProofDB;
GO

PRINT 'Seeding Inspections...';

-- Get required IDs
DECLARE @TenantId UNIQUEIDENTIFIER = '634f2b52-d32a-46dd-a045-d158e793adcb';
DECLARE @MonthlyTypeId UNIQUEIDENTIFIER = (SELECT InspectionTypeId FROM dbo.InspectionTypes WHERE TypeName = 'Monthly Test' AND TenantId = @TenantId);
DECLARE @AnnualTypeId UNIQUEIDENTIFIER = (SELECT InspectionTypeId FROM dbo.InspectionTypes WHERE TypeName = 'Annual Test' AND TenantId = @TenantId);
DECLARE @InspectorUserId UNIQUEIDENTIFIER = (SELECT TOP 1 UserId FROM dbo.Users WHERE Email = 'chris@servicevision.net');

-- Get Extinguisher IDs
DECLARE @Ext1Id UNIQUEIDENTIFIER = (SELECT TOP 1 ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-MO-001' AND TenantId = @TenantId);
DECLARE @Ext2Id UNIQUEIDENTIFIER = (SELECT TOP 1 ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-MO-002' AND TenantId = @TenantId);
DECLARE @Ext3Id UNIQUEIDENTIFIER = (SELECT TOP 1 ExtinguisherId FROM dbo.Extinguishers WHERE AssetTag = 'TEST-WW-001' AND TenantId = @TenantId);

-- Debug: Show what we found
PRINT 'MonthlyTypeId: ' + ISNULL(CAST(@MonthlyTypeId AS NVARCHAR(50)), 'NULL');
PRINT 'AnnualTypeId: ' + ISNULL(CAST(@AnnualTypeId AS NVARCHAR(50)), 'NULL');
PRINT 'InspectorUserId: ' + ISNULL(CAST(@InspectorUserId AS NVARCHAR(50)), 'NULL');
PRINT 'Ext1Id: ' + ISNULL(CAST(@Ext1Id AS NVARCHAR(50)), 'NULL');
PRINT 'Ext2Id: ' + ISNULL(CAST(@Ext2Id AS NVARCHAR(50)), 'NULL');
PRINT 'Ext3Id: ' + ISNULL(CAST(@Ext3Id AS NVARCHAR(50)), 'NULL');

-- Clear existing test inspections
DELETE FROM dbo.Inspections WHERE TenantId = @TenantId;
PRINT 'Cleared existing inspections';

-- Seed Inspections if we have all required IDs
IF @MonthlyTypeId IS NOT NULL AND @Ext1Id IS NOT NULL AND @InspectorUserId IS NOT NULL
BEGIN
    INSERT INTO dbo.Inspections (
        InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
        InspectionDate, Passed, IsAccessible, SignageVisible, SealIntact, PinInPlace,
        GaugeInGreenZone, Notes, CreatedDate
    )
    VALUES
      -- Monthly inspection for Ext1 (15 days ago)
      (NEWID(), @TenantId, @Ext1Id, @MonthlyTypeId, @InspectorUserId,
       DATEADD(DAY, -15, GETUTCDATE()), 1, 1, 1, 1, 1, 1,
       'Routine monthly inspection - all checks passed',
       DATEADD(DAY, -15, GETUTCDATE()));

    IF @Ext2Id IS NOT NULL
    BEGIN
        INSERT INTO dbo.Inspections (
            InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, Passed, IsAccessible, SignageVisible, SealIntact, PinInPlace,
            GaugeInGreenZone, Notes, CreatedDate
        )
        VALUES
          -- Monthly inspection for Ext2 (10 days ago)
          (NEWID(), @TenantId, @Ext2Id, @MonthlyTypeId, @InspectorUserId,
           DATEADD(DAY, -10, GETUTCDATE()), 1, 1, 1, 1, 1, 1,
           'Monthly inspection - unit in good condition',
           DATEADD(DAY, -10, GETUTCDATE()));
    END

    IF @Ext3Id IS NOT NULL
    BEGIN
        INSERT INTO dbo.Inspections (
            InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, Passed, IsAccessible, SignageVisible, SealIntact, PinInPlace,
            GaugeInGreenZone, Notes, CreatedDate
        )
        VALUES
          -- Monthly inspection for Ext3 (5 days ago)
          (NEWID(), @TenantId, @Ext3Id, @MonthlyTypeId, @InspectorUserId,
           DATEADD(DAY, -5, GETUTCDATE()), 1, 1, 1, 1, 1, 1,
           'Monthly inspection - no issues found',
           DATEADD(DAY, -5, GETUTCDATE()));
    END

    -- Add annual inspection if type exists
    IF @AnnualTypeId IS NOT NULL
    BEGIN
        INSERT INTO dbo.Inspections (
            InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionDate, Passed, IsAccessible, SignageVisible, SealIntact, PinInPlace,
            GaugeInGreenZone, Notes, CreatedDate
        )
        VALUES
          -- Annual inspection for Ext1 (30 days ago)
          (NEWID(), @TenantId, @Ext1Id, @AnnualTypeId, @InspectorUserId,
           DATEADD(DAY, -30, GETUTCDATE()), 1, 1, 1, 1, 1, 1,
           'Annual comprehensive inspection - passed all checks',
           DATEADD(DAY, -30, GETUTCDATE()));
    END

    PRINT '✓ Inspections seeded successfully';
END
ELSE
BEGIN
    PRINT '⚠️ Missing required IDs - cannot seed inspections';
END

-- Summary
SELECT
  (SELECT COUNT(*) FROM dbo.Inspections WHERE TenantId = @TenantId) as TotalInspections;

GO
