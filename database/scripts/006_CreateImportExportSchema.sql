/*============================================================================
  File:     006_CreateImportExportSchema.sql
  Summary:  Creates tables and stored procedures for import/export features
  Date:     2025-10-30
  Phase:    2.1 - Data Import/Export System

  Features:
    - Import job tracking and history
    - Field mapping templates
    - Historical inspection import with lockout
    - Export job management
    - Audit logging for imports/exports
============================================================================*/

USE FireProofDB
GO

PRINT 'Creating Import/Export Schema...'
PRINT ''

-- ============================================================================
-- Table: ImportJobs
-- Description: Tracks all import operations
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ImportJobs')
BEGIN
    CREATE TABLE dbo.ImportJobs (
        ImportJobId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        JobType NVARCHAR(50) NOT NULL, -- 'Extinguishers', 'Locations', 'HistoricalInspections', 'ChecklistTemplates'
        FileName NVARCHAR(255) NOT NULL,
        FileSize BIGINT NOT NULL,
        FileHash NVARCHAR(64) NOT NULL, -- SHA256 hash
        BlobStorageUrl NVARCHAR(1000) NULL,
        Status NVARCHAR(50) NOT NULL, -- 'Pending', 'Validating', 'Processing', 'Completed', 'Failed', 'PartialSuccess'
        TotalRows INT NULL,
        ProcessedRows INT NULL,
        SuccessRows INT NULL,
        FailedRows INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        ErrorDetails NVARCHAR(MAX) NULL, -- JSON array of row-level errors
        MappingTemplateId UNIQUEIDENTIFIER NULL,
        MappingData NVARCHAR(MAX) NULL, -- JSON of field mappings
        IsDryRun BIT NOT NULL DEFAULT 0,
        StartedDate DATETIME2 NULL,
        CompletedDate DATETIME2 NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ImportJobs_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT FK_ImportJobs_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
        INDEX IX_ImportJobs_TenantId_CreatedDate (TenantId, CreatedDate DESC),
        INDEX IX_ImportJobs_Status (Status),
        INDEX IX_ImportJobs_JobType (JobType)
    )

    PRINT '  - ImportJobs table created'
END
GO

-- ============================================================================
-- Table: FieldMappingTemplates
-- Description: Saves field mapping configurations for reuse
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FieldMappingTemplates')
BEGIN
    CREATE TABLE dbo.FieldMappingTemplates (
        MappingTemplateId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        TemplateName NVARCHAR(100) NOT NULL,
        JobType NVARCHAR(50) NOT NULL,
        MappingData NVARCHAR(MAX) NOT NULL, -- JSON of source->destination field mappings
        TransformationRules NVARCHAR(MAX) NULL, -- JSON of data transformation rules (date formats, text case, etc.)
        IsDefault BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_FieldMappingTemplates_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT FK_FieldMappingTemplates_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
        INDEX IX_FieldMappingTemplates_TenantId_JobType (TenantId, JobType)
    )

    PRINT '  - FieldMappingTemplates table created'
END
GO

-- ============================================================================
-- Table: ExportJobs
-- Description: Tracks all export operations
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExportJobs')
BEGIN
    CREATE TABLE dbo.ExportJobs (
        ExportJobId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        TenantId UNIQUEIDENTIFIER NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        JobType NVARCHAR(50) NOT NULL, -- 'Extinguishers', 'Inspections', 'ComplianceReport', 'FullExport'
        ExportFormat NVARCHAR(20) NOT NULL, -- 'CSV', 'XLSX', 'PDF'
        FileName NVARCHAR(255) NOT NULL,
        FileSize BIGINT NULL,
        BlobStorageUrl NVARCHAR(1000) NULL,
        Status NVARCHAR(50) NOT NULL, -- 'Pending', 'Processing', 'Completed', 'Failed'
        TotalRows INT NULL,
        FilterCriteria NVARCHAR(MAX) NULL, -- JSON of filter parameters
        IncludedFields NVARCHAR(MAX) NULL, -- JSON array of field names
        ErrorMessage NVARCHAR(MAX) NULL,
        StartedDate DATETIME2 NULL,
        CompletedDate DATETIME2 NULL,
        ExpiresDate DATETIME2 NULL, -- Download link expiration
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ExportJobs_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
        CONSTRAINT FK_ExportJobs_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
        INDEX IX_ExportJobs_TenantId_CreatedDate (TenantId, CreatedDate DESC),
        INDEX IX_ExportJobs_Status (Status)
    )

    PRINT '  - ExportJobs table created'
