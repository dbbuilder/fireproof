/*============================================================================
  File:     004_CreateTenantStoredProcedures.sql
  Summary:  Creates tenant-specific stored procedures
  Date:     October 9, 2025

  Description:
    This script creates stored procedures within a tenant schema for:
    - Location management
    - Extinguisher management
    - Inspection operations
    - Reporting

  Usage:
    Replace {tenant_schema} with actual tenant schema name before execution
    OR run dynamically via application code during tenant provisioning

  Notes:
    - All procedures operate within tenant schema boundaries
    - Includes tamper-proofing logic for inspections
    - Supports offline inspection sync
============================================================================*/

PRINT 'Starting 004_CreateTenantStoredProcedures.sql execution...'
PRINT 'Creating tenant-specific stored procedures'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

-- Get tenant schema name from first active tenant (DEMO001)
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @SchemaName NVARCHAR(128)

SELECT TOP 1 @TenantId = TenantId, @SchemaName = DatabaseSchema
FROM dbo.Tenants
WHERE TenantCode = 'DEMO001' AND IsActive = 1

IF @SchemaName IS NULL
BEGIN
    PRINT 'ERROR: No tenant schema found. Run 001 and 002 scripts first.'
    RETURN
END

PRINT 'Creating procedures for schema: ' + @SchemaName
PRINT 'Tenant ID: ' + CAST(@TenantId AS NVARCHAR(36))
PRINT ''

