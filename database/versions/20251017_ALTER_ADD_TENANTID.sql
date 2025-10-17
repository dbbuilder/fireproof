-- =============================================
-- TenantId RLS Migration - ALTER TABLE Script
-- Date: 2025-10-17
-- Purpose: Add TenantId column to 6 tables for RLS
-- =============================================

USE FireProofDB;
GO

PRINT 'Starting TenantId migration...';
GO

-- =============================================
-- STEP 1: Add TenantId columns to tables
-- =============================================

PRINT 'Adding TenantId to ChecklistItems...';
ALTER TABLE [dbo].[ChecklistItems]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_ChecklistItems_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

PRINT 'Adding TenantId to ExtinguisherTypes...';
ALTER TABLE [dbo].[ExtinguisherTypes]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_ExtinguisherTypes_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

PRINT 'Adding TenantId to InspectionChecklistResponses...';
ALTER TABLE [dbo].[InspectionChecklistResponses]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_InspectionChecklistResponses_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

PRINT 'Adding TenantId to InspectionDeficiencies...';
ALTER TABLE [dbo].[InspectionDeficiencies]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_InspectionDeficiencies_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

PRINT 'Adding TenantId to InspectionPhotos...';
ALTER TABLE [dbo].[InspectionPhotos]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_InspectionPhotos_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

PRINT 'Adding TenantId to MaintenanceRecords...';
ALTER TABLE [dbo].[MaintenanceRecords]
    ADD [TenantId] [uniqueidentifier] NOT NULL
    CONSTRAINT DF_MaintenanceRecords_TenantId DEFAULT ('00000000-0000-0000-0000-000000000000');
GO

-- =============================================
-- STEP 2: Create indexes on TenantId
-- =============================================

