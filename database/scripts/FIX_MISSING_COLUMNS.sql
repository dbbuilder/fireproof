/*******************************************************************************
 * FIX MISSING COLUMNS IN STORED PROCEDURES
 *
 * Fixes column mismatches between stored procedures and C# DTOs
 *******************************************************************************/

USE FireProofDB;
GO

PRINT 'Fixing usp_Inspection_GetStats to return all required columns...';
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetStats
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Default to last 30 days if no date range specified
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(DAY, -30, GETUTCDATE());

    IF @EndDate IS NULL
        SET @EndDate = GETUTCDATE();

    SELECT
        COUNT(*) AS TotalInspections,
        SUM(CASE WHEN Passed = 1 THEN 1 ELSE 0 END) AS PassedInspections,
        SUM(CASE WHEN Passed = 0 THEN 1 ELSE 0 END) AS FailedInspections,
        CASE
            WHEN COUNT(*) > 0
            THEN CAST(SUM(CASE WHEN Passed = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100
            ELSE 0
        END AS PassRate,
        SUM(CASE WHEN RequiresService = 1 THEN 1 ELSE 0 END) AS RequiringService,
        SUM(CASE WHEN RequiresReplacement = 1 THEN 1 ELSE 0 END) AS RequiringReplacement,
        MAX(InspectionDate) AS LastInspectionDate,
        SUM(CASE
            WHEN YEAR(InspectionDate) = YEAR(GETUTCDATE())
             AND MONTH(InspectionDate) = MONTH(GETUTCDATE())
            THEN 1
            ELSE 0
        END) AS InspectionsThisMonth,
        SUM(CASE
            WHEN YEAR(InspectionDate) = YEAR(GETUTCDATE())
            THEN 1
            ELSE 0
        END) AS InspectionsThisYear
    FROM dbo.Inspections
    WHERE TenantId = @TenantId
      AND InspectionDate >= @StartDate
      AND InspectionDate <= @EndDate;
END;
GO

PRINT '✓ usp_Inspection_GetStats fixed';
GO

PRINT 'Fixing usp_Inspection_GetAll to return PhotoUrls column...';
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER = NULL,
    @InspectorUserId UNIQUEIDENTIFIER = NULL,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @InspectionType NVARCHAR(200) = NULL,
    @Passed BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId, i.TenantId, i.ExtinguisherId, i.InspectionTypeId, i.InspectorUserId,
           i.InspectionDate, i.Passed, i.IsAccessible, i.HasObstructions, i.SignageVisible,
           i.SealIntact, i.PinInPlace, i.NozzleClear, i.HoseConditionGood, i.GaugeInGreenZone,
           i.GaugePressurePsi, i.PhysicalDamagePresent, i.InspectionTagAttached,
           i.RequiresService, i.RequiresReplacement, i.Notes, i.FailureReason, i.CorrectiveAction,
           i.GPSLatitude, i.GPSLongitude, i.DeviceId, i.TamperProofHash, i.PreviousInspectionHash,
           -- Missing columns - return NULL
           NULL AS PhotoUrls,
           NULL AS DataHash,
           NULL AS InspectorSignature,
           NULL AS SignedDate,
           NULL AS LocationVerified,
           NULL AS GpsAccuracyMeters,
           NULL AS DamageDescription,
           NULL AS WeightPounds,
           NULL AS WeightWithinSpec,
           NULL AS PreviousInspectionDate,
           NULL AS IsVerified,
           i.CreatedDate,
           NULL AS ModifiedDate,
           e.AssetTag,
           l.LocationName,
           it.TypeName AS InspectionTypeName,
           u.FirstName + ' ' + u.LastName AS InspectorName
    FROM dbo.Inspections i
    LEFT JOIN dbo.Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.InspectionTypes it ON i.InspectionTypeId = it.InspectionTypeId
    LEFT JOIN dbo.Users u ON i.InspectorUserId = u.UserId
    WHERE i.TenantId = @TenantId
      AND (@ExtinguisherId IS NULL OR i.ExtinguisherId = @ExtinguisherId)
      AND (@InspectorUserId IS NULL OR i.InspectorUserId = @InspectorUserId)
      AND (@StartDate IS NULL OR i.InspectionDate >= @StartDate)
      AND (@EndDate IS NULL OR i.InspectionDate <= @EndDate)
      AND (@InspectionType IS NULL OR it.TypeName = @InspectionType)
      AND (@Passed IS NULL OR i.Passed = @Passed)
    ORDER BY i.InspectionDate DESC;
END;
GO

PRINT '✓ usp_Inspection_GetAll fixed';
GO

PRINT '✓ All column mismatches fixed!';
GO
