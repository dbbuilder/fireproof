-- =============================================
-- Corrected Stored Procedures with TenantId RLS
-- Date: 2025-10-17
-- Purpose: Update procedures with correct column names from actual schema
-- =============================================

USE FireProofDB;
GO

PRINT 'Updating stored procedures with correct column names and TenantId filtering...';
GO

-- =============================================
-- ChecklistTemplate Procedures
-- =============================================

PRINT 'Updating usp_ChecklistTemplate_GetById...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_ChecklistTemplate_GetById];
GO
CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetById]
    @TemplateId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
    FROM dbo.ChecklistTemplates
    WHERE TemplateId = @TemplateId
        AND TenantId = @TenantId;
END;
GO

PRINT 'Updating usp_ChecklistTemplate_GetByType...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_ChecklistTemplate_GetByType];
GO
CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetByType]
    @InspectionType NVARCHAR(100),
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
    FROM dbo.ChecklistTemplates
    WHERE InspectionType = @InspectionType
        AND TenantId = @TenantId
        AND IsActive = 1;
END;
GO

-- =============================================
-- Extinguisher Procedures
-- =============================================

PRINT 'Updating usp_Extinguisher_GetById...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_Extinguisher_GetById];
GO
CREATE PROCEDURE [dbo].[usp_Extinguisher_GetById]
    @ExtinguisherId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

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
        e.ModifiedDate
    FROM dbo.Extinguishers e
    WHERE e.ExtinguisherId = @ExtinguisherId
        AND e.TenantId = @TenantId;
END;
GO

-- =============================================
-- Inspection Procedures
-- =============================================

PRINT 'Updating usp_Inspection_GetById...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_Inspection_GetById];
GO
CREATE PROCEDURE [dbo].[usp_Inspection_GetById]
    @InspectionId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.InspectionId,
        i.TenantId,
        i.ExtinguisherId,
        i.InspectionTypeId,
        i.InspectorUserId,
        i.InspectionDate,
        i.Passed,
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
        i.InspectionTagAttached,
        i.RequiresService,
        i.RequiresReplacement,
        i.Notes,
        i.FailureReason,
        i.CorrectiveAction,
        i.GpsLatitude,
        i.GpsLongitude,
        i.DeviceId,
        i.TamperProofHash,
        i.PreviousInspectionHash,
        i.CreatedDate,
        i.InspectionType,
        i.GpsAccuracyMeters,
        i.LocationVerified,
        i.DamageDescription,
        i.WeightPounds,
        i.WeightWithinSpec,
        i.PreviousInspectionDate,
        i.PhotoUrls,
        i.DataHash,
        i.InspectorSignature,
        i.SignedDate,
        i.IsVerified,
        i.ModifiedDate
    FROM dbo.Inspections i
    WHERE i.InspectionId = @InspectionId
        AND i.TenantId = @TenantId;
END;
GO

-- =============================================
-- InspectionChecklistResponse Procedures
-- =============================================

PRINT 'Updating usp_InspectionChecklistResponse_GetByInspection...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionChecklistResponse_GetByInspection];
GO
CREATE PROCEDURE [dbo].[usp_InspectionChecklistResponse_GetByInspection]
    @InspectionId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ResponseId,
        InspectionId,
        ChecklistItemId,
        Response,
        Comment,
        PhotoId,
        CreatedDate,
        TenantId
    FROM dbo.InspectionChecklistResponses
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

-- =============================================
-- InspectionDeficiency Procedures
-- =============================================

PRINT 'Updating usp_InspectionDeficiency_Create...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionDeficiency_Create];
GO
CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Create]
    @DeficiencyId UNIQUEIDENTIFIER OUTPUT,
    @InspectionId UNIQUEIDENTIFIER,
    @DeficiencyType NVARCHAR(100),
    @Severity NVARCHAR(50),
    @Description NVARCHAR(MAX),
    @ActionRequired NVARCHAR(MAX) = NULL,
    @EstimatedCost DECIMAL(10,2) = NULL,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @DeficiencyId IS NULL
        SET @DeficiencyId = NEWID();

    INSERT INTO dbo.InspectionDeficiencies (
        DeficiencyId,
        InspectionId,
        DeficiencyType,
        Severity,
        Description,
        Status,
        ActionRequired,
        EstimatedCost,
        TenantId,
        CreatedDate,
        ModifiedDate
    ) VALUES (
        @DeficiencyId,
        @InspectionId,
        @DeficiencyType,
        @Severity,
        @Description,
        'Open',
        @ActionRequired,
        @EstimatedCost,
        @TenantId,
        GETUTCDATE(),
        GETUTCDATE()
    );

    SELECT @DeficiencyId AS DeficiencyId;
