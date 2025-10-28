-- Fix usp_Extinguisher_GetAll to match service code expectations
-- Issue: Service passes 5 parameters, but stored procedure only accepts 1
-- Date: 2025-10-18
--
-- Service parameters:
--   @TenantId, @LocationId, @ExtinguisherTypeId, @IsActive, @IsOutOfService

USE FireProofDB;
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

    SELECT e.ExtinguisherId,
           e.TenantId,
           e.LocationId,
           e.ExtinguisherTypeId,
           e.AssetTag,
           e.BarcodeData,
           e.Manufacturer,
           e.Model,
           e.SerialNumber,
           e.ManufactureDate,
           e.InstallDate,
           e.LastHydrostaticTestDate,
           e.Capacity,
           e.LocationDescription,
           e.IsActive,
           e.IsOutOfService,
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    LEFT JOIN dbo.Locations l ON e.LocationId = l.LocationId AND l.TenantId = @TenantId
    LEFT JOIN dbo.ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
      AND (@LocationId IS NULL OR e.LocationId = @LocationId)
      AND (@ExtinguisherTypeId IS NULL OR e.ExtinguisherTypeId = @ExtinguisherTypeId)
      AND (@IsActive IS NULL OR e.IsActive = @IsActive)
      AND (@IsOutOfService IS NULL OR e.IsOutOfService = @IsOutOfService)
    ORDER BY l.LocationName, e.AssetTag;
END;
GO

PRINT 'Fixed usp_Extinguisher_GetAll - now accepts 5 parameters with optional filtering';
