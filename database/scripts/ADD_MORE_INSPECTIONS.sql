/*============================================================================
  ADD MORE INSPECTIONS FOR E2E TESTING

  This script adds more inspection records to the existing DEMO001 tenant
  data to populate charts and provide richer test data for E2E tests.

  Run this script after the initial seed data has been created.
============================================================================*/

USE FireProofDB
GO

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @InspectorUserId UNIQUEIDENTIFIER

-- Get chris@servicevision.net user ID
SELECT @InspectorUserId = UserId FROM dbo.Users WHERE Email = 'chris@servicevision.net'

IF @InspectorUserId IS NULL
BEGIN
    PRINT 'ERROR: chris@servicevision.net user not found'
    RETURN
END

PRINT '============================================================================'
PRINT 'Adding more inspections for E2E testing'
PRINT '============================================================================'
PRINT 'Schema: ' + @Schema
PRINT 'Tenant: ' + CAST(@TenantId AS NVARCHAR(50))
PRINT 'Inspector: ' + CAST(@InspectorUserId AS NVARCHAR(50))
PRINT ''

-- Get existing extinguishers
DECLARE @ExtinguisherIds TABLE (ExtinguisherId UNIQUEIDENTIFIER, RowNum INT)

SET @SQL = N'
SELECT ExtinguisherId, ROW_NUMBER() OVER (ORDER BY CreatedDate) AS RowNum
FROM [' + @Schema + '].Extinguishers'

INSERT INTO @ExtinguisherIds
EXEC sp_executesql @SQL

DECLARE @ExtinguisherCount INT
SELECT @ExtinguisherCount = COUNT(*) FROM @ExtinguisherIds

PRINT 'Found ' + CAST(@ExtinguisherCount AS VARCHAR) + ' extinguishers'
PRINT ''

IF @ExtinguisherCount = 0
BEGIN
    PRINT 'ERROR: No extinguishers found. Run seed data scripts first.'
    RETURN
END

-- Get inspection types
DECLARE @InspectionTypes TABLE (InspectionTypeId UNIQUEIDENTIFIER, TypeName NVARCHAR(100))

SET @SQL = N'
SELECT InspectionTypeId, InspectionTypeName
FROM [' + @Schema + '].InspectionTypes'

INSERT INTO @InspectionTypes
EXEC sp_executesql @SQL

-- Create 50 additional inspections spread over 90 days
-- Mix of Monthly, Annual, and 5-Year inspections
-- 75% pass rate for realistic testing

DECLARE @Counter INT = 1
DECLARE @TotalToCreate INT = 50
DECLARE @CreatedCount INT = 0

PRINT 'Creating ' + CAST(@TotalToCreate AS VARCHAR) + ' inspections...'
PRINT ''

WHILE @Counter <= @TotalToCreate
BEGIN
    DECLARE @ExtId UNIQUEIDENTIFIER
    DECLARE @InspTypeId UNIQUEIDENTIFIER
    DECLARE @InspectionDate DATETIME2
    DECLARE @PassedBit BIT
    DECLARE @InspectionStatus NVARCHAR(50)
    DECLARE @OverallResult NVARCHAR(50)
    DECLARE @InspectionId UNIQUEIDENTIFIER = NEWID()

    -- Spread dates over last 90 days
    SET @InspectionDate = DATEADD(DAY, -(@Counter * 1.8), GETUTCDATE())

    -- Rotate through extinguishers
    SELECT @ExtId = ExtinguisherId
    FROM @ExtinguisherIds
    WHERE RowNum = ((@Counter - 1) % @ExtinguisherCount) + 1

    -- Determine inspection type (60% Monthly, 30% Annual, 10% 5-Year)
    IF @Counter % 10 = 0
        SELECT TOP 1 @InspTypeId = InspectionTypeId FROM @InspectionTypes WHERE TypeName LIKE '%5-Year%'
    ELSE IF @Counter % 3 = 0
        SELECT TOP 1 @InspTypeId = InspectionTypeId FROM @InspectionTypes WHERE TypeName LIKE '%Annual%'
    ELSE
        SELECT TOP 1 @InspTypeId = InspectionTypeId FROM @InspectionTypes WHERE TypeName LIKE '%Monthly%'

    -- 75% pass rate (fail every 4th inspection)
    SET @PassedBit = CASE WHEN @Counter % 4 = 0 THEN 0 ELSE 1 END
    SET @InspectionStatus = 'Completed'
    SET @OverallResult = CASE WHEN @PassedBit = 1 THEN 'Pass' ELSE 'Fail' END

    -- Insert inspection
    SET @SQL = N'
    INSERT INTO [' + @Schema + '].Inspections (
        InspectionId, TenantId, ExtinguisherId, InspectionTypeId,
        InspectorUserId, InspectionStartTime, InspectionEndTime,
        InspectionStatus, OverallResult, TamperHash, CreatedDate
    )
    VALUES (
        @InspectionId, @TenantId, @ExtId, @InspTypeId,
        @InspectorUserId, @InspectionDate, DATEADD(MINUTE, 5, @InspectionDate),
        @InspectionStatus, @OverallResult,
        CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'', CAST(@InspectionId AS NVARCHAR(36)))),
        @InspectionDate
    )'

    EXEC sp_executesql @SQL,
        N'@InspectionId UNIQUEIDENTIFIER, @TenantId UNIQUEIDENTIFIER, @ExtId UNIQUEIDENTIFIER,
          @InspTypeId UNIQUEIDENTIFIER, @InspectorUserId UNIQUEIDENTIFIER, @InspectionDate DATETIME2,
          @InspectionStatus NVARCHAR(50), @OverallResult NVARCHAR(50)',
        @InspectionId, @TenantId, @ExtId, @InspTypeId, @InspectorUserId, @InspectionDate,
        @InspectionStatus, @OverallResult

    SET @CreatedCount = @CreatedCount + 1

    IF @Counter % 10 = 0
        PRINT '  Created ' + CAST(@Counter AS VARCHAR) + '/' + CAST(@TotalToCreate AS VARCHAR) + ' inspections...'

    SET @Counter = @Counter + 1
END

PRINT ''
PRINT '✓ Successfully created ' + CAST(@CreatedCount AS VARCHAR) + ' inspections'
PRINT ''

-- Display summary statistics
PRINT '============================================================================'
PRINT 'INSPECTION SUMMARY'
PRINT '============================================================================'

SET @SQL = N'
SELECT
    ''Total Inspections'' AS Metric,
    COUNT(*) AS Count
FROM [' + @Schema + '].Inspections
UNION ALL
SELECT
    ''Passed'' AS Metric,
    COUNT(*) AS Count
FROM [' + @Schema + '].Inspections
WHERE OverallResult = ''Pass''
UNION ALL
SELECT
    ''Failed'' AS Metric,
    COUNT(*) AS Count
FROM [' + @Schema + '].Inspections
WHERE OverallResult = ''Fail''
UNION ALL
SELECT
    ''Pass Rate'' AS Metric,
    CAST(ROUND(
        (COUNT(CASE WHEN OverallResult = ''Pass'' THEN 1 END) * 100.0 / COUNT(*)),
        1
    ) AS INT) AS Count
FROM [' + @Schema + '].Inspections'

EXEC sp_executesql @SQL

PRINT ''
PRINT 'Database is ready for E2E testing with rich inspection data!'
PRINT '============================================================================'
GO
