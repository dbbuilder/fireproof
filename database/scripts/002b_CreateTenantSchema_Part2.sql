/*============================================================================
  File:     002b_CreateTenantSchema_Part2.sql
  Summary:  Creates remaining tenant-specific tables (Inspections, Photos, etc.)
  Date:     October 8, 2025
  
  Description:
    This script continues creating tenant-specific tables including Inspections,
    InspectionChecklistResponses, InspectionPhotos, and MaintenanceRecords.
    Run this after 002_CreateTenantSchema.sql
============================================================================*/

PRINT 'Starting 002b_CreateTenantSchema_Part2.sql execution...'
PRINT 'Creating inspection and maintenance tables'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

-- Get tenant information
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @SchemaName NVARCHAR(128)

SELECT TOP 1 @TenantId = TenantId, @SchemaName = DatabaseSchema 
FROM dbo.Tenants 
WHERE TenantCode = 'DEMO001'

IF @TenantId IS NULL
BEGIN
    PRINT 'ERROR: No tenant found'
    RETURN
END

PRINT 'Working with tenant schema: ' + @SchemaName
PRINT ''

/*============================================================================
  TABLE: Inspections
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.Inspections'

DECLARE @CreateInspectionsSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.Inspections'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].Inspections

CREATE TABLE [' + @SchemaName + '].Inspections (
    InspectionId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    InspectorUserId UNIQUEIDENTIFIER NOT NULL,
    InspectionStartTime DATETIME2 NOT NULL,
    InspectionEndTime DATETIME2 NULL,
    InspectionStatus NVARCHAR(50) NOT NULL,
    Latitude DECIMAL(9,6) NULL,
    Longitude DECIMAL(9,6) NULL,
    GpsAccuracy DECIMAL(10,2) NULL,
    DeviceFingerprint NVARCHAR(500) NULL,
    OverallResult NVARCHAR(50) NULL,
    InspectorNotes NVARCHAR(MAX) NULL,
    TamperHash NVARCHAR(128) NOT NULL,
    PreviousInspectionHash NVARCHAR(128) NULL,
    IsOfflineInspection BIT NOT NULL DEFAULT 0,
    SyncedDate DATETIME2 NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Inspections PRIMARY KEY CLUSTERED (InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_Insp_Extinguisher FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId),
    CONSTRAINT FK_' + @SchemaName + '_Insp_Type FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId),
    CONSTRAINT CK_' + @SchemaName + '_Insp_Status CHECK (InspectionStatus IN (''InProgress'', ''Completed'', ''Failed'')),
    CONSTRAINT CK_' + @SchemaName + '_Insp_Result CHECK (OverallResult IN (''Pass'', ''Fail'', ''NeedsService'') OR OverallResult IS NULL)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Extinguisher ON [' + @SchemaName + '].Inspections(ExtinguisherId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_StartTime ON [' + @SchemaName + '].Inspections(InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Inspector ON [' + @SchemaName + '].Inspections(InspectorUserId, InspectionStartTime DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Insp_Status ON [' + @SchemaName + '].Inspections(InspectionStatus) INCLUDE (InspectionStartTime)
'
EXEC sp_executesql @CreateInspectionsSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionChecklistResponses
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionChecklistResponses'

DECLARE @CreateResponsesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionChecklistResponses'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].InspectionChecklistResponses

CREATE TABLE [' + @SchemaName + '].InspectionChecklistResponses (
    ResponseId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    ChecklistItemId UNIQUEIDENTIFIER NOT NULL,
    ResponseValue NVARCHAR(50) NOT NULL,
    Notes NVARCHAR(MAX) NULL,
    PhotoBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Responses PRIMARY KEY CLUSTERED (ResponseId),
    CONSTRAINT FK_' + @SchemaName + '_Resp_Inspection FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId),
    CONSTRAINT FK_' + @SchemaName + '_Resp_Item FOREIGN KEY (ChecklistItemId) REFERENCES [' + @SchemaName + '].ChecklistItems(ChecklistItemId),
    CONSTRAINT CK_' + @SchemaName + '_Resp_Value CHECK (ResponseValue IN (''Pass'', ''Fail'', ''NA''))
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Resp_Inspection ON [' + @SchemaName + '].InspectionChecklistResponses(InspectionId)
'
EXEC sp_executesql @CreateResponsesSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectionPhotos
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionPhotos'

DECLARE @CreatePhotosSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionPhotos'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].InspectionPhotos

CREATE TABLE [' + @SchemaName + '].InspectionPhotos (
    PhotoId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    InspectionId UNIQUEIDENTIFIER NOT NULL,
    BlobPath NVARCHAR(500) NOT NULL,
    FileName NVARCHAR(255) NOT NULL,
    FileSize BIGINT NOT NULL,
    ContentType NVARCHAR(100) NOT NULL,
    CaptureDate DATETIME2 NOT NULL,
    ExifData NVARCHAR(MAX) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Photos PRIMARY KEY CLUSTERED (PhotoId),
    CONSTRAINT FK_' + @SchemaName + '_Photo_Inspection FOREIGN KEY (InspectionId) REFERENCES [' + @SchemaName + '].Inspections(InspectionId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Photos_Inspection ON [' + @SchemaName + '].InspectionPhotos(InspectionId)
'
EXEC sp_executesql @CreatePhotosSql
PRINT '  - Table created successfully'
PRINT ''

/*============================================================================
  TABLE: MaintenanceRecords
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.MaintenanceRecords'

DECLARE @CreateMaintenanceSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.MaintenanceRecords'', ''U'') IS NOT NULL
    DROP TABLE [' + @SchemaName + '].MaintenanceRecords

CREATE TABLE [' + @SchemaName + '].MaintenanceRecords (
    MaintenanceRecordId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    MaintenanceType NVARCHAR(100) NOT NULL,
    MaintenanceDate DATE NOT NULL,
    TechnicianName NVARCHAR(200) NULL,
    ServiceCompany NVARCHAR(200) NULL,
    Cost DECIMAL(10,2) NULL,
    Notes NVARCHAR(MAX) NULL,
    ReceiptBlobPath NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Maintenance PRIMARY KEY CLUSTERED (MaintenanceRecordId),
    CONSTRAINT FK_' + @SchemaName + '_Maint_Extinguisher FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId)
)

CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Maint_Extinguisher ON [' + @SchemaName + '].MaintenanceRecords(ExtinguisherId, MaintenanceDate DESC)
'
EXEC sp_executesql @CreateMaintenanceSql
PRINT '  - Table created successfully'
PRINT ''

PRINT '============================================================================'
PRINT 'All tenant tables created successfully!'
PRINT 'Schema: ' + @SchemaName
PRINT 'Next step: Run 003_CreateStoredProcedures.sql'
PRINT '============================================================================'

GO