/*============================================================================
  SECTION: LOCATION MANAGEMENT PROCEDURES
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
PRINT '  - Created: ' + @SchemaName + '.usp_Location_Create'

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
PRINT '  - Created: ' + @SchemaName + '.usp_Location_GetAll'

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
PRINT '  - Created: ' + @SchemaName + '.usp_Location_GetById'

/*============================================================================
  SECTION: EXTINGUISHER MANAGEMENT PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating Extinguisher Management Procedures...'

-- usp_Extinguisher_Create
DECLARE @CreateExtinguisherCreateProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Extinguisher_Create
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
    @LocationDescription NVARCHAR(500) = NULL,
    @ExtinguisherId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        SET @ExtinguisherId = NEWID()

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
PRINT '  - Created: ' + @SchemaName + '.usp_Extinguisher_Create'

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
PRINT '  - Created: ' + @SchemaName + '.usp_Extinguisher_GetAll'

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
PRINT '  - Created: ' + @SchemaName + '.usp_Extinguisher_GetByBarcode'

/*============================================================================
  SECTION: INSPECTION PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating Inspection Procedures...'

-- usp_Inspection_Create
DECLARE @CreateInspectionCreateProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Inspection_Create
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @InspectionTypeId UNIQUEIDENTIFIER,
    @InspectorUserId UNIQUEIDENTIFIER,
    @Latitude DECIMAL(9,6) = NULL,
    @Longitude DECIMAL(9,6) = NULL,
    @GpsAccuracy DECIMAL(10,2) = NULL,
    @DeviceFingerprint NVARCHAR(500) = NULL,
    @IsOfflineInspection BIT = 0,
    @InspectionId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        SET @InspectionId = NEWID()

        -- Get previous inspection hash for chain
        DECLARE @PreviousHash NVARCHAR(128)
        SELECT TOP 1 @PreviousHash = TamperHash
        FROM [' + @SchemaName + '].Inspections
        WHERE ExtinguisherId = @ExtinguisherId
        ORDER BY InspectionStartTime DESC

        -- Generate tamper hash (temporary - will be updated on completion)
        DECLARE @TempHash NVARCHAR(128) = CONVERT(NVARCHAR(128), HASHBYTES(''SHA2_256'',
            CAST(@InspectionId AS NVARCHAR(36)) +
            CAST(GETUTCDATE() AS NVARCHAR(50)) +
            CAST(@ExtinguisherId AS NVARCHAR(36))
        ), 2)

        INSERT INTO [' + @SchemaName + '].Inspections (
            InspectionId, TenantId, ExtinguisherId, InspectionTypeId, InspectorUserId,
            InspectionStartTime, InspectionStatus, Latitude, Longitude, GpsAccuracy,
            DeviceFingerprint, TamperHash, PreviousInspectionHash, IsOfflineInspection
        )
        VALUES (
            @InspectionId, @TenantId, @ExtinguisherId, @InspectionTypeId, @InspectorUserId,
            GETUTCDATE(), ''InProgress'', @Latitude, @Longitude, @GpsAccuracy,
            @DeviceFingerprint, @TempHash, @PreviousHash, @IsOfflineInspection
        )

        COMMIT TRANSACTION

        SELECT @InspectionId AS InspectionId, ''SUCCESS'' AS Status
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateInspectionCreateProc
PRINT '  - Created: ' + @SchemaName + '.usp_Inspection_Create'

-- usp_Inspection_Complete
DECLARE @CreateInspectionCompleteProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Inspection_Complete
    @InspectionId UNIQUEIDENTIFIER,
    @OverallResult NVARCHAR(50),
    @InspectorNotes NVARCHAR(MAX) = NULL,
    @TamperHash NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        UPDATE [' + @SchemaName + '].Inspections
        SET
            InspectionEndTime = GETUTCDATE(),
            InspectionStatus = ''Completed'',
            OverallResult = @OverallResult,
            InspectorNotes = @InspectorNotes,
            TamperHash = @TamperHash,
            ModifiedDate = GETUTCDATE()
        WHERE InspectionId = @InspectionId

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
EXEC sp_executesql @CreateInspectionCompleteProc
PRINT '  - Created: ' + @SchemaName + '.usp_Inspection_Complete'

-- usp_Inspection_GetById
DECLARE @CreateInspectionGetByIdProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Inspection_GetById
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        i.InspectionId,
        i.TenantId,
        i.ExtinguisherId,
        i.InspectionTypeId,
        i.InspectorUserId,
        i.InspectionStartTime,
        i.InspectionEndTime,
        i.InspectionStatus,
        i.Latitude,
        i.Longitude,
        i.GpsAccuracy,
        i.DeviceFingerprint,
        i.OverallResult,
        i.InspectorNotes,
        i.TamperHash,
        i.PreviousInspectionHash,
        i.IsOfflineInspection,
        i.SyncedDate,
        i.CreatedDate,
        e.AssetTag,
        e.BarcodeData AS ExtinguisherBarcode,
        l.LocationName,
        it.TypeName AS InspectionTypeName
    FROM [' + @SchemaName + '].Inspections i
    INNER JOIN [' + @SchemaName + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    INNER JOIN [' + @SchemaName + '].Locations l ON e.LocationId = l.LocationId
    INNER JOIN [' + @SchemaName + '].InspectionTypes it ON i.InspectionTypeId = it.InspectionTypeId
    WHERE i.InspectionId = @InspectionId
END
'
EXEC sp_executesql @CreateInspectionGetByIdProc
PRINT '  - Created: ' + @SchemaName + '.usp_Inspection_GetById'

-- usp_Inspection_GetByExtinguisher
DECLARE @CreateInspectionGetByExtProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Inspection_GetByExtinguisher
    @ExtinguisherId UNIQUEIDENTIFIER,
    @PageSize INT = 50,
    @PageNumber INT = 1
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        i.InspectionId,
        i.InspectionStartTime,
        i.InspectionEndTime,
        i.InspectionStatus,
        i.OverallResult,
        i.InspectorNotes,
        i.IsOfflineInspection,
        it.TypeName AS InspectionTypeName,
        u.FirstName + '' '' + u.LastName AS InspectorName
    FROM [' + @SchemaName + '].Inspections i
    INNER JOIN [' + @SchemaName + '].InspectionTypes it ON i.InspectionTypeId = it.InspectionTypeId
    INNER JOIN dbo.Users u ON i.InspectorUserId = u.UserId
    WHERE i.ExtinguisherId = @ExtinguisherId
    ORDER BY i.InspectionStartTime DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
END
'
EXEC sp_executesql @CreateInspectionGetByExtProc
PRINT '  - Created: ' + @SchemaName + '.usp_Inspection_GetByExtinguisher'

-- usp_InspectionResponse_CreateBatch
DECLARE @CreateResponseBatchProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_InspectionResponse_CreateBatch
    @InspectionId UNIQUEIDENTIFIER,
    @ResponsesJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        -- Insert responses from JSON array
        INSERT INTO [' + @SchemaName + '].InspectionChecklistResponses (
            ResponseId, InspectionId, ChecklistItemId, ResponseValue, Notes, PhotoBlobPath
        )
        SELECT
            NEWID(),
            @InspectionId,
            JSON_VALUE(value, ''$.ChecklistItemId''),
            JSON_VALUE(value, ''$.ResponseValue''),
            JSON_VALUE(value, ''$.Notes''),
            JSON_VALUE(value, ''$.PhotoBlobPath'')
        FROM OPENJSON(@ResponsesJson)

        COMMIT TRANSACTION

        SELECT ''SUCCESS'' AS Status, @@ROWCOUNT AS RowsInserted
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
'
EXEC sp_executesql @CreateResponseBatchProc
PRINT '  - Created: ' + @SchemaName + '.usp_InspectionResponse_CreateBatch'

/*============================================================================
  SECTION: REPORTING PROCEDURES
============================================================================*/
PRINT ''
PRINT 'Creating Reporting Procedures...'

