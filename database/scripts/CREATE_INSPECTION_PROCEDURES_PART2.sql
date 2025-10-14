/*============================================================================
  File:     CREATE_INSPECTION_PROCEDURES_PART2.sql
  Purpose:  Create remaining inspection stored procedures (Part 2)
  Date:     October 14, 2025

  Procedures Created: 11
    - InspectionChecklistResponse procedures (2)
    - InspectionPhoto procedures (3)
    - InspectionDeficiency procedures (6)
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Remaining Inspection Procedures (Part 2)'
PRINT '============================================================================'
PRINT ''

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'

-- ============================================================================
-- INSPECTION CHECKLIST RESPONSE PROCEDURES (2)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT '3. InspectionChecklistResponse Procedures'
PRINT '------------------------------------------------------------------------'

-- 3.1 usp_InspectionChecklistResponse_CreateBatch
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionChecklistResponse_CreateBatch' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionChecklistResponse_CreateBatch')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionChecklistResponse_CreateBatch
    @InspectionId UNIQUEIDENTIFIER,
    @ResponsesJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of responses
    INSERT INTO [' + @Schema + '].InspectionChecklistResponses (
        InspectionId, ChecklistItemId, Response, Comment, PhotoId, CreatedDate
    )
    SELECT
        @InspectionId,
        CAST(JSON_VALUE(value, ''$.ChecklistItemId'') AS UNIQUEIDENTIFIER),
        JSON_VALUE(value, ''$.Response''),
        JSON_VALUE(value, ''$.Comment''),
        CAST(JSON_VALUE(value, ''$.PhotoId'') AS UNIQUEIDENTIFIER),
        GETUTCDATE()
    FROM OPENJSON(@ResponsesJson)

    SELECT @@ROWCOUNT as ResponsesCreated
END
')
PRINT '  ✓ usp_InspectionChecklistResponse_CreateBatch'

-- 3.2 usp_InspectionChecklistResponse_GetByInspection
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionChecklistResponse_GetByInspection' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionChecklistResponse_GetByInspection')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionChecklistResponse_GetByInspection
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.ResponseId,
        r.InspectionId,
        r.ChecklistItemId,
        r.Response,
        r.Comment,
        r.PhotoId,
        r.CreatedDate,
        i.ItemText,
        i.Category,
        i.[Order]
    FROM [' + @Schema + '].InspectionChecklistResponses r
    LEFT JOIN [' + @Schema + '].ChecklistItems i ON r.ChecklistItemId = i.ChecklistItemId
    WHERE r.InspectionId = @InspectionId
    ORDER BY i.[Order]
END
')
PRINT '  ✓ usp_InspectionChecklistResponse_GetByInspection'
PRINT ''

-- ============================================================================
-- INSPECTION PHOTO PROCEDURES (3)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT '4. InspectionPhoto Procedures'
PRINT '------------------------------------------------------------------------'

-- 4.1 usp_InspectionPhoto_Create
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionPhoto_Create' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionPhoto_Create')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionPhoto_Create
    @InspectionId UNIQUEIDENTIFIER,
    @PhotoType NVARCHAR(50),
    @BlobUrl NVARCHAR(500),
    @ThumbnailUrl NVARCHAR(500) = NULL,
    @FileSize BIGINT = NULL,
    @MimeType NVARCHAR(100) = NULL,
    @CaptureDate DATETIME2 = NULL,
    @Latitude DECIMAL(9,6) = NULL,
    @Longitude DECIMAL(9,6) = NULL,
    @DeviceModel NVARCHAR(200) = NULL,
    @EXIFData NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(500) = NULL,
    @PhotoId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @PhotoId = NEWID()

    INSERT INTO [' + @Schema + '].InspectionPhotos (
        PhotoId, InspectionId, PhotoType, BlobUrl, ThumbnailUrl,
        FileSize, MimeType, CaptureDate, Latitude, Longitude,
        DeviceModel, EXIFData, Notes, CreatedDate
    )
    VALUES (
        @PhotoId, @InspectionId, @PhotoType, @BlobUrl, @ThumbnailUrl,
        @FileSize, @MimeType, @CaptureDate, @Latitude, @Longitude,
        @DeviceModel, @EXIFData, @Notes, GETUTCDATE()
    )

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
        CreatedDate
    FROM [' + @Schema + '].InspectionPhotos
    WHERE PhotoId = @PhotoId
END
')
PRINT '  ✓ usp_InspectionPhoto_Create'

-- 4.2 usp_InspectionPhoto_GetByInspection
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionPhoto_GetByInspection' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionPhoto_GetByInspection')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionPhoto_GetByInspection
    @InspectionId UNIQUEIDENTIFIER
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
        Notes,
        CreatedDate
    FROM [' + @Schema + '].InspectionPhotos
    WHERE InspectionId = @InspectionId
    ORDER BY CreatedDate ASC
END
')
PRINT '  ✓ usp_InspectionPhoto_GetByInspection'

-- 4.3 usp_InspectionPhoto_GetByType
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionPhoto_GetByType' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionPhoto_GetByType')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionPhoto_GetByType
    @InspectionId UNIQUEIDENTIFIER,
    @PhotoType NVARCHAR(50)
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
        Notes,
        CreatedDate
    FROM [' + @Schema + '].InspectionPhotos
    WHERE InspectionId = @InspectionId
        AND PhotoType = @PhotoType
    ORDER BY CreatedDate ASC
END
')
PRINT '  ✓ usp_InspectionPhoto_GetByType'
PRINT ''

-- ============================================================================
-- INSPECTION DEFICIENCY PROCEDURES (6)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT '5. InspectionDeficiency Procedures'
PRINT '------------------------------------------------------------------------'

-- 5.1 usp_InspectionDeficiency_Create
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_Create' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Create')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Create
    @InspectionId UNIQUEIDENTIFIER,
    @DeficiencyType NVARCHAR(50),
    @Severity NVARCHAR(20),
    @Description NVARCHAR(1000),
    @ActionRequired NVARCHAR(500) = NULL,
    @EstimatedCost DECIMAL(10,2) = NULL,
    @AssignedToUserId UNIQUEIDENTIFIER = NULL,
    @DueDate DATE = NULL,
    @PhotoIds NVARCHAR(MAX) = NULL,
    @DeficiencyId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @DeficiencyId = NEWID()

    INSERT INTO [' + @Schema + '].InspectionDeficiencies (
        DeficiencyId, InspectionId, DeficiencyType, Severity, Description,
        Status, ActionRequired, EstimatedCost, AssignedToUserId, DueDate,
        PhotoIds, CreatedDate
    )
    VALUES (
        @DeficiencyId, @InspectionId, @DeficiencyType, @Severity, @Description,
        ''Open'', @ActionRequired, @EstimatedCost, @AssignedToUserId, @DueDate,
        @PhotoIds, GETUTCDATE()
    )

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
        CreatedDate
    FROM [' + @Schema + '].InspectionDeficiencies
    WHERE DeficiencyId = @DeficiencyId
END
')
PRINT '  ✓ usp_InspectionDeficiency_Create'

-- 5.2 usp_InspectionDeficiency_Update
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_Update' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Update')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Update
    @DeficiencyId UNIQUEIDENTIFIER,
    @Status NVARCHAR(20) = NULL,
    @ActionRequired NVARCHAR(500) = NULL,
    @EstimatedCost DECIMAL(10,2) = NULL,
    @AssignedToUserId UNIQUEIDENTIFIER = NULL,
    @DueDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [' + @Schema + '].InspectionDeficiencies
    SET
        Status = ISNULL(@Status, Status),
        ActionRequired = ISNULL(@ActionRequired, ActionRequired),
        EstimatedCost = ISNULL(@EstimatedCost, EstimatedCost),
        AssignedToUserId = ISNULL(@AssignedToUserId, AssignedToUserId),
        DueDate = ISNULL(@DueDate, DueDate),
        ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId = @DeficiencyId
END
')
PRINT '  ✓ usp_InspectionDeficiency_Update'

-- 5.3 usp_InspectionDeficiency_Resolve
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_Resolve' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Resolve')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_Resolve
    @DeficiencyId UNIQUEIDENTIFIER,
    @ResolvedByUserId UNIQUEIDENTIFIER,
    @ResolutionNotes NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [' + @Schema + '].InspectionDeficiencies
    SET
        Status = ''Resolved'',
        ResolvedByUserId = @ResolvedByUserId,
        ResolvedDate = GETUTCDATE(),
        ResolutionNotes = @ResolutionNotes,
        ModifiedDate = GETUTCDATE()
    WHERE DeficiencyId = @DeficiencyId

    SELECT
        DeficiencyId,
        Status,
        ResolvedByUserId,
        ResolvedDate,
        ResolutionNotes
    FROM [' + @Schema + '].InspectionDeficiencies
    WHERE DeficiencyId = @DeficiencyId
END
')
PRINT '  ✓ usp_InspectionDeficiency_Resolve'

-- 5.4 usp_InspectionDeficiency_GetByInspection
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_GetByInspection' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetByInspection')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetByInspection
    @InspectionId UNIQUEIDENTIFIER
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
        CreatedDate,
        ModifiedDate
    FROM [' + @Schema + '].InspectionDeficiencies
    WHERE InspectionId = @InspectionId
    ORDER BY Severity DESC, CreatedDate DESC
END
')
PRINT '  ✓ usp_InspectionDeficiency_GetByInspection'

-- 5.5 usp_InspectionDeficiency_GetOpen
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_GetOpen' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetOpen')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetOpen
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.DeficiencyId,
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
    FROM [' + @Schema + '].InspectionDeficiencies d
    INNER JOIN [' + @Schema + '].Inspections i ON d.InspectionId = i.InspectionId
    INNER JOIN [' + @Schema + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE i.TenantId = @TenantId
        AND d.Status IN (''Open'', ''InProgress'')
    ORDER BY d.Severity DESC, d.CreatedDate DESC
END
')
PRINT '  ✓ usp_InspectionDeficiency_GetOpen'

-- 5.6 usp_InspectionDeficiency_GetBySeverity
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_InspectionDeficiency_GetBySeverity' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetBySeverity')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_InspectionDeficiency_GetBySeverity
    @TenantId UNIQUEIDENTIFIER,
    @Severity NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.DeficiencyId,
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
    FROM [' + @Schema + '].InspectionDeficiencies d
    INNER JOIN [' + @Schema + '].Inspections i ON d.InspectionId = i.InspectionId
    INNER JOIN [' + @Schema + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE i.TenantId = @TenantId
        AND d.Severity = @Severity
        AND d.Status IN (''Open'', ''InProgress'')
    ORDER BY d.CreatedDate DESC
END
')
PRINT '  ✓ usp_InspectionDeficiency_GetBySeverity'
PRINT ''

PRINT '============================================================================'
PRINT 'All Inspection Stored Procedures Created Successfully!'
PRINT '============================================================================'
PRINT ''
PRINT 'Summary:'
PRINT '  - ChecklistTemplate procedures: 5'
PRINT '  - Inspection procedures: 9'
PRINT '  - InspectionChecklistResponse procedures: 2'
PRINT '  - InspectionPhoto procedures: 3'
PRINT '  - InspectionDeficiency procedures: 6'
PRINT ''
PRINT 'Total: 25 stored procedures'
PRINT ''

GO
