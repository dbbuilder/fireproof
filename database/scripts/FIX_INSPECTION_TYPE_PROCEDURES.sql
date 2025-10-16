/*******************************************************************************
 * FIX INSPECTION TYPE STORED PROCEDURES
 *
 * Corrects the InspectionType stored procedures to match actual table schema:
 * - Add TenantId parameter (tenant-scoped data, not shared)
 * - Use correct columns: RequiresServiceTechnician, FrequencyDays
 * - Remove incorrect columns: TypeCode, IntervalMonths, RequiresPhotos, etc.
 *
 * Created: 2025-10-15
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Fixing InspectionType Stored Procedures';
PRINT '========================================';
GO

-- ============================================================================
-- INSPECTION TYPES (Tenant-Specific - WITH TenantId)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_GetAll
    @TenantId UNIQUEIDENTIFIER = NULL  -- Optional: NULL returns all, specific ID filters by tenant
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE (@TenantId IS NULL OR TenantId = @TenantId)
      AND IsActive = 1
    ORDER BY TypeName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_GetById
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId
      AND (@TenantId IS NULL OR TenantId = @TenantId);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_Create
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @RequiresServiceTechnician BIT = 0,
    @FrequencyDays INT = 365
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.InspectionTypes (
        InspectionTypeId, TenantId, TypeName, Description,
        RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    )
    VALUES (
        @InspectionTypeId, @TenantId, @TypeName, @Description,
        @RequiresServiceTechnician, @FrequencyDays, 1, GETUTCDATE()
    );

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_Update
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @RequiresServiceTechnician BIT = 0,
    @FrequencyDays INT = 365,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.InspectionTypes
    SET TypeName = @TypeName,
        Description = @Description,
        RequiresServiceTechnician = @RequiresServiceTechnician,
        FrequencyDays = @FrequencyDays,
        IsActive = @IsActive
    WHERE InspectionTypeId = @InspectionTypeId
      AND TenantId = @TenantId;

    SELECT InspectionTypeId, TenantId, TypeName, Description,
           RequiresServiceTechnician, FrequencyDays, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;
GO

-- ============================================================================
-- FIX LOCATION UPDATE - REMOVE LocationCode (IT'S IMMUTABLE)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Location_Update
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @Latitude DECIMAL(10,7) = NULL,
    @Longitude DECIMAL(10,7) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Locations
    SET LocationName = @LocationName,
        AddressLine1 = @AddressLine1,
        AddressLine2 = @AddressLine2,
        City = @City,
        StateProvince = @StateProvince,
        PostalCode = @PostalCode,
        Country = @Country,
        Latitude = @Latitude,
        Longitude = @Longitude,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND LocationId = @LocationId;

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           Latitude, Longitude, LocationBarcodeData, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId;
END;
GO

PRINT '';
PRINT '========================================';
PRINT 'InspectionType & Location Procedures Fixed';
PRINT '========================================';
PRINT '✓ Procedures now match actual table schema';
PRINT '';

GO