-- usp_Report_ComplianceDashboard
DECLARE @CreateComplianceDashboardProc NVARCHAR(MAX) = '
CREATE OR ALTER PROCEDURE [' + @SchemaName + '].usp_Report_ComplianceDashboard
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    IF @StartDate IS NULL SET @StartDate = DATEADD(MONTH, -1, GETUTCDATE())
    IF @EndDate IS NULL SET @EndDate = GETUTCDATE()

    -- Total extinguishers
    DECLARE @TotalExtinguishers INT
    SELECT @TotalExtinguishers = COUNT(*)
    FROM [' + @SchemaName + '].Extinguishers
    WHERE TenantId = @TenantId AND IsActive = 1

    -- Inspections in period
    DECLARE @InspectionsCompleted INT
    SELECT @InspectionsCompleted = COUNT(*)
    FROM [' + @SchemaName + '].Inspections
    WHERE TenantId = @TenantId
    AND InspectionStatus = ''Completed''
    AND InspectionStartTime BETWEEN @StartDate AND @EndDate

    -- Failed inspections
    DECLARE @FailedInspections INT
    SELECT @FailedInspections = COUNT(*)
    FROM [' + @SchemaName + '].Inspections
    WHERE TenantId = @TenantId
    AND InspectionStatus = ''Completed''
    AND OverallResult = ''Fail''
    AND InspectionStartTime BETWEEN @StartDate AND @EndDate

    -- Compliance rate
    DECLARE @ComplianceRate DECIMAL(5,2) = 0
    IF @InspectionsCompleted > 0
        SET @ComplianceRate = CAST((@InspectionsCompleted - @FailedInspections) AS DECIMAL) / @InspectionsCompleted * 100

    SELECT
        @TotalExtinguishers AS TotalExtinguishers,
        @InspectionsCompleted AS InspectionsCompleted,
        @FailedInspections AS FailedInspections,
        @ComplianceRate AS ComplianceRate,
        @StartDate AS StartDate,
        @EndDate AS EndDate
END
'
EXEC sp_executesql @CreateComplianceDashboardProc
PRINT '  - Created: ' + @SchemaName + '.usp_Report_ComplianceDashboard'

PRINT ''
PRINT '============================================================================'
PRINT 'Tenant stored procedures created successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT 'Total procedures created: 14'
PRINT '============================================================================'

GO