END;
GO

PRINT 'Updating usp_InspectionDeficiency_GetByInspection...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionDeficiency_GetByInspection];
GO
CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_GetByInspection]
    @InspectionId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
        ResolutionNotes,
        ResolvedDate,
        ResolvedByUserId,
        PhotoIds,
        TenantId,
        CreatedDate,
        ModifiedDate
    FROM dbo.InspectionDeficiencies
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

PRINT 'Updating usp_InspectionDeficiency_Resolve...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionDeficiency_Resolve];
GO
CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Resolve]
    @DeficiencyId UNIQUEIDENTIFIER,
    @ResolvedByUserId UNIQUEIDENTIFIER,
    @ResolutionNotes NVARCHAR(MAX) = NULL,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.InspectionDeficiencies
    SET
        Status = 'Resolved',
        ResolvedDate = GETUTCDATE(),
        ResolvedByUserId = @ResolvedByUserId,
        ResolutionNotes = @ResolutionNotes,
        ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId = @DeficiencyId
        AND TenantId = @TenantId;
END;
GO

-- =============================================
-- InspectionPhoto Procedures
-- =============================================

PRINT 'Updating usp_InspectionPhoto_Create...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionPhoto_Create];
GO
CREATE PROCEDURE [dbo].[usp_InspectionPhoto_Create]
    @PhotoId UNIQUEIDENTIFIER OUTPUT,
    @InspectionId UNIQUEIDENTIFIER,
    @PhotoType NVARCHAR(50),
    @BlobUrl NVARCHAR(500),
    @ThumbnailUrl NVARCHAR(500) = NULL,
    @FileSize BIGINT = NULL,
    @MimeType NVARCHAR(100) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @PhotoId IS NULL
        SET @PhotoId = NEWID();

    INSERT INTO dbo.InspectionPhotos (
        PhotoId,
        InspectionId,
        PhotoType,
        BlobUrl,
        ThumbnailUrl,
        FileSize,
        MimeType,
        CaptureDate,
        Notes,
        TenantId,
        CreatedDate
    ) VALUES (
        @PhotoId,
        @InspectionId,
        @PhotoType,
        @BlobUrl,
        @ThumbnailUrl,
        @FileSize,
        @MimeType,
        GETUTCDATE(),
        @Notes,
        @TenantId,
        GETUTCDATE()
    );

    SELECT @PhotoId AS PhotoId;
END;
GO

PRINT 'Updating usp_InspectionPhoto_GetByInspection...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionPhoto_GetByInspection];
GO
CREATE PROCEDURE [dbo].[usp_InspectionPhoto_GetByInspection]
    @InspectionId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
        TenantId,
        CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

PRINT 'Updating usp_InspectionPhoto_GetByType...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionPhoto_GetByType];
GO
CREATE PROCEDURE [dbo].[usp_InspectionPhoto_GetByType]
    @InspectionId UNIQUEIDENTIFIER,
    @PhotoType NVARCHAR(50),
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
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
        TenantId,
        CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId = @InspectionId
        AND PhotoType = @PhotoType
        AND TenantId = @TenantId;
END;
GO

-- =============================================
-- Location Procedures
-- =============================================

PRINT 'Updating usp_Location_GetById...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_Location_GetById];
GO
CREATE PROCEDURE [dbo].[usp_Location_GetById]
    @LocationId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

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
        ContactName,
        ContactPhone,
        ContactEmail,
        IsActive,
        CreatedDate,
        ModifiedDate,
        Latitude,
        Longitude,
        LocationBarcodeData
    FROM dbo.Locations
    WHERE LocationId = @LocationId
        AND TenantId = @TenantId;
END;
GO

-- =============================================
-- UserTenantRole Procedures
-- =============================================

PRINT 'Updating usp_UserTenantRole_GetByUser...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_UserTenantRole_GetByUser];
GO
CREATE PROCEDURE [dbo].[usp_UserTenantRole_GetByUser]
    @UserId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        utr.UserTenantRoleId,
        utr.UserId,
        utr.TenantId,
        utr.RoleName,
        utr.IsActive,
        utr.CreatedDate,
        t.CompanyName AS TenantName,
        t.SubscriptionTier
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId
        AND utr.TenantId = @TenantId;
END;
GO

PRINT 'All stored procedures updated successfully!';
PRINT '';
PRINT 'Summary:';
PRINT '- Updated 13 stored procedures with TenantId RLS filtering';
PRINT '- Corrected all column names to match actual database schema';
PRINT '- All procedures now include @TenantId parameter';
PRINT '- All queries filter by TenantId for data isolation';
GO