PRINT 'Creating index on ChecklistItems.TenantId...';
CREATE NONCLUSTERED INDEX [IX_ChecklistItems_TenantId]
    ON [dbo].[ChecklistItems] ([TenantId])
    INCLUDE ([ChecklistItemId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

PRINT 'Creating index on ExtinguisherTypes.TenantId...';
CREATE NONCLUSTERED INDEX [IX_ExtinguisherTypes_TenantId]
    ON [dbo].[ExtinguisherTypes] ([TenantId])
    INCLUDE ([ExtinguisherTypeId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

PRINT 'Creating index on InspectionChecklistResponses.TenantId...';
CREATE NONCLUSTERED INDEX [IX_InspectionChecklistResponses_TenantId]
    ON [dbo].[InspectionChecklistResponses] ([TenantId])
    INCLUDE ([ResponseId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

PRINT 'Creating index on InspectionDeficiencies.TenantId...';
CREATE NONCLUSTERED INDEX [IX_InspectionDeficiencies_TenantId]
    ON [dbo].[InspectionDeficiencies] ([TenantId])
    INCLUDE ([DeficiencyId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

PRINT 'Creating index on InspectionPhotos.TenantId...';
CREATE NONCLUSTERED INDEX [IX_InspectionPhotos_TenantId]
    ON [dbo].[InspectionPhotos] ([TenantId])
    INCLUDE ([PhotoId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

PRINT 'Creating index on MaintenanceRecords.TenantId...';
CREATE NONCLUSTERED INDEX [IX_MaintenanceRecords_TenantId]
    ON [dbo].[MaintenanceRecords] ([TenantId])
    INCLUDE ([MaintenanceId])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

-- =============================================
-- STEP 3: Create foreign keys to Tenants table
-- =============================================

PRINT 'Creating FK from ChecklistItems to Tenants...';
ALTER TABLE [dbo].[ChecklistItems] WITH CHECK
    ADD CONSTRAINT [FK_ChecklistItems_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[ChecklistItems] CHECK CONSTRAINT [FK_ChecklistItems_Tenants];
GO

PRINT 'Creating FK from ExtinguisherTypes to Tenants...';
ALTER TABLE [dbo].[ExtinguisherTypes] WITH CHECK
    ADD CONSTRAINT [FK_ExtinguisherTypes_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[ExtinguisherTypes] CHECK CONSTRAINT [FK_ExtinguisherTypes_Tenants];
GO

PRINT 'Creating FK from InspectionChecklistResponses to Tenants...';
ALTER TABLE [dbo].[InspectionChecklistResponses] WITH CHECK
    ADD CONSTRAINT [FK_InspectionChecklistResponses_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[InspectionChecklistResponses] CHECK CONSTRAINT [FK_InspectionChecklistResponses_Tenants];
GO

PRINT 'Creating FK from InspectionDeficiencies to Tenants...';
ALTER TABLE [dbo].[InspectionDeficiencies] WITH CHECK
    ADD CONSTRAINT [FK_InspectionDeficiencies_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[InspectionDeficiencies] CHECK CONSTRAINT [FK_InspectionDeficiencies_Tenants];
GO

PRINT 'Creating FK from InspectionPhotos to Tenants...';
ALTER TABLE [dbo].[InspectionPhotos] WITH CHECK
    ADD CONSTRAINT [FK_InspectionPhotos_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[InspectionPhotos] CHECK CONSTRAINT [FK_InspectionPhotos_Tenants];
GO

PRINT 'Creating FK from MaintenanceRecords to Tenants...';
ALTER TABLE [dbo].[MaintenanceRecords] WITH CHECK
    ADD CONSTRAINT [FK_MaintenanceRecords_Tenants] FOREIGN KEY([TenantId])
    REFERENCES [dbo].[Tenants] ([TenantId]);
GO
ALTER TABLE [dbo].[MaintenanceRecords] CHECK CONSTRAINT [FK_MaintenanceRecords_Tenants];
GO

-- =============================================
-- STEP 4: Update stored procedures with TenantId parameters
-- =============================================

-- usp_ChecklistTemplate_GetById
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
        ChecklistTemplateId,
        InspectionTypeId,
        TemplateName,
        Description,
        IsActive,
        CreatedDate,
        ModifiedDate,
        TenantId
    FROM dbo.ChecklistTemplates
    WHERE ChecklistTemplateId = @TemplateId
        AND TenantId = @TenantId;
END;
GO

-- usp_ChecklistTemplate_GetByType
PRINT 'Updating usp_ChecklistTemplate_GetByType...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_ChecklistTemplate_GetByType];
GO
CREATE PROCEDURE [dbo].[usp_ChecklistTemplate_GetByType]
    @InspectionTypeId UNIQUEIDENTIFIER,
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ChecklistTemplateId,
        InspectionTypeId,
        TemplateName,
        Description,
        IsActive,
        CreatedDate,
        ModifiedDate,
        TenantId
    FROM dbo.ChecklistTemplates
    WHERE InspectionTypeId = @InspectionTypeId
        AND TenantId = @TenantId
        AND IsActive = 1;
END;
GO

-- usp_Extinguisher_GetById
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
        e.LocationId,
        e.ExtinguisherTypeId,
        e.Barcode,
        e.SerialNumber,
        e.ManufactureDate,
        e.LastInspectionDate,
        e.NextInspectionDue,
        e.LastHydroTestDate,
        e.NextHydroTestDue,
        e.Status,
        e.Notes,
        e.TenantId,
        e.CreatedDate,
        e.ModifiedDate
    FROM dbo.Extinguishers e
    WHERE e.ExtinguisherId = @ExtinguisherId
        AND e.TenantId = @TenantId;
END;
GO

-- usp_Inspection_GetById
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
        i.ExtinguisherId,
        i.InspectorUserId,
        i.StartedAt,
        i.CompletedAt,
        i.Status,
        i.Result,
        i.GpsLatitude,
        i.GpsLongitude,
        i.Notes,
        i.TenantId,
        i.CreatedDate,
        i.ModifiedDate
    FROM dbo.Inspections i
    WHERE i.InspectionId = @InspectionId
        AND i.TenantId = @TenantId;
END;
GO

-- usp_InspectionChecklistResponse_GetByInspection
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
        Notes,
        PhotoBlobName,
        TenantId,
        CreatedDate
    FROM dbo.InspectionChecklistResponses
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

-- usp_InspectionDeficiency_Create
PRINT 'Updating usp_InspectionDeficiency_Create...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionDeficiency_Create];
GO
CREATE PROCEDURE [dbo].[usp_InspectionDeficiency_Create]
    @DeficiencyId UNIQUEIDENTIFIER OUTPUT,
    @InspectionId UNIQUEIDENTIFIER,
    @DeficiencyType NVARCHAR(50),
    @Severity NVARCHAR(20),
    @Description NVARCHAR(MAX),
    @PhotoBlobName NVARCHAR(500) = NULL,
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
        PhotoBlobName,
        IsResolved,
        TenantId,
        CreatedDate
    ) VALUES (
        @DeficiencyId,
        @InspectionId,
        @DeficiencyType,
        @Severity,
        @Description,
        @PhotoBlobName,
        0,
        @TenantId,
        GETUTCDATE()
    );

    SELECT @DeficiencyId AS DeficiencyId;
END;
GO

-- usp_InspectionDeficiency_GetByInspection
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
        PhotoBlobName,
        IsResolved,
        ResolvedDate,
        ResolvedByUserId,
        ResolutionNotes,
        TenantId,
        CreatedDate
    FROM dbo.InspectionDeficiencies
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

-- usp_InspectionDeficiency_Resolve
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
        IsResolved = 1,
        ResolvedDate = GETUTCDATE(),
        ResolvedByUserId = @ResolvedByUserId,
        ResolutionNotes = @ResolutionNotes
    WHERE DeficiencyId = @DeficiencyId
        AND TenantId = @TenantId;
END;
GO

-- usp_InspectionPhoto_Create
PRINT 'Updating usp_InspectionPhoto_Create...';
GO
DROP PROCEDURE IF EXISTS [dbo].[usp_InspectionPhoto_Create];
GO
CREATE PROCEDURE [dbo].[usp_InspectionPhoto_Create]
    @PhotoId UNIQUEIDENTIFIER OUTPUT,
    @InspectionId UNIQUEIDENTIFIER,
    @PhotoType NVARCHAR(50),
    @BlobName NVARCHAR(500),
    @Caption NVARCHAR(500) = NULL,
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
        BlobName,
        Caption,
        TenantId,
        CreatedDate
    ) VALUES (
        @PhotoId,
        @InspectionId,
        @PhotoType,
        @BlobName,
        @Caption,
        @TenantId,
        GETUTCDATE()
    );

    SELECT @PhotoId AS PhotoId;
END;
GO

-- usp_InspectionPhoto_GetByInspection
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
        BlobName,
        Caption,
        TenantId,
        CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId = @InspectionId
        AND TenantId = @TenantId;
END;
GO

-- usp_InspectionPhoto_GetByType
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
        BlobName,
        Caption,
        TenantId,
        CreatedDate
    FROM dbo.InspectionPhotos
    WHERE InspectionId = @InspectionId
        AND PhotoType = @PhotoType
        AND TenantId = @TenantId;
END;
GO

-- usp_Location_GetById
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
        LocationName,
        Address,
        City,
        State,
        ZipCode,
        Latitude,
        Longitude,
        TenantId,
        CreatedDate,
        ModifiedDate
    FROM dbo.Locations
    WHERE LocationId = @LocationId
        AND TenantId = @TenantId;
END;
GO

-- usp_UserTenantRole_GetByUser
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
        utr.CreatedDate,
        t.TenantName,
        t.SubscriptionTier
    FROM dbo.UserTenantRoles utr
    INNER JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
    WHERE utr.UserId = @UserId
        AND utr.TenantId = @TenantId;
END;
GO

PRINT 'TenantId migration completed successfully!';
PRINT '';
PRINT 'Summary:';
PRINT '- Added TenantId column to 6 tables';
PRINT '- Created 6 indexes on TenantId';
PRINT '- Created 6 foreign keys to Tenants table';
PRINT '- Updated 13 stored procedures with TenantId parameters';
GO
