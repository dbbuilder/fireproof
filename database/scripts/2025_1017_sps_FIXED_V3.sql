/****** Object: StoredProcedure dbo.[usp_Location_GetAll] Script Date: 10/17/2025 1:52:58 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Location_GetAll];
GO

CREATE PROCEDURE dbo.[usp_Location_GetAll]
      @TenantId UNIQUEIDENTIFIER, @IsActive BIT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
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
    FROM dbo.Locations
    WHERE TenantId=@TenantId AND (@IsActive IS NULL OR IsActive=@IsActive)
    ORDER BY LocationName;
END;

GO

/****** Object: StoredProcedure dbo.[usp_Location_GetById] Script Date: 10/17/2025 1:52:58 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Location_GetById];
GO

CREATE PROCEDURE dbo.[usp_Location_GetById]
      @LocationId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
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
    FROM dbo.Locations
    WHERE LocationId=@LocationId;
END;

GO

/****** Object: StoredProcedure dbo.[usp_Extinguisher_GetAll] Script Date: 10/17/2025 1:52:58 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Extinguisher_GetAll];
GO

CREATE PROCEDURE dbo.[usp_Extinguisher_GetAll]
      @TenantId UNIQUEIDENTIFIER, @LocationId UNIQUEIDENTIFIER = NULL, @IsActive BIT = NULL
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
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId
          AND (@LocationId IS NULL OR e.LocationId=@LocationId)
          AND (@IsActive IS NULL OR e.IsActive=@IsActive)
    ORDER BY l.LocationName, e.AssetTag;
END;

GO

/****** Object: StoredProcedure dbo.[usp_Extinguisher_GetById] Script Date: 10/17/2025 1:52:58 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Extinguisher_GetById];
GO

CREATE PROCEDURE dbo.[usp_Extinguisher_GetById]
      @ExtinguisherId UNIQUEIDENTIFIER
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
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM dbo.Extinguishers e
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.ExtinguisherId=@ExtinguisherId;
END;

GO

/****** Object: StoredProcedure dbo.[usp_Inspection_GetById] Script Date: 10/17/2025 1:52:58 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Inspection_GetById];
GO

CREATE PROCEDURE dbo.[usp_Inspection_GetById]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.TenantId,
           i.ExtinguisherId,
           i.InspectionTypeId,
           i.InspectorUserId,
           i.InspectionDate,
           i.InspectionDate,
           i.InspectionStatus,
           i.OverallResult,
           i.GpsLatitude,
           i.GpsLongitude,
           i.GpsAccuracyMeters,
           i.Notes,
           e.AssetTag,
           l.LocationName,
           it.TypeName AS InspectionTypeName
    FROM dbo.Inspections i
    INNER JOIN dbo.Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    INNER JOIN dbo.Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN dbo.InspectionTypes it
              ON i.InspectionTypeId=it.InspectionTypeId
    WHERE i.InspectionId=@InspectionId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_GetById] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_GetById]
      @LocationId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
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
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE LocationId=@LocationId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_GetAll] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_GetAll]
      @TenantId UNIQUEIDENTIFIER, @IsActive BIT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT LocationId,
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
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
    WHERE TenantId=@TenantId AND (@IsActive IS NULL OR IsActive=@IsActive)
    ORDER BY LocationName;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Create] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Create]
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
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Generate barcode data

        DECLARE @BarcodeData NVARCHAR(200) = 'EXT:' + CAST(@TenantId AS NVARCHAR(36)) + ':' + CAST(@ExtinguisherId AS NVARCHAR(36));

        INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
        (  
           ExtinguisherId,
           TenantId,
           LocationId,
           ExtinguisherTypeId,
           AssetTag,
           BarcodeData,
           Manufacturer,
           Model,
           SerialNumber,
           ManufactureDate,
           InstallDate,
           LastHydrostaticTestDate,
           Capacity,
           LocationDescription,
           IsActive
        )
        VALUES (  
                  @ExtinguisherId,
                  @TenantId,
                  @LocationId,
                  @ExtinguisherTypeId,
                  @AssetTag,
                  @BarcodeData,
                  @Manufacturer,
                  @Model,
                  @SerialNumber,
                  @ManufactureDate,
                  @InstallDate,
                  @LastHydrostaticTestDate,
                  @Capacity,
                  @LocationDescription,
                  1
               );

        COMMIT TRANSACTION;

        SELECT @ExtinguisherId AS ExtinguisherId, @BarcodeData AS BarcodeData, 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetAll] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetAll]
      @TenantId UNIQUEIDENTIFIER, @LocationId UNIQUEIDENTIFIER = NULL, @IsActive BIT = NULL
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
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId
          AND (@LocationId IS NULL OR e.LocationId=@LocationId)
          AND (@IsActive IS NULL OR e.IsActive=@IsActive)
    ORDER BY l.LocationName, e.AssetTag;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetByBarcode] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetByBarcode]
      @BarcodeData NVARCHAR(200)
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
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           l.Latitude AS LocationLatitude,
           l.Longitude AS LocationLongitude,
           et.TypeName,
           et.TypeCode
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.BarcodeData=@BarcodeData AND e.IsActive=1;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionResponse_CreateBatch] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionResponse_CreateBatch]
      @InspectionId UNIQUEIDENTIFIER, @ResponsesJson NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert responses from JSON array

        INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionChecklistResponses
        (  
           ResponseId,
           InspectionId,
           ChecklistItemId,
           ResponseValue,
           Notes,
           PhotoBlobPath
        )
        SELECT NEWID(),
               @InspectionId,
               JSON_VALUE(value, '$.ChecklistItemId'),
               JSON_VALUE(value, '$.ResponseValue'),
               JSON_VALUE(value, '$.Notes'),
               JSON_VALUE(value, '$.PhotoBlobPath')
        FROM OPENJSON(@ResponsesJson);

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status, @@ROWCOUNT AS RowsInserted;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_Create] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Location_Create]
      @TenantId UNIQUEIDENTIFIER,
      @LocationCode NVARCHAR(50),
      @LocationName NVARCHAR(200),
      @AddressLine1 NVARCHAR(200) = NULL,
      @AddressLine2 NVARCHAR(200) = NULL,
      @City NVARCHAR(100) = NULL,
      @StateProvince NVARCHAR(100) = NULL,
      @PostalCode NVARCHAR(20) = NULL,
      @Country NVARCHAR(100) = NULL,
      @Latitude DECIMAL(9, 6) = NULL,
      @Longitude DECIMAL(9, 6) = NULL,
      @LocationId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SET @LocationId = NEWID();

        -- Generate barcode data
        DECLARE @BarcodeData NVARCHAR(200) = 'LOC:' + CAST(@TenantId AS NVARCHAR(36)) + ':' + CAST(@LocationId AS NVARCHAR(36));

        INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations
        (  
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
           IsActive
        )
        VALUES (  
                  @LocationId,
                  @TenantId,
                  @LocationCode,
                  @LocationName,
                  @AddressLine1,
                  @AddressLine2,
                  @City,
                  @StateProvince,
                  @PostalCode,
                  @Country,
                  @Latitude,
                  @Longitude,
                  @BarcodeData,
                  1
               );

        COMMIT TRANSACTION;

        SELECT @LocationId AS LocationId, @BarcodeData AS BarcodeData, 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Report_ComplianceDashboard] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Report_ComplianceDashboard]
      @TenantId UNIQUEIDENTIFIER, @StartDate DATE = NULL, @EndDate DATE = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    IF @StartDate IS NULL
        SET @StartDate = DATEADD(MONTH, -1, GETUTCDATE());

    IF @EndDate IS NULL
        SET @EndDate = GETUTCDATE();

    -- Total extinguishers
    DECLARE @TotalExtinguishers INT;

    SELECT @TotalExtinguishers = COUNT(*)
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers
    WHERE TenantId=@TenantId AND IsActive=1;

    -- Inspections in period
    DECLARE @InspectionsCompleted INT;

    SELECT @InspectionsCompleted = COUNT(*)
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    WHERE TenantId=@TenantId
          AND InspectionStatus='Completed'
          AND InspectionStartTime BETWEEN @StartDate AND @EndDate;

    -- Failed inspections
    DECLARE @FailedInspections INT;

    SELECT @FailedInspections = COUNT(*)
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    WHERE TenantId=@TenantId
          AND InspectionStatus='Completed'
          AND OverallResult='Fail'
          AND InspectionStartTime BETWEEN @StartDate AND @EndDate;

    -- Compliance rate
    DECLARE @ComplianceRate DECIMAL(5, 2) = 0;

    IF @InspectionsCompleted>0
        SET @ComplianceRate = CAST((@InspectionsCompleted - @FailedInspections) AS DECIMAL) / @InspectionsCompleted * 100;

    SELECT @TotalExtinguishers AS TotalExtinguishers,
           @InspectionsCompleted AS InspectionsCompleted,
           @FailedInspections AS FailedInspections,
           @ComplianceRate AS ComplianceRate,
           @StartDate AS StartDate,
           @EndDate AS EndDate;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetByExtinguisher] Script Date: 10/17/2025 1:52:59 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetByExtinguisher]
      @ExtinguisherId UNIQUEIDENTIFIER, @PageSize INT = 50, @PageNumber INT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.InspectionStartTime,
           i.InspectionEndTime,
           i.InspectionStatus,
           i.OverallResult,
           i.InspectorNotes,
           i.IsOfflineInspection,
           it.TypeName AS InspectionTypeName,
           u.FirstName + ' ' + u.LastName AS InspectorName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionTypes it
              ON i.InspectionTypeId=it.InspectionTypeId
    INNER JOIN dbo.Users u
              ON i.InspectorUserId=u.UserId
    WHERE i.ExtinguisherId=@ExtinguisherId
    ORDER BY i.InspectionStartTime DESC OFFSET(@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ExtinguisherType_GetById] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ExtinguisherType_GetById]
      @ExtinguisherTypeId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT ExtinguisherTypeId,
           TenantId,
           TypeCode,
           TypeName,
           Description,
           MonthlyInspectionRequired,
           AnnualInspectionRequired,
           HydrostaticTestYears,
           IsActive,
           CreatedDate,  
          -- Additional columns expected by service
          AgentType = NULL,
           Capacity = NULL,
           CapacityUnit = NULL,
           FireClassRating = NULL,
           ServiceLifeYears = NULL,
           HydroTestIntervalYears = HydrostaticTestYears,
           ModifiedDate = GETUTCDATE()
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes
    WHERE ExtinguisherTypeId=@ExtinguisherTypeId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetNeedingHydroTest] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetNeedingHydroTest]
      @TenantId UNIQUEIDENTIFIER, @TestIntervalYears INT = 5
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @CutoffDate DATE = DATEADD(YEAR, -@TestIntervalYears, GETUTCDATE());

    SELECT e.ExtinguisherId,
           e.AssetTag,
           e.LastHydrostaticTestDate,
           e.LocationDescription,
           l.LocationName,
           et.TypeName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId
          AND e.IsActive=1
          AND (e.LastHydrostaticTestDate IS NULL OR e.LastHydrostaticTestDate<@CutoffDate);
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetNeedingService] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[usp_Extinguisher_GetNeedingService];
GO

CREATE PROCEDURE [usp_Extinguisher_GetNeedingService]
      @TenantId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT e.ExtinguisherId,
           e.AssetTag,
           e.LocationDescription,
           l.LocationName,
           et.TypeName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.TenantId=@TenantId AND e.IsActive=0;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_MarkOutOfService] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_MarkOutOfService]
      @ExtinguisherId UNIQUEIDENTIFIER, @Reason NVARCHAR(500) = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers SET IsActive = 0, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId=@ExtinguisherId;

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_ReturnToService] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_ReturnToService]
      @ExtinguisherId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers SET IsActive = 1, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId=@ExtinguisherId;

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Delete] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Delete]
      @ExtinguisherId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers SET IsActive = 0, ModifiedDate = GETUTCDATE()
        WHERE ExtinguisherId=@ExtinguisherId;

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Update] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_Update]
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
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers SET LocationId = COALESCE(@LocationId, LocationId),
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
        WHERE ExtinguisherId=@ExtinguisherId;

        COMMIT TRANSACTION;

        SELECT 'SUCCESS' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION THROW;
    END CATCH;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetById] Script Date: 10/17/2025 1:53:00 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetById]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
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
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionTypes it
              ON i.InspectionTypeId=it.InspectionTypeId
    WHERE i.InspectionId=@InspectionId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetBySeverity] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetBySeverity]
      @TenantId UNIQUEIDENTIFIER, @Severity NVARCHAR(20)
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT d.DeficiencyId,
           d.InspectionId,
           d.DeficiencyType,
           d.Severity,
           d.Description,
           d.Status,
           d.ActionRequired,
           d.EstimatedCost,
           d.AssignedToUserId,
           d.DueDate,
           d.CreatedDate,
           i.ExtinguisherId,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies d
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
              ON d.InspectionId=i.InspectionId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId
          AND d.Severity=@Severity
          AND d.Status IN('Open', 'InProgress')
    ORDER BY d.CreatedDate DESC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetOpen] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetOpen]
      @TenantId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT d.DeficiencyId,
           d.InspectionId,
           d.DeficiencyType,
           d.Severity,
           d.Description,
           d.Status,
           d.ActionRequired,
           d.EstimatedCost,
           d.AssignedToUserId,
           d.DueDate,
           d.CreatedDate,
           i.ExtinguisherId,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies d
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
              ON d.InspectionId=i.InspectionId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId AND d.Status IN('Open', 'InProgress')
    ORDER BY d.Severity DESC, d.CreatedDate DESC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetByInspection] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT DeficiencyId,
           InspectionId,
           DeficiencyType,
           Severity,
           Description,
           Status,
           ActionRequired,
           EstimatedCost,
           AssignedToUserId,
           DueDate,
           ResolutionNotes,
           ResolvedDate,
           ResolvedByUserId,
           PhotoIds,
           CreatedDate,
           ModifiedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies
    WHERE InspectionId=@InspectionId
    ORDER BY Severity DESC, CreatedDate DESC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Resolve] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Resolve]
      @DeficiencyId UNIQUEIDENTIFIER, @ResolvedByUserId UNIQUEIDENTIFIER, @ResolutionNotes NVARCHAR(1000)
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies SET Status = 'Resolved',
                                                                                    ResolvedByUserId = @ResolvedByUserId,
                                                                                    ResolvedDate = GETUTCDATE(),
                                                                                    ResolutionNotes = @ResolutionNotes,
                                                                                    ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId=@DeficiencyId;

    SELECT DeficiencyId,
           Status,
           ResolvedByUserId,
           ResolvedDate,
           ResolutionNotes
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies
    WHERE DeficiencyId=@DeficiencyId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Update] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Update]
      @DeficiencyId UNIQUEIDENTIFIER,
      @Status NVARCHAR(20) = NULL,
      @ActionRequired NVARCHAR(500) = NULL,
      @EstimatedCost DECIMAL(10, 2) = NULL,
      @AssignedToUserId UNIQUEIDENTIFIER = NULL,
      @DueDate DATE = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies SET Status = ISNULL(@Status, Status),
                                                                                    ActionRequired = ISNULL(@ActionRequired, ActionRequired),
                                                                                    EstimatedCost = ISNULL(@EstimatedCost, EstimatedCost),
                                                                                    AssignedToUserId = ISNULL(@AssignedToUserId, AssignedToUserId),
                                                                                    DueDate = ISNULL(@DueDate, DueDate),
                                                                                    ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId=@DeficiencyId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Create] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionDeficiency_Create]
      @InspectionId UNIQUEIDENTIFIER,
      @DeficiencyType NVARCHAR(50),
      @Severity NVARCHAR(20),
      @Description NVARCHAR(1000),
      @ActionRequired NVARCHAR(500) = NULL,
      @EstimatedCost DECIMAL(10, 2) = NULL,
      @AssignedToUserId UNIQUEIDENTIFIER = NULL,
      @DueDate DATE = NULL,
      @PhotoIds NVARCHAR(MAX) = NULL,
      @DeficiencyId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @DeficiencyId = NEWID();

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies
    (  
       DeficiencyId,
       InspectionId,
       DeficiencyType,
       Severity,
       Description,
       Status,
       ActionRequired,
       EstimatedCost,
       AssignedToUserId,
       DueDate,
       PhotoIds,
       CreatedDate
    )
    VALUES (  
              @DeficiencyId,
              @InspectionId,
              @DeficiencyType,
              @Severity,
              @Description,
              'Open',
              @ActionRequired,
              @EstimatedCost,
              @AssignedToUserId,
              @DueDate,
              @PhotoIds,
              GETUTCDATE()
           );

    SELECT DeficiencyId,
           InspectionId,
           DeficiencyType,
           Severity,
           Description,
           Status,
           ActionRequired,
           EstimatedCost,
           AssignedToUserId,
           DueDate,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionDeficiencies
    WHERE DeficiencyId=@DeficiencyId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_GetByType] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_GetByType]
      @InspectionId UNIQUEIDENTIFIER, @PhotoType NVARCHAR(50)
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           Notes,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionPhotos
    WHERE InspectionId=@InspectionId AND PhotoType=@PhotoType
    ORDER BY CreatedDate ASC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_GetByInspection] Script Date: 10/17/2025 1:53:01 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           DeviceModel,
           Notes,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionPhotos
    WHERE InspectionId=@InspectionId
    ORDER BY CreatedDate ASC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_Create] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionPhoto_Create]
      @InspectionId UNIQUEIDENTIFIER,
      @PhotoType NVARCHAR(50),
      @BlobUrl NVARCHAR(500),
      @ThumbnailUrl NVARCHAR(500) = NULL,
      @FileSize BIGINT = NULL,
      @MimeType NVARCHAR(100) = NULL,
      @CaptureDate DATETIME2 = NULL,
      @Latitude DECIMAL(9, 6) = NULL,
      @Longitude DECIMAL(9, 6) = NULL,
      @DeviceModel NVARCHAR(200) = NULL,
      @EXIFData NVARCHAR(MAX) = NULL,
      @Notes NVARCHAR(500) = NULL,
      @PhotoId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @PhotoId = NEWID();

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionPhotos
    (  
       PhotoId,
       InspectionId,
       PhotoType,
       BlobUrl,
       ThumbnailUrl,
       FileSize,
       MimeType,
       CaptureDate,
       Latitude,
       Longitude,
       DeviceModel,
       EXIFData,
       Notes,
       CreatedDate
    )
    VALUES (  
              @PhotoId,
              @InspectionId,
              @PhotoType,
              @BlobUrl,
              @ThumbnailUrl,
              @FileSize,
              @MimeType,
              @CaptureDate,
              @Latitude,
              @Longitude,
              @DeviceModel,
              @EXIFData,
              @Notes,
              GETUTCDATE()
           );

    SELECT PhotoId,
           InspectionId,
           PhotoType,
           BlobUrl,
           ThumbnailUrl,
           FileSize,
           MimeType,
           CaptureDate,
           Latitude,
           Longitude,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionPhotos
    WHERE PhotoId=@PhotoId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionChecklistResponse_GetByInspection] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionChecklistResponse_GetByInspection]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT r.ResponseId,
           r.InspectionId,
           r.ChecklistItemId,
           r.Response,
           r.Comment,
           r.PhotoId,
           r.CreatedDate,
           i.ItemText,
           i.Category,
           i.[Order]
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionChecklistResponses r
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems i
              ON r.ChecklistItemId=i.ChecklistItemId
    WHERE r.InspectionId=@InspectionId
    ORDER BY i.[Order];
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ExtinguisherType_Create] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ExtinguisherType_Create]
      @TenantId UNIQUEIDENTIFIER,
      @TypeCode NVARCHAR(50),
      @TypeName NVARCHAR(200),
      @Description NVARCHAR(1000) = NULL,
      @AgentType NVARCHAR(100) = NULL,
      @Capacity DECIMAL(10, 2) = NULL,
      @CapacityUnit NVARCHAR(20) = NULL,
      @FireClassRating NVARCHAR(50) = NULL,
      @ServiceLifeYears INT = NULL,
      @HydroTestIntervalYears INT = NULL,
      @ExtinguisherTypeId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @ExtinguisherTypeId = NEWID();

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes
    (  
       ExtinguisherTypeId,
       TenantId,
       TypeCode,
       TypeName,
       Description,
       MonthlyInspectionRequired,
       AnnualInspectionRequired,
       HydrostaticTestYears,
       IsActive,
       CreatedDate
    )
    VALUES (  
              @ExtinguisherTypeId,
              @TenantId,
              @TypeCode,
              @TypeName,
              @Description,
              1,
              1,
              @HydroTestIntervalYears,
              1,
              GETUTCDATE()
           );

    SELECT ExtinguisherTypeId,
           TenantId,
           TypeCode,
           TypeName,
           Description,
           MonthlyInspectionRequired,
           AnnualInspectionRequired,
           HydrostaticTestYears,
           IsActive,
           CreatedDate,
           AgentType = @AgentType,
           Capacity = @Capacity,
           CapacityUnit = @CapacityUnit,
           FireClassRating = @FireClassRating,
           ServiceLifeYears = @ServiceLifeYears,
           HydroTestIntervalYears = HydrostaticTestYears,
           ModifiedDate = GETUTCDATE()
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes
    WHERE ExtinguisherTypeId=@ExtinguisherTypeId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetAll] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetAll]
      @TenantId UNIQUEIDENTIFIER = NULL, @IsActive BIT = 1
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
    WHERE (@TenantId IS NULL
            OR TenantId=@TenantId
            OR TenantId IS NULL) -- System templates + tenant templates

          AND (@IsActive IS NULL OR IsActive=@IsActive)
    ORDER BY InspectionType, TemplateName;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetByType] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetByType]
      @InspectionType NVARCHAR(50), @Standard NVARCHAR(50) = 'NFPA10'
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
           TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
    WHERE InspectionType=@InspectionType
          AND Standard=@Standard
          AND IsActive=1
          AND IsSystemTemplate=1 -- Prefer system templates

    ORDER BY IsSystemTemplate DESC, CreatedDate DESC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetById] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_GetById]
      @TemplateId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    -- Get template

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
    WHERE TemplateId=@TemplateId;

    -- Get items
    SELECT ChecklistItemId,
           TemplateId,
           ItemText,
           ItemDescription,
           [Order],
           Category,
           Required,
           RequiresPhoto,
           RequiresComment,
           PassFailNA,
           VisualAid,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems
    WHERE TemplateId=@TemplateId
    ORDER BY [Order];
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_Create] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistTemplate_Create]
      @TenantId UNIQUEIDENTIFIER,
      @TemplateName NVARCHAR(200),
      @InspectionType NVARCHAR(50),
      @Standard NVARCHAR(50),
      @Description NVARCHAR(1000) = NULL,
      @TemplateId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @TemplateId = NEWID();

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
    (  
       TemplateId,
       TenantId,
       TemplateName,
       InspectionType,
       Standard,
       IsSystemTemplate,
       IsActive,
       Description,
       CreatedDate
    )
    VALUES (  
              @TemplateId,
              @TenantId,
              @TemplateName,
              @InspectionType,
              @Standard,
              0,
              1,
              @Description,
              GETUTCDATE()
           );

    SELECT TemplateId,
           TenantId,
           TemplateName,
           InspectionType,
           Standard,
           IsSystemTemplate,
           IsActive,
           Description,
           CreatedDate,
           ModifiedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistTemplates
    WHERE TemplateId=@TemplateId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistItem_CreateBatch] Script Date: 10/17/2025 1:53:02 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_ChecklistItem_CreateBatch]
      @TemplateId UNIQUEIDENTIFIER, @ItemsJson NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of checklist items

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ChecklistItems
    (  
       TemplateId,
       ItemText,
       ItemDescription,
       [Order],
       Category,
       Required,
       RequiresPhoto,
       RequiresComment,
       PassFailNA,
       VisualAid,
       CreatedDate
    )
    SELECT @TemplateId,
           JSON_VALUE(value, '$.ItemText'),
           JSON_VALUE(value, '$.ItemDescription'),
           JSON_VALUE(value, '$.Order'),
           JSON_VALUE(value, '$.Category'),
           ISNULL(CAST(JSON_VALUE(value, '$.Required') AS BIT), 1),
           ISNULL(CAST(JSON_VALUE(value, '$.RequiresPhoto') AS BIT), 0),
           ISNULL(CAST(JSON_VALUE(value, '$.RequiresComment') AS BIT), 0),
           ISNULL(CAST(JSON_VALUE(value, '$.PassFailNA') AS BIT), 1),
           JSON_VALUE(value, '$.VisualAid'),
           GETUTCDATE()
    FROM OPENJSON(@ItemsJson);

    SELECT @@ROWCOUNT AS ItemsCreated;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetById] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER ON;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Extinguisher_GetById]
      @ExtinguisherId UNIQUEIDENTIFIER
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
           e.CreatedDate,
           e.ModifiedDate,
           l.LocationName,
           l.LocationCode,
           et.TypeName,
           et.TypeCode
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    INNER JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].ExtinguisherTypes et
              ON e.ExtinguisherTypeId=et.ExtinguisherTypeId
    WHERE e.ExtinguisherId=@ExtinguisherId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Create] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Create]
      @TenantId UNIQUEIDENTIFIER,
      @ExtinguisherId UNIQUEIDENTIFIER,
      @InspectorUserId UNIQUEIDENTIFIER,
      @InspectionType NVARCHAR(50),
      @ScheduledDate DATETIME2 = NULL,
      @InspectionId UNIQUEIDENTIFIER OUTPUT
AS 
BEGIN
    SET NOCOUNT ON;

    SET @InspectionId = NEWID();

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    (  
       InspectionId,
       TenantId,
       ExtinguisherId,
       InspectorUserId,
       InspectionType,
       InspectionDate,
       ScheduledDate,
       Status,
       CreatedDate
    )
    VALUES (  
              @InspectionId,
              @TenantId,
              @ExtinguisherId,
              @InspectorUserId,
              @InspectionType,
              GETUTCDATE(),
              @ScheduledDate,
              'Scheduled',
              GETUTCDATE()
           );

    SELECT InspectionId,
           TenantId,
           ExtinguisherId,
           InspectorUserId,
           InspectionType,
           InspectionDate,
           ScheduledDate,
           Status,
           CreatedDate
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    WHERE InspectionId=@InspectionId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Complete] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Complete]
      @InspectionId UNIQUEIDENTIFIER,
      @InspectorSignature NVARCHAR(MAX),
      @InspectionHash NVARCHAR(256),
      @PreviousInspectionHash NVARCHAR(256) = NULL,
      @OverallPass BIT,
      @DeficiencyCount INT
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections SET Status = 'Completed',
                                                                         InspectorSignature = @InspectorSignature,
                                                                         CompletedTime = GETUTCDATE(),
                                                                         DurationSeconds = DATEDIFF(SECOND, StartTime, GETUTCDATE()),
                                                                         InspectionHash = @InspectionHash,
                                                                         PreviousInspectionHash = @PreviousInspectionHash,
                                                                         HashVerified = CASE
                                                                                            WHEN @PreviousInspectionHash IS NOT NULL THEN 1
                                                                                            ELSE NULL
                                                                                        END,
                                                                         OverallPass = @OverallPass,
                                                                         DeficiencyCount = @DeficiencyCount,
                                                                         ModifiedDate = GETUTCDATE()
    WHERE InspectionId=@InspectionId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetByDate] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetByDate]
      @TenantId UNIQUEIDENTIFIER, @StartDate DATETIME2, @EndDate DATETIME2
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.ExtinguisherId,
           i.InspectorUserId,
           i.InspectionType,
           i.InspectionDate,
           i.Status,
           i.OverallPass,
           i.DeficiencyCount,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId AND i.InspectionDate BETWEEN @StartDate AND @EndDate
    ORDER BY i.InspectionDate DESC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetDue] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetDue]
      @TenantId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    -- Get extinguishers with overdue inspections

    SELECT e.ExtinguisherId,
           e.AssetTag,
           e.BarcodeData,
           e.NextServiceDueDate,
           l.LocationName,
           l.LocationId,
           DATEDIFF(DAY, e.NextServiceDueDate, GETUTCDATE()) AS DaysOverdue
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    WHERE e.TenantId=@TenantId
          AND e.IsActive=1
          AND e.NextServiceDueDate<GETUTCDATE()
    ORDER BY e.NextServiceDueDate ASC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetScheduled] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_GetScheduled]
      @TenantId UNIQUEIDENTIFIER, @DaysAhead INT = 30
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT i.InspectionId,
           i.ExtinguisherId,
           i.InspectorUserId,
           i.InspectionType,
           i.ScheduledDate,
           i.Status,
           e.AssetTag,
           e.BarcodeData,
           l.LocationName
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections i
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Extinguishers e
              ON i.ExtinguisherId=e.ExtinguisherId
    LEFT JOIN [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Locations l
              ON e.LocationId=l.LocationId
    WHERE i.TenantId=@TenantId
          AND i.Status IN('Scheduled', 'InProgress')
          AND i.ScheduledDate BETWEEN GETUTCDATE() AND DATEADD(DAY, @DaysAhead, GETUTCDATE())
    ORDER BY i.ScheduledDate ASC;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_VerifyHash] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_VerifyHash]
      @InspectionId UNIQUEIDENTIFIER
AS 
BEGIN
    SET NOCOUNT ON;

    SELECT InspectionId,
           InspectionHash,
           PreviousInspectionHash,
           HashVerified,
           ExtinguisherId,
           InspectionDate,
           Status
    FROM [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections
    WHERE InspectionId=@InspectionId;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionChecklistResponse_CreateBatch] Script Date: 10/17/2025 1:53:03 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_InspectionChecklistResponse_CreateBatch]
      @InspectionId UNIQUEIDENTIFIER, @ResponsesJson NVARCHAR(MAX)
AS 
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of responses

    INSERT [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].InspectionChecklistResponses
    (  
       InspectionId,
       ChecklistItemId,
       Response,
       Comment,
       PhotoId,
       CreatedDate
    )
    SELECT @InspectionId,
           CAST(JSON_VALUE(value, '$.ChecklistItemId') AS UNIQUEIDENTIFIER),
           JSON_VALUE(value, '$.Response'),
           JSON_VALUE(value, '$.Comment'),
           CAST(JSON_VALUE(value, '$.PhotoId') AS UNIQUEIDENTIFIER),
           GETUTCDATE()
    FROM OPENJSON(@ResponsesJson);

    SELECT @@ROWCOUNT AS ResponsesCreated;
END;

GO

/****** Object: StoredProcedure [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Update] Script Date: 10/17/2025 1:53:04 PM ******/
SET ANSI_NULLS ON;

