/*******************************************************************************
 * CREATE MISSING STORED PROCEDURES
 *
 * This script creates all stored procedures that the API expects but are
 * missing from the database.
 *
 * Missing Procedures Inventory:
 * - Extinguisher: 6 procedures
 * - Inspection: 6 procedures
 * - Tenant: 5 procedures
 * Total: 17 procedures
 *
 * Created: 2025-10-16
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Creating Missing Stored Procedures';
PRINT '========================================';

-- ============================================================================
-- EXTINGUISHER PROCEDURES (6 missing)
-- ============================================================================

PRINT 'Creating Extinguisher procedures...';

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_Delete
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Soft delete by setting IsActive = 0
    UPDATE dbo.Extinguishers
    SET IsActive = 0,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetByBarcode
    @TenantId UNIQUEIDENTIFIER,
    @BarcodeData NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
      AND e.BarcodeData = @BarcodeData
      AND e.IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetNeedingHydroTest
    @TenantId UNIQUEIDENTIFIER,
    @MonthsAhead INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode,
           et.HydrostaticTestYears,
           DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate)) AS NextHydroTestDue
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
      AND e.IsActive = 1
      AND et.HydrostaticTestYears IS NOT NULL
      AND DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate)) <= DATEADD(MONTH, @MonthsAhead, GETUTCDATE())
    ORDER BY DATEADD(YEAR, et.HydrostaticTestYears, ISNULL(e.LastHydrostaticTestDate, e.ManufactureDate));
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetNeedingService
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get extinguishers flagged as needing service from latest inspection
    SELECT DISTINCT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode,
           i.InspectionDate AS LastInspectionDate,
           i.RequiresService,
           i.FailureReason
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    OUTER APPLY (
        SELECT TOP 1 InspectionDate, RequiresService, FailureReason
        FROM dbo.Inspections
        WHERE ExtinguisherId = e.ExtinguisherId
          AND TenantId = @TenantId
        ORDER BY InspectionDate DESC
    ) i
    WHERE e.TenantId = @TenantId
      AND e.IsActive = 1
      AND i.RequiresService = 1
    ORDER BY i.InspectionDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_MarkOutOfService
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @Reason NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET IsActive = 0,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return updated record
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_ReturnToService
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET IsActive = 1,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return updated record
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           e.ManufactureDate, e.InstallDate, e.LastHydrostaticTestDate,
           e.Capacity, e.LocationDescription, e.IsActive, e.CreatedDate, e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId;
END;
GO

PRINT '✓ Extinguisher procedures created (6)';

-- ============================================================================
-- INSPECTION PROCEDURES (6 missing)
-- ============================================================================

PRINT 'Creating Inspection procedures...';

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_Create
    @InspectionId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @InspectionTypeId UNIQUEIDENTIFIER,
    @InspectorUserId UNIQUEIDENTIFIER,
    @InspectionDate DATETIME2,
    @Passed BIT,
    @IsAccessible BIT = 1,
    @HasObstructions BIT = 0,
    @SignageVisible BIT = 1,
    @SealIntact BIT = NULL,
    @PinInPlace BIT = NULL,
    @NozzleClear BIT = NULL,
    @HoseConditionGood BIT = NULL,
    @GaugeInGreenZone BIT = NULL,
    @GaugePressurePsi DECIMAL(6, 2) = NULL,
    @PhysicalDamagePresent BIT = 0,
    @InspectionTagAttached BIT = 1,
    @RequiresService BIT = 0,
    @RequiresReplacement BIT = 0,
    @Notes NVARCHAR(MAX) = NULL,
    @FailureReason NVARCHAR(MAX) = NULL,
    @CorrectiveAction NVARCHAR(MAX) = NULL,
    @GPSLatitude DECIMAL(10, 7) = NULL,
    @GPSLongitude DECIMAL(10, 7) = NULL,
    @DeviceId NVARCHAR(200) = NULL,
    @TamperProofHash NVARCHAR(100) = NULL,
    @PreviousInspectionHash NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Inspections (
        InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
        InspectionDate, Passed, IsAccessible, HasObstructions, SignageVisible,
        SealIntact, PinInPlace, NozzleClear, HoseConditionGood, GaugeInGreenZone,
        GaugePressurePsi, PhysicalDamagePresent, InspectionTagAttached,
        RequiresService, RequiresReplacement, Notes, FailureReason, CorrectiveAction,
        GPSLatitude, GPSLongitude, DeviceId, TamperProofHash, PreviousInspectionHash,
        CreatedDate
    )
    VALUES (
        @InspectionId, @TenantId, @ExtinguisherId, @InspectionTypeId, @InspectorUserId,
        @InspectionDate, @Passed, @IsAccessible, @HasObstructions, @SignageVisible,
        @SealIntact, @PinInPlace, @NozzleClear, @HoseConditionGood, @GaugeInGreenZone,
        @GaugePressurePsi, @PhysicalDamagePresent, @InspectionTagAttached,
        @RequiresService, @RequiresReplacement, @Notes, @FailureReason, @CorrectiveAction,
        @GPSLatitude, @GPSLongitude, @DeviceId, @TamperProofHash, @PreviousInspectionHash,
        GETUTCDATE()
    );

    -- Return created inspection with joins
    SELECT i.InspectionId, i.TenantId, i.ExtinguisherId, i.InspectionTypeId, i.InspectorUserId,
           i.InspectionDate, i.Passed, i.IsAccessible, i.HasObstructions, i.SignageVisible,
           i.SealIntact, i.PinInPlace, i.NozzleClear, i.HoseConditionGood, i.GaugeInGreenZone,
           i.GaugePressurePsi, i.PhysicalDamagePresent, i.InspectionTagAttached,
           i.RequiresService, i.RequiresReplacement, i.Notes, i.FailureReason, i.CorrectiveAction,
           i.GPSLatitude, i.GPSLongitude, i.DeviceId, i.TamperProofHash, i.PreviousInspectionHash,
           i.CreatedDate,
           e.AssetTag,
           l.LocationName,
           it.TypeName AS InspectionTypeName,
           u.FirstName + ' ' + u.LastName AS InspectorName
    FROM dbo.Inspections i
    LEFT JOIN dbo.Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.InspectionTypes it ON i.InspectionTypeId = it.InspectionTypeId
    LEFT JOIN dbo.Users u ON i.InspectorUserId = u.UserId
    WHERE i.InspectionId = @InspectionId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_Delete
    @TenantId UNIQUEIDENTIFIER,
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Hard delete (inspections are immutable by design, but allow admin deletion)
    DELETE FROM dbo.Inspections
    WHERE TenantId = @TenantId
      AND InspectionId = @InspectionId;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER = NULL,
    @InspectorUserId UNIQUEIDENTIFIER = NULL,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId, i.TenantId, i.ExtinguisherId, i.InspectionTypeId, i.InspectorUserId,
           i.InspectionDate, i.Passed, i.IsAccessible, i.HasObstructions, i.SignageVisible,
           i.SealIntact, i.PinInPlace, i.NozzleClear, i.HoseConditionGood, i.GaugeInGreenZone,
           i.GaugePressurePsi, i.PhysicalDamagePresent, i.InspectionTagAttached,
           i.RequiresService, i.RequiresReplacement, i.Notes, i.FailureReason, i.CorrectiveAction,
           i.GPSLatitude, i.GPSLongitude, i.DeviceId, i.TamperProofHash, i.PreviousInspectionHash,
           i.CreatedDate,
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
    ORDER BY i.InspectionDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetById
    @TenantId UNIQUEIDENTIFIER,
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId, i.TenantId, i.ExtinguisherId, i.InspectionTypeId, i.InspectorUserId,
           i.InspectionDate, i.Passed, i.IsAccessible, i.HasObstructions, i.SignageVisible,
           i.SealIntact, i.PinInPlace, i.NozzleClear, i.HoseConditionGood, i.GaugeInGreenZone,
           i.GaugePressurePsi, i.PhysicalDamagePresent, i.InspectionTagAttached,
           i.RequiresService, i.RequiresReplacement, i.Notes, i.FailureReason, i.CorrectiveAction,
           i.GPSLatitude, i.GPSLongitude, i.DeviceId, i.TamperProofHash, i.PreviousInspectionHash,
           i.CreatedDate,
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
      AND i.InspectionId = @InspectionId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetOverdue
    @TenantId UNIQUEIDENTIFIER,
    @DaysOverdue INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Get extinguishers without recent inspections based on inspection type frequency
    WITH LatestInspections AS (
        SELECT
            ExtinguisherId,
            MAX(InspectionDate) AS LastInspectionDate
        FROM dbo.Inspections
        WHERE TenantId = @TenantId
        GROUP BY ExtinguisherId
    )
    SELECT e.ExtinguisherId, e.TenantId, e.LocationId, e.ExtinguisherTypeId,
           e.AssetTag, e.BarcodeData, e.Manufacturer, e.Model, e.SerialNumber,
           l.LocationName,
           et.TypeName,
           li.LastInspectionDate,
           DATEDIFF(DAY, li.LastInspectionDate, GETUTCDATE()) AS DaysSinceInspection
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    LEFT JOIN LatestInspections li ON e.ExtinguisherId = li.ExtinguisherId
    WHERE e.TenantId = @TenantId
      AND e.IsActive = 1
      AND (li.LastInspectionDate IS NULL
           OR DATEDIFF(DAY, li.LastInspectionDate, GETUTCDATE()) > @DaysOverdue)
    ORDER BY li.LastInspectionDate ASC;
END;
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
        MIN(InspectionDate) AS EarliestInspection,
        MAX(InspectionDate) AS LatestInspection
    FROM dbo.Inspections
    WHERE TenantId = @TenantId
      AND InspectionDate >= @StartDate
      AND InspectionDate <= @EndDate;
END;
GO

PRINT '✓ Inspection procedures created (6)';

-- ============================================================================
-- TENANT PROCEDURES (5 missing)
-- ============================================================================

PRINT 'Creating Tenant procedures...';

CREATE OR ALTER PROCEDURE dbo.usp_Tenant_Create
    @TenantId UNIQUEIDENTIFIER,
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50) = 'Free',
    @MaxLocations INT = 10,
    @MaxUsers INT = 5,
    @MaxExtinguishers INT = 100,
    @DatabaseSchema NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Tenants (
        TenantId, TenantCode, CompanyName, SubscriptionTier,
        IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
        DatabaseSchema, CreatedDate, ModifiedDate
    )
    VALUES (
        @TenantId, @TenantCode, @CompanyName, @SubscriptionTier,
        1, @MaxLocations, @MaxUsers, @MaxExtinguishers,
        @DatabaseSchema, GETUTCDATE(), GETUTCDATE()
    );

    -- Return created tenant
    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Tenant_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE IsActive = 1
    ORDER BY CompanyName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Tenant_GetById
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Tenant_Update
    @TenantId UNIQUEIDENTIFIER,
    @TenantCode NVARCHAR(50),
    @CompanyName NVARCHAR(200),
    @SubscriptionTier NVARCHAR(50),
    @MaxLocations INT,
    @MaxUsers INT,
    @MaxExtinguishers INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Tenants
    SET TenantCode = @TenantCode,
        CompanyName = @CompanyName,
        SubscriptionTier = @SubscriptionTier,
        MaxLocations = @MaxLocations,
        MaxUsers = @MaxUsers,
        MaxExtinguishers = @MaxExtinguishers,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId;

    -- Return updated tenant
    SELECT TenantId, TenantCode, CompanyName, SubscriptionTier,
           IsActive, MaxLocations, MaxUsers, MaxExtinguishers,
           DatabaseSchema, CreatedDate, ModifiedDate
    FROM dbo.Tenants
    WHERE TenantId = @TenantId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Tenant_GetAvailableForUser
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get tenants the user has access to via UserTenantRoles
    SELECT DISTINCT t.TenantId, t.TenantCode, t.CompanyName, t.SubscriptionTier,
           t.IsActive, t.MaxLocations, t.MaxUsers, t.MaxExtinguishers,
           t.DatabaseSchema, t.CreatedDate, t.ModifiedDate,
           utr.RoleName AS UserRole
    FROM dbo.Tenants t
    INNER JOIN dbo.UserTenantRoles utr ON t.TenantId = utr.TenantId
    WHERE utr.UserId = @UserId
      AND t.IsActive = 1
      AND utr.IsActive = 1
    ORDER BY t.CompanyName;
END;
GO

PRINT '✓ Tenant procedures created (5)';

PRINT '';
PRINT '========================================';
PRINT 'Summary: All Missing Procedures Created';
PRINT '========================================';
PRINT 'Extinguisher: 6 procedures';
PRINT 'Inspection: 6 procedures';
PRINT 'Tenant: 5 procedures';
PRINT 'Total: 17 procedures';
PRINT '';

-- List all procedures
SELECT
    ROUTINE_NAME AS ProcedureName,
    CREATED AS CreatedDate,
    LAST_ALTERED AS ModifiedDate
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'dbo'
  AND ROUTINE_NAME LIKE 'usp_%'
ORDER BY ROUTINE_NAME;

PRINT '';
PRINT '✓ All missing stored procedures created successfully!';
GO
