/*******************************************************************************
 * STANDARD SCHEMA STORED PROCEDURES
 *
 * Stored procedures for standard multi-tenant architecture with TenantId columns.
 * All procedures are in dbo schema and filter by TenantId parameter.
 *
 * Created: 2025-10-15
 *******************************************************************************/

USE FireProofDB;
GO

PRINT '========================================';
PRINT 'Creating Standard Stored Procedures';
PRINT '========================================';

-- ============================================================================
-- EXTINGUISHER TYPES (Shared Reference Data - No TenantId)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_ExtinguisherType_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE IsActive = 1
    ORDER BY TypeName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ExtinguisherType_GetById
    @ExtinguisherTypeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ExtinguisherType_Create
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @MonthlyInspectionRequired BIT = 1,
    @AnnualInspectionRequired BIT = 1,
    @HydrostaticTestYears INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ExtinguisherTypes (
        ExtinguisherTypeId, TypeCode, TypeName, Description,
        MonthlyInspectionRequired, AnnualInspectionRequired,
        HydrostaticTestYears, IsActive, CreatedDate
    )
    VALUES (
        @ExtinguisherTypeId, @TypeCode, @TypeName, @Description,
        @MonthlyInspectionRequired, @AnnualInspectionRequired,
        @HydrostaticTestYears, 1, GETUTCDATE()
    );

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ExtinguisherType_Update
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @MonthlyInspectionRequired BIT = 1,
    @AnnualInspectionRequired BIT = 1,
    @HydrostaticTestYears INT = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ExtinguisherTypes
    SET TypeCode = @TypeCode,
        TypeName = @TypeName,
        Description = @Description,
        MonthlyInspectionRequired = @MonthlyInspectionRequired,
        AnnualInspectionRequired = @AnnualInspectionRequired,
        HydrostaticTestYears = @HydrostaticTestYears,
        IsActive = @IsActive
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;

    SELECT ExtinguisherTypeId, TypeCode, TypeName, Description,
           MonthlyInspectionRequired, AnnualInspectionRequired,
           HydrostaticTestYears, IsActive, CreatedDate
    FROM dbo.ExtinguisherTypes
    WHERE ExtinguisherTypeId = @ExtinguisherTypeId;
END;
GO

-- ============================================================================
-- INSPECTION TYPES (Shared Reference Data - No TenantId)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TypeCode, TypeName, Description,
           IntervalMonths, RequiresPhotos, RequiresPressureCheck,
           RequiresWeightCheck, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE IsActive = 1
    ORDER BY TypeName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_GetById
    @InspectionTypeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionTypeId, TypeCode, TypeName, Description,
           IntervalMonths, RequiresPhotos, RequiresPressureCheck,
           RequiresWeightCheck, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_InspectionType_Create
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TypeCode NVARCHAR(50),
    @TypeName NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @IntervalMonths INT = NULL,
    @RequiresPhotos BIT = 0,
    @RequiresPressureCheck BIT = 0,
    @RequiresWeightCheck BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.InspectionTypes (
        InspectionTypeId, TypeCode, TypeName, Description,
        IntervalMonths, RequiresPhotos, RequiresPressureCheck,
        RequiresWeightCheck, IsActive, CreatedDate
    )
    VALUES (
        @InspectionTypeId, @TypeCode, @TypeName, @Description,
        @IntervalMonths, @RequiresPhotos, @RequiresPressureCheck,
        @RequiresWeightCheck, 1, GETUTCDATE()
    );

    SELECT InspectionTypeId, TypeCode, TypeName, Description,
           IntervalMonths, RequiresPhotos, RequiresPressureCheck,
           RequiresWeightCheck, IsActive, CreatedDate
    FROM dbo.InspectionTypes
    WHERE InspectionTypeId = @InspectionTypeId;
END;
GO

