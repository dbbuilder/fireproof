/*============================================================================
  File:     CREATE_INSPECTION_TABLES.sql
  Purpose:  Create inspection workflow tables for Phase 1 MVP
  Date:     October 14, 2025

  Tables Created:
    1. Inspections - Core inspection records with tamper-proofing
    2. InspectionPhotos - Photo metadata with EXIF data
    3. InspectionDeficiencies - Deficiency tracking
    4. ChecklistTemplates - NFPA compliance templates
    5. ChecklistItems - Checklist item definitions
    6. InspectionChecklistResponses - Pass/Fail/NA responses

  Applied to: DEMO001 and DEMO002 tenant schemas
============================================================================*/

USE FireProofDB
GO

SET NOCOUNT ON
GO

PRINT '============================================================================'
PRINT 'Creating Inspection Workflow Tables'
PRINT '============================================================================'
PRINT ''

-- Get tenant schemas
DECLARE @Demo001Schema NVARCHAR(128) = (SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO001')
DECLARE @Demo002Schema NVARCHAR(128) = (SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode = 'DEMO002')

IF @Demo001Schema IS NULL OR @Demo002Schema IS NULL
BEGIN
    PRINT 'ERROR: Required tenant schemas not found!'
    RETURN
END

PRINT 'DEMO001 Schema: ' + @Demo001Schema
PRINT 'DEMO002 Schema: ' + @Demo002Schema
PRINT ''

-- Create tables for both tenants
DECLARE @Schema NVARCHAR(128)
DECLARE @Sql NVARCHAR(MAX)

DECLARE tenant_cursor CURSOR FOR
SELECT DatabaseSchema FROM dbo.Tenants WHERE TenantCode IN ('DEMO001', 'DEMO002')

OPEN tenant_cursor
FETCH NEXT FROM tenant_cursor INTO @Schema

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '============================================================================'
    PRINT 'Processing Schema: ' + @Schema
    PRINT '============================================================================'
    PRINT ''

    -- 1. ChecklistTemplates table (must be first - referenced by ChecklistItems)
    PRINT '  Creating ChecklistTemplates table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''ChecklistTemplates'')
    BEGIN
        CREATE TABLE [' + @Schema + '].ChecklistTemplates (
            TemplateId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NULL, -- NULL for system templates
            TemplateName NVARCHAR(200) NOT NULL,
            InspectionType NVARCHAR(50) NOT NULL, -- Monthly, Annual, SixYear, TwelveYear, Hydrostatic
            Standard NVARCHAR(50) NOT NULL, -- NFPA10, Title19, ULC, OSHA
            IsSystemTemplate BIT NOT NULL DEFAULT 0,
            IsActive BIT NOT NULL DEFAULT 1,
            Description NVARCHAR(1000) NULL,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NULL,

            INDEX IX_ChecklistTemplates_TenantId (TenantId),
            INDEX IX_ChecklistTemplates_InspectionType (InspectionType),
            INDEX IX_ChecklistTemplates_Standard (Standard)
        )
        PRINT ''    ✓ ChecklistTemplates table created''
    END
    ELSE
        PRINT ''    ⊙ ChecklistTemplates table already exists''
    '
    EXEC sp_executesql @Sql

    -- 2. ChecklistItems table (depends on ChecklistTemplates)
    PRINT '  Creating ChecklistItems table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''ChecklistItems'')
    BEGIN
        CREATE TABLE [' + @Schema + '].ChecklistItems (
            ChecklistItemId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            TemplateId UNIQUEIDENTIFIER NOT NULL,
            ItemText NVARCHAR(500) NOT NULL,
            ItemDescription NVARCHAR(1000) NULL, -- Help text for inspectors
            [Order] INT NOT NULL,
            Category NVARCHAR(50) NOT NULL, -- Location, PhysicalCondition, Pressure, Seal, Hose, Label, Other
            Required BIT NOT NULL DEFAULT 1,
            RequiresPhoto BIT NOT NULL DEFAULT 0,
            RequiresComment BIT NOT NULL DEFAULT 0,
            PassFailNA BIT NOT NULL DEFAULT 1, -- true = Pass/Fail/NA, false = Pass/Fail only
            VisualAid NVARCHAR(500) NULL, -- URL to diagram/photo
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT FK_ChecklistItems_Template FOREIGN KEY (TemplateId)
                REFERENCES [' + @Schema + '].ChecklistTemplates(TemplateId)
                ON DELETE CASCADE,

            INDEX IX_ChecklistItems_TemplateId (TemplateId),
            INDEX IX_ChecklistItems_Order ([Order])
        )
        PRINT ''    ✓ ChecklistItems table created''
    END
    ELSE
        PRINT ''    ⊙ ChecklistItems table already exists''
    '
    EXEC sp_executesql @Sql

    -- 3. Inspections table (core table)
    PRINT '  Creating Inspections table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''Inspections'')
    BEGIN
        CREATE TABLE [' + @Schema + '].Inspections (
            InspectionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            TenantId UNIQUEIDENTIFIER NOT NULL,
            ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
            InspectorUserId UNIQUEIDENTIFIER NOT NULL,
            InspectionType NVARCHAR(50) NOT NULL, -- Monthly, Annual, SixYear, TwelveYear, Hydrostatic
            InspectionDate DATETIME2 NOT NULL,
            ScheduledDate DATETIME2 NULL,
            Status NVARCHAR(50) NOT NULL DEFAULT ''Scheduled'', -- Scheduled, InProgress, Completed, Failed, Cancelled

            -- GPS & Location Verification
            Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL,
            LocationAccuracy DECIMAL(10,2) NULL, -- meters
            LocationVerified BIT NULL, -- matches extinguisher expected location

            -- Physical Condition Checks
            PhysicalConditionPass BIT NULL,
            PhysicalConditionNotes NVARCHAR(500) NULL,
            HasDamage BIT NULL,
            HasCorrosion BIT NULL,
            HasLeakage BIT NULL,
            IsObstructed BIT NULL,

            -- Pressure/Weight Check
            PressureCheckPass BIT NULL,
            PressureReading NVARCHAR(50) NULL, -- "Green", "Red", or actual PSI
            WeightReading DECIMAL(10,2) NULL, -- for CO2
            WeightUnit NVARCHAR(10) NULL, -- lbs, kg

            -- Label/Tag Integrity
            LabelIntegrityPass BIT NULL,
            InstructionsLegible BIT NULL,
            LastInspectionDateVisible BIT NULL,

            -- Seal & Pin Status
            SealIntegrityPass BIT NULL,
            SealPresent BIT NULL,
            SealUnbroken BIT NULL,
            PinPresent BIT NULL,

            -- Hose/Nozzle Check
            HoseNozzlePass BIT NULL,
            HoseCondition NVARCHAR(50) NULL, -- Good, Cracked, Blocked
            NozzleCondition NVARCHAR(50) NULL,

            -- Overall Results
            OverallPass BIT NULL,
            RequiresRepair BIT NULL,
            RequiresReplacement BIT NULL,
            DeficiencyCount INT NOT NULL DEFAULT 0,

            -- Signatures & Timestamps
            InspectorSignature NVARCHAR(MAX) NULL, -- base64 image
            StartTime DATETIME2 NULL,
            CompletedTime DATETIME2 NULL,
            DurationSeconds INT NULL,

            -- Device Info
            DeviceInfo NVARCHAR(500) NULL, -- JSON: device, OS, app version
            AppVersion NVARCHAR(50) NULL,

            -- Tamper-Proofing
            InspectionHash NVARCHAR(256) NULL, -- HMAC-SHA256
            PreviousInspectionHash NVARCHAR(256) NULL, -- hash chain (blockchain-style)
            HashVerified BIT NULL,

            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NULL,

            CONSTRAINT FK_Inspections_Extinguisher FOREIGN KEY (ExtinguisherId)
                REFERENCES [' + @Schema + '].Extinguishers(ExtinguisherId),

            INDEX IX_Inspections_TenantId (TenantId),
            INDEX IX_Inspections_ExtinguisherId (ExtinguisherId),
            INDEX IX_Inspections_InspectorUserId (InspectorUserId),
            INDEX IX_Inspections_InspectionDate (InspectionDate),
            INDEX IX_Inspections_Status (Status),
            INDEX IX_Inspections_InspectionType (InspectionType)
        )
        PRINT ''    ✓ Inspections table created''
    END
    ELSE
        PRINT ''    ⊙ Inspections table already exists''
    '
    EXEC sp_executesql @Sql

    -- 4. InspectionPhotos table (depends on Inspections)
    PRINT '  Creating InspectionPhotos table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''InspectionPhotos'')
    BEGIN
        CREATE TABLE [' + @Schema + '].InspectionPhotos (
            PhotoId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            InspectionId UNIQUEIDENTIFIER NOT NULL,
            PhotoType NVARCHAR(50) NOT NULL, -- Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other
            BlobUrl NVARCHAR(500) NOT NULL, -- Azure Blob Storage URL
            ThumbnailUrl NVARCHAR(500) NULL,
            FileSize BIGINT NULL,
            MimeType NVARCHAR(100) NULL,

            -- EXIF Data (for tamper verification)
            CaptureDate DATETIME2 NULL,
            Latitude DECIMAL(9,6) NULL,
            Longitude DECIMAL(9,6) NULL,
            DeviceModel NVARCHAR(200) NULL,
            EXIFData NVARCHAR(MAX) NULL, -- full JSON

            Notes NVARCHAR(500) NULL,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT FK_InspectionPhotos_Inspection FOREIGN KEY (InspectionId)
                REFERENCES [' + @Schema + '].Inspections(InspectionId)
                ON DELETE CASCADE,

            INDEX IX_InspectionPhotos_InspectionId (InspectionId),
            INDEX IX_InspectionPhotos_PhotoType (PhotoType)
        )
        PRINT ''    ✓ InspectionPhotos table created''
    END
    ELSE
        PRINT ''    ⊙ InspectionPhotos table already exists''
    '
    EXEC sp_executesql @Sql

    -- 5. InspectionDeficiencies table (depends on Inspections)
    PRINT '  Creating InspectionDeficiencies table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''InspectionDeficiencies'')
    BEGIN
        CREATE TABLE [' + @Schema + '].InspectionDeficiencies (
            DeficiencyId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            InspectionId UNIQUEIDENTIFIER NOT NULL,
            DeficiencyType NVARCHAR(50) NOT NULL, -- Damage, Corrosion, Leakage, Pressure, Seal, Label, Hose, Location, Other
            Severity NVARCHAR(20) NOT NULL, -- Low, Medium, High, Critical
            Description NVARCHAR(1000) NOT NULL,
            Status NVARCHAR(20) NOT NULL DEFAULT ''Open'', -- Open, InProgress, Resolved, Deferred

            ActionRequired NVARCHAR(500) NULL,
            EstimatedCost DECIMAL(10,2) NULL,

            AssignedToUserId UNIQUEIDENTIFIER NULL,
            DueDate DATE NULL,

            ResolutionNotes NVARCHAR(1000) NULL,
            ResolvedDate DATETIME2 NULL,
            ResolvedByUserId UNIQUEIDENTIFIER NULL,

            PhotoIds NVARCHAR(MAX) NULL, -- JSON array of PhotoIds

            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
            ModifiedDate DATETIME2 NULL,

            CONSTRAINT FK_InspectionDeficiencies_Inspection FOREIGN KEY (InspectionId)
                REFERENCES [' + @Schema + '].Inspections(InspectionId)
                ON DELETE CASCADE,

            INDEX IX_InspectionDeficiencies_InspectionId (InspectionId),
            INDEX IX_InspectionDeficiencies_Status (Status),
            INDEX IX_InspectionDeficiencies_Severity (Severity),
            INDEX IX_InspectionDeficiencies_AssignedToUserId (AssignedToUserId)
        )
        PRINT ''    ✓ InspectionDeficiencies table created''
    END
    ELSE
        PRINT ''    ⊙ InspectionDeficiencies table already exists''
    '
    EXEC sp_executesql @Sql

    -- 6. InspectionChecklistResponses table (depends on Inspections and ChecklistItems)
    PRINT '  Creating InspectionChecklistResponses table...'
    SET @Sql = '
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
                   WHERE TABLE_SCHEMA = ''' + @Schema + '''
                   AND TABLE_NAME = ''InspectionChecklistResponses'')
    BEGIN
        CREATE TABLE [' + @Schema + '].InspectionChecklistResponses (
            ResponseId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
            InspectionId UNIQUEIDENTIFIER NOT NULL,
            ChecklistItemId UNIQUEIDENTIFIER NOT NULL,
            Response NVARCHAR(10) NOT NULL, -- Pass, Fail, NA
            Comment NVARCHAR(1000) NULL,
            PhotoId UNIQUEIDENTIFIER NULL,
            CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

            CONSTRAINT FK_InspectionChecklistResponses_Inspection FOREIGN KEY (InspectionId)
                REFERENCES [' + @Schema + '].Inspections(InspectionId)
                ON DELETE CASCADE,

            CONSTRAINT FK_InspectionChecklistResponses_ChecklistItem FOREIGN KEY (ChecklistItemId)
                REFERENCES [' + @Schema + '].ChecklistItems(ChecklistItemId),

            INDEX IX_InspectionChecklistResponses_InspectionId (InspectionId),
            INDEX IX_InspectionChecklistResponses_ChecklistItemId (ChecklistItemId),
            INDEX IX_InspectionChecklistResponses_Response (Response)
        )
        PRINT ''    ✓ InspectionChecklistResponses table created''
    END
    ELSE
        PRINT ''    ⊙ InspectionChecklistResponses table already exists''
    '
    EXEC sp_executesql @Sql

    PRINT ''
    PRINT '  Schema ' + @Schema + ' processing complete.'
    PRINT ''

    FETCH NEXT FROM tenant_cursor INTO @Schema
END

CLOSE tenant_cursor
DEALLOCATE tenant_cursor

PRINT '============================================================================'
PRINT 'Inspection Tables Created Successfully!'
PRINT '============================================================================'
PRINT ''
PRINT 'Tables Created:'
PRINT '  1. ChecklistTemplates - NFPA compliance templates'
PRINT '  2. ChecklistItems - Checklist item definitions'
PRINT '  3. Inspections - Core inspection records'
PRINT '  4. InspectionPhotos - Photo metadata with EXIF'
PRINT '  5. InspectionDeficiencies - Deficiency tracking'
PRINT '  6. InspectionChecklistResponses - Pass/Fail/NA responses'
PRINT ''
PRINT 'Applied to schemas: ' + @Demo001Schema + ', ' + @Demo002Schema
PRINT ''

GO
