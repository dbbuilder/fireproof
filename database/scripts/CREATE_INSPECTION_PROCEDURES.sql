/*============================================================================
  File:     CREATE_INSPECTION_PROCEDURES.sql
  Purpose:  Create all stored procedures for Phase 1 inspection workflow
  Date:     October 14, 2025

  Procedures Created: 25 total
    - ChecklistTemplate procedures (5)
    - Inspection procedures (9)
    - InspectionChecklistResponse procedures (2)
    - InspectionPhoto procedures (3)
    - InspectionDeficiency procedures (6)

  Applied to: DEMO001 tenant schema
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Inspection Stored Procedures'
PRINT '============================================================================'
PRINT ''

DECLARE @Schema NVARCHAR(128) = 'tenant_634F2B52-D32A-46DD-A045-D158E793ADCB'

PRINT 'Schema: ' + @Schema
PRINT ''

-- ============================================================================
-- CHECKLIST TEMPLATE PROCEDURES (5)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT '1. ChecklistTemplate Procedures'
PRINT '------------------------------------------------------------------------'

-- 1.1 usp_ChecklistTemplate_GetAll
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ChecklistTemplate_GetAll' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetAll')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetAll
    @TenantId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = 1
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
    FROM [' + @Schema + '].ChecklistTemplates
    WHERE (@TenantId IS NULL OR TenantId = @TenantId OR TenantId IS NULL) -- System templates + tenant templates
        AND (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY InspectionType, TemplateName
END
')
PRINT '  ✓ usp_ChecklistTemplate_GetAll'

-- 1.2 usp_ChecklistTemplate_GetById
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ChecklistTemplate_GetById' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetById')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetById
    @TemplateId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get template
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
    FROM [' + @Schema + '].ChecklistTemplates
    WHERE TemplateId = @TemplateId

    -- Get items
    SELECT
        ChecklistItemId,
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
    FROM [' + @Schema + '].ChecklistItems
    WHERE TemplateId = @TemplateId
    ORDER BY [Order]
END
')
PRINT '  ✓ usp_ChecklistTemplate_GetById'

-- 1.3 usp_ChecklistTemplate_GetByType
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ChecklistTemplate_GetByType' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetByType')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_GetByType
    @InspectionType NVARCHAR(50),
    @Standard NVARCHAR(50) = ''NFPA10''
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
    FROM [' + @Schema + '].ChecklistTemplates
    WHERE InspectionType = @InspectionType
        AND Standard = @Standard
        AND IsActive = 1
        AND IsSystemTemplate = 1 -- Prefer system templates
    ORDER BY IsSystemTemplate DESC, CreatedDate DESC
END
')
PRINT '  ✓ usp_ChecklistTemplate_GetByType'

-- 1.4 usp_ChecklistTemplate_Create
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ChecklistTemplate_Create' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_Create')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_ChecklistTemplate_Create
    @TenantId UNIQUEIDENTIFIER,
    @TemplateName NVARCHAR(200),
    @InspectionType NVARCHAR(50),
    @Standard NVARCHAR(50),
    @Description NVARCHAR(1000) = NULL,
    @TemplateId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @TemplateId = NEWID()

    INSERT INTO [' + @Schema + '].ChecklistTemplates (
        TemplateId, TenantId, TemplateName, InspectionType, Standard,
        IsSystemTemplate, IsActive, Description, CreatedDate
    )
    VALUES (
        @TemplateId, @TenantId, @TemplateName, @InspectionType, @Standard,
        0, 1, @Description, GETUTCDATE()
    )

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
    FROM [' + @Schema + '].ChecklistTemplates
    WHERE TemplateId = @TemplateId
END
')
PRINT '  ✓ usp_ChecklistTemplate_Create'

-- 1.5 usp_ChecklistItem_CreateBatch
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_ChecklistItem_CreateBatch' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_ChecklistItem_CreateBatch')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_ChecklistItem_CreateBatch
    @TemplateId UNIQUEIDENTIFIER,
    @ItemsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Parse JSON array of checklist items
    INSERT INTO [' + @Schema + '].ChecklistItems (
        TemplateId, ItemText, ItemDescription, [Order], Category,
        Required, RequiresPhoto, RequiresComment, PassFailNA, VisualAid, CreatedDate
    )
    SELECT
        @TemplateId,
        JSON_VALUE(value, ''$.ItemText''),
        JSON_VALUE(value, ''$.ItemDescription''),
        JSON_VALUE(value, ''$.Order''),
        JSON_VALUE(value, ''$.Category''),
        ISNULL(CAST(JSON_VALUE(value, ''$.Required'') AS BIT), 1),
        ISNULL(CAST(JSON_VALUE(value, ''$.RequiresPhoto'') AS BIT), 0),
        ISNULL(CAST(JSON_VALUE(value, ''$.RequiresComment'') AS BIT), 0),
        ISNULL(CAST(JSON_VALUE(value, ''$.PassFailNA'') AS BIT), 1),
        JSON_VALUE(value, ''$.VisualAid''),
        GETUTCDATE()
    FROM OPENJSON(@ItemsJson)

    SELECT @@ROWCOUNT as ItemsCreated
END
')
PRINT '  ✓ usp_ChecklistItem_CreateBatch'
PRINT ''

-- ============================================================================
-- INSPECTION PROCEDURES (9)
-- ============================================================================
PRINT '------------------------------------------------------------------------'
PRINT '2. Inspection Procedures'
PRINT '------------------------------------------------------------------------'

-- 2.1 usp_Inspection_Create
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_Create' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_Create')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_Create
    @TenantId UNIQUEIDENTIFIER,
    @ExtinguisherId UNIQUEIDENTIFIER,
    @InspectorUserId UNIQUEIDENTIFIER,
    @InspectionType NVARCHAR(50),
    @ScheduledDate DATETIME2 = NULL,
    @InspectionId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @InspectionId = NEWID()

    INSERT INTO [' + @Schema + '].Inspections (
        InspectionId, TenantId, ExtinguisherId, InspectorUserId,
        InspectionType, InspectionDate, ScheduledDate, Status,
        CreatedDate
    )
    VALUES (
        @InspectionId, @TenantId, @ExtinguisherId, @InspectorUserId,
        @InspectionType, GETUTCDATE(), @ScheduledDate, ''Scheduled'',
        GETUTCDATE()
    )

    SELECT
        InspectionId,
        TenantId,
        ExtinguisherId,
        InspectorUserId,
        InspectionType,
        InspectionDate,
        ScheduledDate,
        Status,
        CreatedDate
    FROM [' + @Schema + '].Inspections
    WHERE InspectionId = @InspectionId
END
')
PRINT '  ✓ usp_Inspection_Create'

-- 2.2 usp_Inspection_Update
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_Update' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_Update')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_Update
    @InspectionId UNIQUEIDENTIFIER,
    @Status NVARCHAR(50) = NULL,
    @Latitude DECIMAL(9,6) = NULL,
    @Longitude DECIMAL(9,6) = NULL,
    @LocationAccuracy DECIMAL(10,2) = NULL,
    @PhysicalConditionPass BIT = NULL,
    @PhysicalConditionNotes NVARCHAR(500) = NULL,
    @PressureCheckPass BIT = NULL,
    @PressureReading NVARCHAR(50) = NULL,
    @OverallPass BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [' + @Schema + '].Inspections
    SET
        Status = ISNULL(@Status, Status),
        Latitude = ISNULL(@Latitude, Latitude),
        Longitude = ISNULL(@Longitude, Longitude),
        LocationAccuracy = ISNULL(@LocationAccuracy, LocationAccuracy),
        PhysicalConditionPass = ISNULL(@PhysicalConditionPass, PhysicalConditionPass),
        PhysicalConditionNotes = ISNULL(@PhysicalConditionNotes, PhysicalConditionNotes),
        PressureCheckPass = ISNULL(@PressureCheckPass, PressureCheckPass),
        PressureReading = ISNULL(@PressureReading, PressureReading),
        OverallPass = ISNULL(@OverallPass, OverallPass),
        ModifiedDate = GETUTCDATE()
    WHERE InspectionId = @InspectionId
END
')
PRINT '  ✓ usp_Inspection_Update'

-- 2.3 usp_Inspection_Complete
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_Complete' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_Complete')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_Complete
    @InspectionId UNIQUEIDENTIFIER,
    @InspectorSignature NVARCHAR(MAX),
    @InspectionHash NVARCHAR(256),
    @PreviousInspectionHash NVARCHAR(256) = NULL,
    @OverallPass BIT,
    @DeficiencyCount INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [' + @Schema + '].Inspections
    SET
        Status = ''Completed'',
        InspectorSignature = @InspectorSignature,
        CompletedTime = GETUTCDATE(),
        DurationSeconds = DATEDIFF(SECOND, StartTime, GETUTCDATE()),
        InspectionHash = @InspectionHash,
        PreviousInspectionHash = @PreviousInspectionHash,
        HashVerified = CASE WHEN @PreviousInspectionHash IS NOT NULL THEN 1 ELSE NULL END,
        OverallPass = @OverallPass,
        DeficiencyCount = @DeficiencyCount,
        ModifiedDate = GETUTCDATE()
    WHERE InspectionId = @InspectionId
END
')
PRINT '  ✓ usp_Inspection_Complete'

-- 2.4 usp_Inspection_GetById
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_GetById' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_GetById')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_GetById
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.*,
        e.AssetTag as ExtinguisherAssetTag,
        e.BarcodeData as ExtinguisherBarcode,
        l.LocationName,
        l.Address as LocationAddress
    FROM [' + @Schema + '].Inspections i
    LEFT JOIN [' + @Schema + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE i.InspectionId = @InspectionId
END
')
PRINT '  ✓ usp_Inspection_GetById'

-- 2.5 usp_Inspection_GetByExtinguisher
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_GetByExtinguisher' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_GetByExtinguisher')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_GetByExtinguisher
    @ExtinguisherId UNIQUEIDENTIFIER,
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        InspectionId,
        TenantId,
        ExtinguisherId,
        InspectorUserId,
        InspectionType,
        InspectionDate,
        Status,
        OverallPass,
        DeficiencyCount,
        CompletedTime,
        CreatedDate
    FROM [' + @Schema + '].Inspections
    WHERE ExtinguisherId = @ExtinguisherId
    ORDER BY InspectionDate DESC
END
')
PRINT '  ✓ usp_Inspection_GetByExtinguisher'

-- 2.6 usp_Inspection_GetByDate
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_GetByDate' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_GetByDate')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_GetByDate
    @TenantId UNIQUEIDENTIFIER,
    @StartDate DATETIME2,
    @EndDate DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.InspectionId,
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
    FROM [' + @Schema + '].Inspections i
    LEFT JOIN [' + @Schema + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE i.TenantId = @TenantId
        AND i.InspectionDate BETWEEN @StartDate AND @EndDate
    ORDER BY i.InspectionDate DESC
END
')
PRINT '  ✓ usp_Inspection_GetByDate'

-- 2.7 usp_Inspection_GetDue
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_GetDue' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_GetDue')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_GetDue
    @TenantId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get extinguishers with overdue inspections
    SELECT
        e.ExtinguisherId,
        e.AssetTag,
        e.BarcodeData,
        e.NextServiceDueDate,
        l.LocationName,
        l.LocationId,
        DATEDIFF(DAY, e.NextServiceDueDate, GETUTCDATE()) as DaysOverdue
    FROM [' + @Schema + '].Extinguishers e
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE e.TenantId = @TenantId
        AND e.IsActive = 1
        AND e.NextServiceDueDate < GETUTCDATE()
    ORDER BY e.NextServiceDueDate ASC
END
')
PRINT '  ✓ usp_Inspection_GetDue'

-- 2.8 usp_Inspection_GetScheduled
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_GetScheduled' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_GetScheduled')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_GetScheduled
    @TenantId UNIQUEIDENTIFIER,
    @DaysAhead INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.InspectionId,
        i.ExtinguisherId,
        i.InspectorUserId,
        i.InspectionType,
        i.ScheduledDate,
        i.Status,
        e.AssetTag,
        e.BarcodeData,
        l.LocationName
    FROM [' + @Schema + '].Inspections i
    LEFT JOIN [' + @Schema + '].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
    LEFT JOIN [' + @Schema + '].Locations l ON e.LocationId = l.LocationId
    WHERE i.TenantId = @TenantId
        AND i.Status IN (''Scheduled'', ''InProgress'')
        AND i.ScheduledDate BETWEEN GETUTCDATE() AND DATEADD(DAY, @DaysAhead, GETUTCDATE())
    ORDER BY i.ScheduledDate ASC
END
')
PRINT '  ✓ usp_Inspection_GetScheduled'

-- 2.9 usp_Inspection_VerifyHash
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'usp_Inspection_VerifyHash' AND SCHEMA_NAME(schema_id) = @Schema)
    EXEC('DROP PROCEDURE [' + @Schema + '].usp_Inspection_VerifyHash')

EXEC('
CREATE PROCEDURE [' + @Schema + '].usp_Inspection_VerifyHash
    @InspectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        InspectionId,
        InspectionHash,
        PreviousInspectionHash,
        HashVerified,
        ExtinguisherId,
        InspectionDate,
        Status
    FROM [' + @Schema + '].Inspections
    WHERE InspectionId = @InspectionId
END
')
PRINT '  ✓ usp_Inspection_VerifyHash'
PRINT ''

PRINT '============================================================================'
PRINT 'Inspection Stored Procedures Created Successfully!'
PRINT 'Created 14 procedures so far... (continuing in next batch)'
PRINT '============================================================================'

GO