END
GO

-- ============================================================================
-- Add Historical Import Lockout flag to Tenants table
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Tenants') AND name = 'AllowHistoricalImports')
BEGIN
    ALTER TABLE dbo.Tenants ADD AllowHistoricalImports BIT NOT NULL DEFAULT 1
    PRINT '  - Added AllowHistoricalImports column to Tenants table'
END
GO

-- ============================================================================
-- Stored Procedure: usp_ImportJob_Create
-- Description: Creates a new import job record
-- ============================================================================
IF OBJECT_ID('dbo.usp_ImportJob_Create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ImportJob_Create
GO

CREATE PROCEDURE dbo.usp_ImportJob_Create
    @TenantId UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER,
    @JobType NVARCHAR(50),
    @FileName NVARCHAR(255),
    @FileSize BIGINT,
    @FileHash NVARCHAR(64),
    @BlobStorageUrl NVARCHAR(1000),
    @MappingTemplateId UNIQUEIDENTIFIER = NULL,
    @MappingData NVARCHAR(MAX) = NULL,
    @IsDryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ImportJobId UNIQUEIDENTIFIER = NEWID()

    -- Check if historical imports are allowed for this tenant
    IF @JobType = 'HistoricalInspections'
    BEGIN
        DECLARE @AllowHistoricalImports BIT
        SELECT @AllowHistoricalImports = AllowHistoricalImports
        FROM dbo.Tenants
        WHERE TenantId = @TenantId

        IF @AllowHistoricalImports = 0
        BEGIN
            RAISERROR('Historical inspection imports are disabled for this tenant', 16, 1)
            RETURN
        END
    END

    INSERT INTO dbo.ImportJobs (
        ImportJobId,
        TenantId,
        UserId,
        JobType,
        FileName,
        FileSize,
        FileHash,
        BlobStorageUrl,
        Status,
        MappingTemplateId,
        MappingData,
        IsDryRun,
        CreatedDate,
        ModifiedDate
    )
    VALUES (
        @ImportJobId,
        @TenantId,
        @UserId,
        @JobType,
        @FileName,
        @FileSize,
        @FileHash,
        @BlobStorageUrl,
        'Pending',
        @MappingTemplateId,
        @MappingData,
        @IsDryRun,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return the created job
    SELECT
        ImportJobId,
        TenantId,
        UserId,
        JobType,
        FileName,
        FileSize,
        FileHash,
        BlobStorageUrl,
        Status,
        TotalRows,
        ProcessedRows,
        SuccessRows,
        FailedRows,
        ErrorMessage,
        ErrorDetails,
        MappingTemplateId,
        MappingData,
        IsDryRun,
        StartedDate,
        CompletedDate,
        CreatedDate,
        ModifiedDate
    FROM dbo.ImportJobs
    WHERE ImportJobId = @ImportJobId
END
GO

PRINT '  - usp_ImportJob_Create created'
GO

-- ============================================================================
-- Stored Procedure: usp_ImportJob_UpdateStatus
-- Description: Updates import job status and statistics
-- ============================================================================
IF OBJECT_ID('dbo.usp_ImportJob_UpdateStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ImportJob_UpdateStatus
GO

CREATE PROCEDURE dbo.usp_ImportJob_UpdateStatus
    @ImportJobId UNIQUEIDENTIFIER,
    @Status NVARCHAR(50),
    @TotalRows INT = NULL,
    @ProcessedRows INT = NULL,
    @SuccessRows INT = NULL,
    @FailedRows INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @ErrorDetails NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ImportJobs
    SET
        Status = @Status,
        TotalRows = COALESCE(@TotalRows, TotalRows),
        ProcessedRows = COALESCE(@ProcessedRows, ProcessedRows),
        SuccessRows = COALESCE(@SuccessRows, SuccessRows),
        FailedRows = COALESCE(@FailedRows, FailedRows),
        ErrorMessage = @ErrorMessage,
        ErrorDetails = @ErrorDetails,
        StartedDate = CASE WHEN @Status = 'Processing' AND StartedDate IS NULL THEN GETUTCDATE() ELSE StartedDate END,
        CompletedDate = CASE WHEN @Status IN ('Completed', 'Failed', 'PartialSuccess') THEN GETUTCDATE() ELSE CompletedDate END,
        ModifiedDate = GETUTCDATE()
    WHERE ImportJobId = @ImportJobId

    -- Return updated job
    SELECT
        ImportJobId,
        TenantId,
        UserId,
        JobType,
        FileName,
        Status,
        TotalRows,
        ProcessedRows,
        SuccessRows,
        FailedRows,
        ErrorMessage,
        ErrorDetails,
        StartedDate,
        CompletedDate,
        CreatedDate,
        ModifiedDate
    FROM dbo.ImportJobs
    WHERE ImportJobId = @ImportJobId
END
GO

PRINT '  - usp_ImportJob_UpdateStatus created'
GO

-- ============================================================================
-- Stored Procedure: usp_ImportJob_GetHistory
-- Description: Gets import job history for a tenant
-- ============================================================================
IF OBJECT_ID('dbo.usp_ImportJob_GetHistory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ImportJob_GetHistory
GO

CREATE PROCEDURE dbo.usp_ImportJob_GetHistory
    @TenantId UNIQUEIDENTIFIER,
    @JobType NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize

    -- Get total count
    DECLARE @TotalCount INT
    SELECT @TotalCount = COUNT(*)
    FROM dbo.ImportJobs
    WHERE TenantId = @TenantId
      AND (@JobType IS NULL OR JobType = @JobType)

    -- Get paginated results
    SELECT
        ij.ImportJobId,
        ij.TenantId,
        ij.UserId,
        u.Email AS UserEmail,
        u.FirstName + ' ' + u.LastName AS UserName,
        ij.JobType,
        ij.FileName,
        ij.FileSize,
        ij.Status,
        ij.TotalRows,
        ij.ProcessedRows,
        ij.SuccessRows,
        ij.FailedRows,
        ij.ErrorMessage,
        ij.IsDryRun,
        ij.StartedDate,
        ij.CompletedDate,
        ij.CreatedDate,
        @TotalCount AS TotalCount
    FROM dbo.ImportJobs ij
    INNER JOIN dbo.Users u ON ij.UserId = u.UserId
    WHERE ij.TenantId = @TenantId
      AND (@JobType IS NULL OR ij.JobType = @JobType)
    ORDER BY ij.CreatedDate DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY
END
GO

PRINT '  - usp_ImportJob_GetHistory created'
GO

-- ============================================================================
-- Stored Procedure: usp_Tenant_ToggleHistoricalImports
-- Description: Enables or disables historical inspection imports for a tenant
-- ============================================================================
IF OBJECT_ID('dbo.usp_Tenant_ToggleHistoricalImports', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Tenant_ToggleHistoricalImports
GO

CREATE PROCEDURE dbo.usp_Tenant_ToggleHistoricalImports
    @TenantId UNIQUEIDENTIFIER,
    @Enable BIT,
    @UserId UNIQUEIDENTIFIER,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION

    BEGIN TRY
        -- Get current state
        DECLARE @CurrentState BIT
        SELECT @CurrentState = AllowHistoricalImports
        FROM dbo.Tenants
        WHERE TenantId = @TenantId

        IF @CurrentState IS NULL
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('Tenant not found', 16, 1)
            RETURN
        END

        -- Prevent re-enabling once disabled (one-way operation)
        IF @CurrentState = 0 AND @Enable = 1
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('Historical imports cannot be re-enabled once disabled', 16, 1)
            RETURN
        END

        -- Update tenant
        UPDATE dbo.Tenants
        SET AllowHistoricalImports = @Enable,
            ModifiedDate = GETUTCDATE()
        WHERE TenantId = @TenantId

        -- Log audit entry
        INSERT INTO dbo.AuditLog (
            TenantId,
            UserId,
            Action,
            EntityType,
            EntityId,
            OldValues,
            NewValues,
            IPAddress,
            UserAgent,
            Timestamp
        )
        VALUES (
            @TenantId,
            @UserId,
            CASE WHEN @Enable = 1 THEN 'EnableHistoricalImports' ELSE 'DisableHistoricalImports' END,
            'Tenant',
            @TenantId,
            CONCAT('AllowHistoricalImports: ', @CurrentState),
            CONCAT('AllowHistoricalImports: ', @Enable, ' | Reason: ', COALESCE(@Reason, 'N/A')),
            NULL,
            NULL,
            GETUTCDATE()
        )

        COMMIT TRANSACTION

        -- Return updated tenant info
        SELECT
            TenantId,
            CompanyName,
            AllowHistoricalImports,
            ModifiedDate
        FROM dbo.Tenants
        WHERE TenantId = @TenantId
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrorMessage, 16, 1)
    END CATCH
END
GO

PRINT '  - usp_Tenant_ToggleHistoricalImports created'
GO

-- ============================================================================
-- Stored Procedure: usp_FieldMappingTemplate_Save
-- Description: Saves a field mapping template for reuse
-- ============================================================================
IF OBJECT_ID('dbo.usp_FieldMappingTemplate_Save', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FieldMappingTemplate_Save
GO

CREATE PROCEDURE dbo.usp_FieldMappingTemplate_Save
    @TenantId UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER,
    @TemplateName NVARCHAR(100),
    @JobType NVARCHAR(50),
    @MappingData NVARCHAR(MAX),
    @TransformationRules NVARCHAR(MAX) = NULL,
    @IsDefault BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MappingTemplateId UNIQUEIDENTIFIER = NEWID()

    -- If setting as default, unset other defaults for this job type
    IF @IsDefault = 1
    BEGIN
        UPDATE dbo.FieldMappingTemplates
        SET IsDefault = 0
        WHERE TenantId = @TenantId
          AND JobType = @JobType
          AND IsDefault = 1
    END

    INSERT INTO dbo.FieldMappingTemplates (
        MappingTemplateId,
        TenantId,
        UserId,
        TemplateName,
        JobType,
        MappingData,
        TransformationRules,
        IsDefault,
        IsActive,
        CreatedDate,
        ModifiedDate
    )
    VALUES (
        @MappingTemplateId,
        @TenantId,
        @UserId,
        @TemplateName,
        @JobType,
        @MappingData,
        @TransformationRules,
        @IsDefault,
        1,
        GETUTCDATE(),
        GETUTCDATE()
    )

    -- Return created template
    SELECT
        MappingTemplateId,
        TenantId,
        UserId,
        TemplateName,
        JobType,
        MappingData,
        TransformationRules,
        IsDefault,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.FieldMappingTemplates
    WHERE MappingTemplateId = @MappingTemplateId
END
GO

PRINT '  - usp_FieldMappingTemplate_Save created'
GO

-- ============================================================================
-- Stored Procedure: usp_FieldMappingTemplate_GetByTenant
-- Description: Gets all mapping templates for a tenant
-- ============================================================================
IF OBJECT_ID('dbo.usp_FieldMappingTemplate_GetByTenant', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_FieldMappingTemplate_GetByTenant
GO

CREATE PROCEDURE dbo.usp_FieldMappingTemplate_GetByTenant
    @TenantId UNIQUEIDENTIFIER,
    @JobType NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        fmt.MappingTemplateId,
        fmt.TenantId,
        fmt.UserId,
        u.Email AS UserEmail,
        u.FirstName + ' ' + u.LastName AS UserName,
        fmt.TemplateName,
        fmt.JobType,
        fmt.MappingData,
        fmt.TransformationRules,
        fmt.IsDefault,
        fmt.IsActive,
        fmt.CreatedDate,
        fmt.ModifiedDate
    FROM dbo.FieldMappingTemplates fmt
    INNER JOIN dbo.Users u ON fmt.UserId = u.UserId
    WHERE fmt.TenantId = @TenantId
      AND fmt.IsActive = 1
      AND (@JobType IS NULL OR fmt.JobType = @JobType)
    ORDER BY fmt.IsDefault DESC, fmt.TemplateName
END
GO

PRINT '  - usp_FieldMappingTemplate_GetByTenant created'
GO

PRINT ''
PRINT 'Import/Export Schema Created Successfully!'
PRINT ''
PRINT 'Tables Created:'
PRINT '  - ImportJobs'
PRINT '  - FieldMappingTemplates'
PRINT '  - ExportJobs'
PRINT '  - Tenants.AllowHistoricalImports column'
PRINT ''
PRINT 'Stored Procedures Created:'
PRINT '  - usp_ImportJob_Create'
PRINT '  - usp_ImportJob_UpdateStatus'
PRINT '  - usp_ImportJob_GetHistory'
PRINT '  - usp_Tenant_ToggleHistoricalImports'
PRINT '  - usp_FieldMappingTemplate_Save'
PRINT '  - usp_FieldMappingTemplate_GetByTenant'
GO
