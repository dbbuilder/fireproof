-- Fix usp_Inspection_GetAll to match service code expectations
-- Issue: Service passes 7 parameters, but stored procedure only accepts 5
-- Date: 2025-10-18
--
-- Service parameters:
--   @TenantId, @ExtinguisherId, @InspectorUserId, @StartDate, @EndDate, @InspectionType, @Passed

USE FireProofDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inspection_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER = NULL,
    @InspectorUserId UNIQUEIDENTIFIER = NULL,
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @InspectionType NVARCHAR(50) = NULL,
    @Passed BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.TenantId,
           i.ExtinguisherId,
           i.InspectionTypeId,
           i.InspectorUserId,
           i.InspectionDate,
           i.InspectionType,
           i.Passed,
           i.GpsLatitude,
           i.GpsLongitude,
           i.GpsAccuracyMeters,
           i.LocationVerified,
           i.IsAccessible,
           i.HasObstructions,
           i.SignageVisible,
           i.SealIntact,
           i.PinInPlace,
           i.NozzleClear,
           i.HoseConditionGood,
           i.GaugeInGreenZone,
           i.GaugePressurePsi,
           i.PhysicalDamagePresent,
           i.DamageDescription,
           i.WeightPounds,
           i.WeightWithinSpec,
           i.InspectionTagAttached,
           i.PreviousInspectionDate,
           i.RequiresService,
           i.RequiresReplacement,
           i.Notes,
           i.FailureReason,
           i.CorrectiveAction,
           i.PhotoUrls,
           i.DataHash,
           i.InspectorSignature,
           i.SignedDate,
           i.IsVerified,
           i.CreatedDate,
           i.ModifiedDate,
           e.AssetTag,
           e.Manufacturer,
           l.LocationName,
           u.FirstName + ' ' + u.LastName AS InspectorName
    FROM dbo.Inspections i
    LEFT JOIN dbo.Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId AND e.TenantId = @TenantId
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId AND l.TenantId = @TenantId
    LEFT JOIN dbo.Users u ON i.InspectorUserId = u.UserId
    WHERE i.TenantId = @TenantId
      AND (@ExtinguisherId IS NULL OR i.ExtinguisherId = @ExtinguisherId)
      AND (@InspectorUserId IS NULL OR i.InspectorUserId = @InspectorUserId)
      AND (@StartDate IS NULL OR i.InspectionDate >= @StartDate)
      AND (@EndDate IS NULL OR i.InspectionDate <= @EndDate)
      AND (@InspectionType IS NULL OR i.InspectionType = @InspectionType)
      AND (@Passed IS NULL OR i.Passed = @Passed)
    ORDER BY i.InspectionDate DESC, i.CreatedDate DESC;
END;
GO

PRINT 'Fixed usp_Inspection_GetAll - now accepts 7 parameters with optional filtering';