GO

SET QUOTED_IDENTIFIER OFF;

GO

DROP PROCEDURE IF EXISTS dbo.[tenant_634F2B52];
GO

CREATE PROCEDURE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].[usp_Inspection_Update]
      @InspectionId UNIQUEIDENTIFIER,
      @Status NVARCHAR(50) = NULL,
      @Latitude DECIMAL(9, 6) = NULL,
      @Longitude DECIMAL(9, 6) = NULL,
      @LocationAccuracy DECIMAL(10, 2) = NULL,
      @PhysicalConditionPass BIT = NULL,
      @PhysicalConditionNotes NVARCHAR(500) = NULL,
      @PressureCheckPass BIT = NULL,
      @PressureReading NVARCHAR(50) = NULL,
      @OverallPass BIT = NULL
AS 
BEGIN
    SET NOCOUNT ON;

    UPDATE [tenant_634F2B52-D32A-46DD-A045-D158E793ADCB].Inspections SET Status = ISNULL(@Status, Status),
                                                                         Latitude = ISNULL(@Latitude, Latitude),
                                                                         Longitude = ISNULL(@Longitude, Longitude),
                                                                         LocationAccuracy = ISNULL(@LocationAccuracy, LocationAccuracy),
                                                                         PhysicalConditionPass = ISNULL(@PhysicalConditionPass, PhysicalConditionPass),
                                                                         PhysicalConditionNotes = ISNULL(@PhysicalConditionNotes, PhysicalConditionNotes),
                                                                         PressureCheckPass = ISNULL(@PressureCheckPass, PressureCheckPass),
                                                                         PressureReading = ISNULL(@PressureReading, PressureReading),
                                                                         OverallPass = ISNULL(@OverallPass, OverallPass),
                                                                         ModifiedDate = GETUTCDATE()
    WHERE InspectionId=@InspectionId;
END;

GO