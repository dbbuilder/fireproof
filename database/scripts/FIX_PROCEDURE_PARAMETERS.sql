/*******************************************************************************
 * FIX STORED PROCEDURE PARAMETERS
 *
 * Update stored procedures to match the actual parameters being passed by services
 *******************************************************************************/

USE FireProofDB;
GO

PRINT 'Fixing usp_Extinguisher_GetAll to accept all filter parameters...';
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER = NULL,
    @ExtinguisherTypeId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = NULL,
    @IsOutOfService BIT = NULL
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
      AND (@LocationId IS NULL OR e.LocationId = @LocationId)
      AND (@ExtinguisherTypeId IS NULL OR e.ExtinguisherTypeId = @ExtinguisherTypeId)
      AND (@IsActive IS NULL OR e.IsActive = @IsActive)
    ORDER BY e.AssetTag;
END;
GO

PRINT '✓ usp_Extinguisher_GetAll fixed';
GO

PRINT 'Fixing usp_Inspection_GetAll to accept all filter parameters...';
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
      AND (@InspectionType IS NULL OR it.TypeName = @InspectionType)
      AND (@Passed IS NULL OR i.Passed = @Passed)
    ORDER BY i.InspectionDate DESC;
END;
GO

PRINT '✓ usp_Inspection_GetAll fixed';
GO

PRINT '✓ All procedure parameters fixed!';
GO
