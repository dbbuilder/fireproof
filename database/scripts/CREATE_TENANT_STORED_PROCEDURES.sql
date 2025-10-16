/*============================================================================
  Create Stored Procedures for Specific Tenant
  Tenant: 634f2b52-d32a-46dd-a045-d158e793adcb
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB'
DECLARE @SchemaName NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'

PRINT 'Creating stored procedures for tenant: ' + CAST(@TenantId AS NVARCHAR(36))
PRINT 'Schema: ' + @SchemaName
PRINT ''

/*============================================================================
  LOCATION MANAGEMENT PROCEDURES
============================================================================*/
PRINT 'Creating Location Management Procedures...'

-- usp_Location_Create
DECLARE @CreateLocationCreateProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Location_Create
    @TenantId UNIQUEIDENTIFIER,
    @LocationCode NVARCHAR(50),
    @LocationName NVARCHAR(200),
    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(20) = NULL,
    @Country NVARCHAR(100) = NULL,
    @Latitude DECIMAL(9,6) = NULL,
    @Longitude DECIMAL(9,6) = NULL,
    @LocationId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        SET @LocationId = NEWID()

        -- Generate barcode data
        DECLARE @BarcodeData NVARCHAR(200) = ''LOC:'' + CAST(@TenantId AS NVARCHAR(36)) + '':'' + CAST(@LocationId AS NVARCHAR(36))

        INSERT INTO [' + @SchemaName + '].Locations (
            LocationId, TenantId, LocationCode, LocationName,
            AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country,
            Latitude, Longitude, LocationBarcodeData, IsActive
        )
        VALUES (
            @LocationId, @TenantId, @LocationCode, @LocationName,
            @AddressLine1, @AddressLine2, @City, @StateProvince, @PostalCode, @Country,
            @Latitude, @Longitude, @BarcodeData, 1
        )

        COMMIT TRANSACTION

        SELECT @LocationId AS LocationId, @BarcodeData AS BarcodeData, ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateLocationCreateProc
PRINT '  ✓ Created: usp_Location_Create'

-- usp_Location_GetAll
DECLARE @CreateLocationGetAllProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Location_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        LocationId,
        TenantId,
        LocationCode,
        LocationName,
        AddressLine1,
        AddressLine2,
        City,
        StateProvince,
        PostalCode,
        Country,
        Latitude,
        Longitude,
        LocationBarcodeData,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM [' + @SchemaName + '].Locations
    WHERE TenantId = @TenantId
    AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY LocationName
END
'
EXEC sp_executesql @CreateLocationGetAllProc
PRINT '  ✓ Created: usp_Location_GetAll'

-- usp_Location_GetById
DECLARE @CreateLocationGetByIdProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Location_GetById
    @LocationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        LocationId,
        TenantId,
        LocationCode,
        LocationName,
        AddressLine1,
        AddressLine2,
        City,
        StateProvince,
        PostalCode,
        Country,
        Latitude,
        Longitude,
        LocationBarcodeData,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM [' + @SchemaName + '].Locations
    WHERE LocationId = @LocationId
END
'
EXEC sp_executesql @CreateLocationGetByIdProc
PRINT '  ✓ Created: usp_Location_GetById'