-- ============================================================================
-- LOCATIONS (Tenant-Specific - WITH TenantId)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Location_GetAll
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE TenantId = @TenantId
      AND IsActive = 1
    ORDER BY LocationName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Location_GetById
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE TenantId = @TenantId
      AND LocationId = @LocationId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Location_Create
    @LocationId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @LocationCode NVARCHAR(50),
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @ContactName NVARCHAR(200) = NULL,
    @ContactPhone NVARCHAR(50) = NULL,
    @ContactEmail NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Locations (
        LocationId, TenantId, LocationCode, LocationName,
        AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
        ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    )
    VALUES (
        @LocationId, @TenantId, @LocationCode, @LocationName,
        @AddressLine1, @AddressLine2, @City, @StateProvince, @PostalCode, @Country,
        @ContactName, @ContactPhone, @ContactEmail, 1, GETUTCDATE(), GETUTCDATE()
    );

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Location_Update
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @LocationCode NVARCHAR(50),
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @ContactName NVARCHAR(200) = NULL,
    @ContactPhone NVARCHAR(50) = NULL,
    @ContactEmail NVARCHAR(200) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Locations
    SET LocationCode = @LocationCode,
        LocationName = @LocationName,
        AddressLine1 = @AddressLine1,
        AddressLine2 = @AddressLine2,
        City = @City,
        StateProvince = @StateProvince,
        PostalCode = @PostalCode,
        Country = @Country,
        ContactName = @ContactName,
        ContactPhone = @ContactPhone,
        ContactEmail = @ContactEmail,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND LocationId = @LocationId;

    SELECT LocationId, TenantId, LocationCode, LocationName,
           AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
           ContactName, ContactPhone, ContactEmail, IsActive, CreatedDate, ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId;
END;
GO

-- ============================================================================
-- EXTINGUISHERS (Tenant-Specific - WITH TenantId)
-- ============================================================================

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

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_GetById
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER
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
      AND e.ExtinguisherId = @ExtinguisherId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_Create
    @ExtinguisherId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @AssetTag NVARCHAR(100),
    @BarcodeData NVARCHAR(500) = NULL,
    @Manufacturer NVARCHAR(200) = NULL,
    @Model NVARCHAR(200) = NULL,
    @SerialNumber NVARCHAR(200) = NULL,
    @ManufactureDate DATE = NULL,
    @InstallDate DATE = NULL,
    @LastHydrostaticTestDate DATE = NULL,
    @Capacity NVARCHAR(50) = NULL,
    @LocationDescription NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Extinguishers (
        ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
        AssetTag, BarcodeData, Manufacturer, Model, SerialNumber,
        ManufactureDate, InstallDate, LastHydrostaticTestDate,
        Capacity, LocationDescription, IsActive, CreatedDate, ModifiedDate
    )
    VALUES (
        @ExtinguisherId, @TenantId, @LocationId, @ExtinguisherTypeId,
        @AssetTag, @BarcodeData, @Manufacturer, @Model, @SerialNumber,
        @ManufactureDate, @InstallDate, @LastHydrostaticTestDate,
        @Capacity, @LocationDescription, 1, GETUTCDATE(), GETUTCDATE()
    );

    -- Return with joins
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

CREATE OR ALTER PROCEDURE dbo.usp_Extinguisher_Update
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @AssetTag NVARCHAR(100),
    @BarcodeData NVARCHAR(500) = NULL,
    @Manufacturer NVARCHAR(200) = NULL,
    @Model NVARCHAR(200) = NULL,
    @SerialNumber NVARCHAR(200) = NULL,
    @ManufactureDate DATE = NULL,
    @InstallDate DATE = NULL,
    @LastHydrostaticTestDate DATE = NULL,
    @Capacity NVARCHAR(50) = NULL,
    @LocationDescription NVARCHAR(500) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Extinguishers
    SET LocationId = @LocationId,
        ExtinguisherTypeId = @ExtinguisherTypeId,
        AssetTag = @AssetTag,
        BarcodeData = @BarcodeData,
        Manufacturer = @Manufacturer,
        Model = @Model,
        SerialNumber = @SerialNumber,
        ManufactureDate = @ManufactureDate,
        InstallDate = @InstallDate,
        LastHydrostaticTestDate = @LastHydrostaticTestDate,
        Capacity = @Capacity,
        LocationDescription = @LocationDescription,
        IsActive = @IsActive,
        ModifiedDate = GETUTCDATE()
    WHERE TenantId = @TenantId
      AND ExtinguisherId = @ExtinguisherId;

    -- Return with joins
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

PRINT '';
PRINT '========================================';
PRINT 'Stored Procedures Created Successfully';
PRINT '========================================';

-- List created procedures
SELECT
    ROUTINE_NAME AS ProcedureName,
    CREATED AS CreatedDate
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'dbo'
  AND ROUTINE_NAME LIKE 'usp_%'
ORDER BY ROUTINE_NAME;

PRINT '';
PRINT '✓ All stored procedures created!';

GO