/*============================================================================
  EXTINGUISHER MANAGEMENT PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating Extinguisher Management Procedures...'

-- usp_Extinguisher_Create
DECLARE @CreateExtinguisherCreateProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_Create
    @ExtinguisherId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER,
    @ExtinguisherTypeId UNIQUEIDENTIFIER,
    @AssetTag NVARCHAR(100),
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
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        -- Generate barcode data
        DECLARE @BarcodeData NVARCHAR(200) = ''EXT:'' + CAST(@TenantId AS NVARCHAR(36)) + '':'' + CAST(@ExtinguisherId AS NVARCHAR(36))

        INSERT INTO [' + @SchemaName + '].Extinguishers (
            ExtinguisherId, TenantId, LocationId, ExtinguisherTypeId,
            AssetTag, BarcodeData, Manufacturer, Model, SerialNumber,
            ManufactureDate, InstallDate, LastHydrostaticTestDate,
            Capacity, LocationDescription, IsActive
        )
        VALUES (
            @ExtinguisherId, @TenantId, @LocationId, @ExtinguisherTypeId,
            @AssetTag, @BarcodeData, @Manufacturer, @Model, @SerialNumber,
            @ManufactureDate, @InstallDate, @LastHydrostaticTestDate,
            @Capacity, @LocationDescription, 1
        )

        COMMIT TRANSACTION

        SELECT @ExtinguisherId AS ExtinguisherId, @BarcodeData AS BarcodeData, ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateExtinguisherCreateProc
PRINT '  ✓ Created: usp_Extinguisher_Create'

-- usp_Extinguisher_GetAll
DECLARE @CreateExtinguisherGetAllProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetAll
    @TenantId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        e.ExtinguisherId,
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
        e.CreatedDate,
        e.ModifiedDate,
        l.LocationName,
        l.LocationCode,
        et.TypeName,
        et.TypeCode
    FROM [' + @SchemaName + '].Extinguishers e
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
    AND (@LocationId IS NULL OR e.LocationId = @LocationId)
    AND (@IsActive IS NULL OR e.IsActive = @IsActive)
    ORDER BY l.LocationName, e.AssetTag
END
'
EXEC sp_executesql @CreateExtinguisherGetAllProc
PRINT '  ✓ Created: usp_Extinguisher_GetAll'

-- usp_Extinguisher_GetById
DECLARE @CreateExtinguisherGetByIdProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetById
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        e.ExtinguisherId,
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
        e.CreatedDate,
        e.ModifiedDate,
        l.LocationName,
        l.LocationCode,
        et.TypeName,
        et.TypeCode
    FROM [' + @SchemaName + '].Extinguishers e
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.ExtinguisherId = @ExtinguisherId
END
'
EXEC sp_executesql @CreateExtinguisherGetByIdProc
PRINT '  ✓ Created: usp_Extinguisher_GetById'

-- usp_Extinguisher_GetByBarcode
DECLARE @CreateExtinguisherGetByBarcodeProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetByBarcode
    @BarcodeData NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        e.ExtinguisherId,
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
        e.CreatedDate,
        e.ModifiedDate,
        l.LocationName,
        l.LocationCode,
        l.Latitude AS LocationLatitude,
        l.Longitude AS LocationLongitude,
        et.TypeName,
        et.TypeCode
    FROM [' + @SchemaName + '].Extinguishers e
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.BarcodeData = @BarcodeData
    AND e.IsActive = 1
END
'
EXEC sp_executesql @CreateExtinguisherGetByBarcodeProc
PRINT '  ✓ Created: usp_Extinguisher_GetByBarcode'

-- usp_Extinguisher_Update
DECLARE @CreateExtinguisherUpdateProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_Update
    @ExtinguisherId UNIQUEIDENTIFIER,
    @LocationId UNIQUEIDENTIFIER = NULL,
    @ExtinguisherTypeId UNIQUEIDENTIFIER = NULL,
    @AssetTag NVARCHAR(100) = NULL,
    @Manufacturer NVARCHAR(200) = NULL,
    @Model NVARCHAR(200) = NULL,
    @SerialNumber NVARCHAR(200) = NULL,
    @ManufactureDate DATE = NULL,
    @InstallDate DATE = NULL,
    @LastHydrostaticTestDate DATE = NULL,
    @Capacity NVARCHAR(50) = NULL,
    @LocationDescription NVARCHAR(500) = NULL,
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        UPDATE [' + @SchemaName + '].Extinguishers
        SET
            LocationId = COALESCE(@LocationId, LocationId),
            ExtinguisherTypeId = COALESCE(@ExtinguisherTypeId, ExtinguisherTypeId),
            AssetTag = COALESCE(@AssetTag, AssetTag),
            Manufacturer = COALESCE(@Manufacturer, Manufacturer),
            Model = COALESCE(@Model, Model),
            SerialNumber = COALESCE(@SerialNumber, SerialNumber),
            ManufactureDate = COALESCE(@ManufactureDate, ManufactureDate),
            InstallDate = COALESCE(@InstallDate, InstallDate),
            LastHydrostaticTestDate = COALESCE(@LastHydrostaticTestDate, LastHydrostaticTestDate),
            Capacity = COALESCE(@Capacity, Capacity),
            LocationDescription = COALESCE(@LocationDescription, LocationDescription),
            IsActive = COALESCE(@IsActive, IsActive),
            ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId = @ExtinguisherId

        COMMIT TRANSACTION

        SELECT ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateExtinguisherUpdateProc
PRINT '  ✓ Created: usp_Extinguisher_Update'

-- usp_Extinguisher_Delete
DECLARE @CreateExtinguisherDeleteProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_Delete
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        UPDATE [' + @SchemaName + '].Extinguishers
        SET IsActive = 0, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId = @ExtinguisherId

        COMMIT TRANSACTION

        SELECT ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateExtinguisherDeleteProc
PRINT '  ✓ Created: usp_Extinguisher_Delete'

-- usp_Extinguisher_MarkOutOfService
DECLARE @CreateExtinguisherMarkOutOfServiceProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_MarkOutOfService
    @ExtinguisherId UNIQUEIDENTIFIER,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        UPDATE [' + @SchemaName + '].Extinguishers
        SET IsActive = 0, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId = @ExtinguisherId

        COMMIT TRANSACTION

        SELECT ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateExtinguisherMarkOutOfServiceProc
PRINT '  ✓ Created: usp_Extinguisher_MarkOutOfService'

-- usp_Extinguisher_ReturnToService
DECLARE @CreateExtinguisherReturnToServiceProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_ReturnToService
    @ExtinguisherId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        UPDATE [' + @SchemaName + '].Extinguishers
        SET IsActive = 1, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId = @ExtinguisherId

        COMMIT TRANSACTION

        SELECT ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateExtinguisherReturnToServiceProc
PRINT '  ✓ Created: usp_Extinguisher_ReturnToService'

-- usp_Extinguisher_GetNeedingService
DECLARE @CreateExtinguisherGetNeedingServiceProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetNeedingService
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        e.ExtinguisherId,
        e.AssetTag,
        e.LocationDescription,
        l.LocationName,
        et.TypeName
    FROM [' + @SchemaName + '].Extinguishers e
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
    AND e.IsActive = 0
END
'
EXEC sp_executesql @CreateExtinguisherGetNeedingServiceProc
PRINT '  ✓ Created: usp_Extinguisher_GetNeedingService'

-- usp_Extinguisher_GetNeedingHydroTest
DECLARE @CreateExtinguisherGetNeedingHydroTestProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_GetNeedingHydroTest
    @TenantId UNIQUEIDENTIFIER,
    @TestIntervalYears INT = 5
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @CutoffDate DATE = DATEADD(YEAR, -@TestIntervalYears, GETUTCDATE())

    SELECT
        e.ExtinguisherId,
        e.AssetTag,
        e.LastHydrostaticTestDate,
        e.LocationDescription,
        l.LocationName,
        et.TypeName
    FROM [' + @SchemaName + '].Extinguishers e
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].ExtinguisherTypes et ON e.ExtinguisherTypeId = et.ExtinguisherTypeId
    WHERE e.TenantId = @TenantId
    AND e.IsActive = 1
    AND (e.LastHydrostaticTestDate IS NULL OR e.LastHydrostaticTestDate < @CutoffDate)
END
'
EXEC sp_executesql @CreateExtinguisherGetNeedingHydroTestProc
PRINT '  ✓ Created: usp_Extinguisher_GetNeedingHydroTest'

PRINT ''
PRINT '============================================================================'
PRINT 'Tenant stored procedures created successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT 'Total procedures created: 13'
PRINT '============================================================================'

GO
