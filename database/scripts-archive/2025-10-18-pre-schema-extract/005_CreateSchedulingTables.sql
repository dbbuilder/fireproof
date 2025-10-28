/*============================================================================
  File:     005_CreateSchedulingTables.sql
  Summary:  Creates tables for inspection scheduling, routing, and geofencing
  Date:     October 8, 2025
  
  Description:
    This script creates tables to support:
    - Automatic inspection scheduling
    - Route optimization for inspectors
    - Geofencing for location-based features
    - Push notification subscriptions
    - Notification preferences
    
  Notes:
    - Run after 002_CreateTenantSchema.sql
    - Creates both shared (dbo) and tenant-specific tables
    - Includes indexes for performance
============================================================================*/

PRINT 'Starting 005_CreateSchedulingTables.sql execution...'
PRINT 'Creating scheduling, routing, and notification tables'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

-- Get tenant information for tenant-specific tables
DECLARE @TenantId UNIQUEIDENTIFIER
DECLARE @SchemaName NVARCHAR(128)

SELECT TOP 1 @TenantId = TenantId, @SchemaName = DatabaseSchema 
FROM dbo.Tenants 
WHERE TenantCode = 'DEMO001'

IF @TenantId IS NULL
BEGIN
    PRINT 'ERROR: No tenant found. Please run 001_CreateCoreSchema.sql first'
    RETURN
END

PRINT 'Creating tables for tenant schema: ' + @SchemaName
PRINT ''

/*============================================================================
  TABLE: InspectionSchedules (Tenant-specific)
  Description: Automatic scheduling of inspections based on frequency
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectionSchedules'

DECLARE @CreateSchedulesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectionSchedules'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectionSchedules
END

CREATE TABLE [' + @SchemaName + '].InspectionSchedules (
    ScheduleId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    ExtinguisherId UNIQUEIDENTIFIER NOT NULL,
    InspectionTypeId UNIQUEIDENTIFIER NOT NULL,
    FrequencyDays INT NOT NULL,
    LastCompletedDate DATE NULL,
    NextDueDate DATE NOT NULL,
    AssignedInspectorUserId UNIQUEIDENTIFIER NULL,
    ScheduleStatus NVARCHAR(50) NOT NULL DEFAULT ''Active'',
    Notes NVARCHAR(500) NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Schedules PRIMARY KEY CLUSTERED (ScheduleId),
    CONSTRAINT FK_' + @SchemaName + '_Sched_Ext FOREIGN KEY (ExtinguisherId) REFERENCES [' + @SchemaName + '].Extinguishers(ExtinguisherId),
    CONSTRAINT FK_' + @SchemaName + '_Sched_Type FOREIGN KEY (InspectionTypeId) REFERENCES [' + @SchemaName + '].InspectionTypes(InspectionTypeId),
    CONSTRAINT CK_' + @SchemaName + '_Sched_Status CHECK (ScheduleStatus IN (''Active'', ''Paused'', ''Completed'', ''Cancelled''))
)
'
EXEC sp_executesql @CreateSchedulesSql

DECLARE @CreateSchedIndexesSql NVARCHAR(MAX) = '
PRINT ''  - Creating indexes on ' + @SchemaName + '.InspectionSchedules''
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Sched_NextDue ON [' + @SchemaName + '].InspectionSchedules(NextDueDate) WHERE ScheduleStatus = ''Active''
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Sched_Inspector ON [' + @SchemaName + '].InspectionSchedules(AssignedInspectorUserId) WHERE AssignedInspectorUserId IS NOT NULL
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Sched_Ext ON [' + @SchemaName + '].InspectionSchedules(ExtinguisherId) INCLUDE (NextDueDate, ScheduleStatus)
'
EXEC sp_executesql @CreateSchedIndexesSql
PRINT '  - Table ' + @SchemaName + '.InspectionSchedules created successfully'
PRINT ''

/*============================================================================
  TABLE: InspectorRoutes (Tenant-specific)
  Description: Optimized daily routes for inspectors
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.InspectorRoutes'

DECLARE @CreateRoutesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.InspectorRoutes'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].InspectorRoutes
END

CREATE TABLE [' + @SchemaName + '].InspectorRoutes (
    RouteId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    InspectorUserId UNIQUEIDENTIFIER NOT NULL,
    RouteDate DATE NOT NULL,
    OptimizedSequence NVARCHAR(MAX) NOT NULL,
    TotalDistanceKm DECIMAL(10,2) NULL,
    EstimatedDurationMinutes INT NULL,
    ActualDurationMinutes INT NULL,
    RouteStatus NVARCHAR(50) NOT NULL DEFAULT ''Planned'',
    StartedAt DATETIME2 NULL,
    CompletedAt DATETIME2 NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Routes PRIMARY KEY CLUSTERED (RouteId),
    CONSTRAINT CK_' + @SchemaName + '_Routes_Status CHECK (RouteStatus IN (''Planned'', ''InProgress'', ''Completed'', ''Cancelled''))
)
'
EXEC sp_executesql @CreateRoutesSql

DECLARE @CreateRoutesIndexesSql NVARCHAR(MAX) = '
PRINT ''  - Creating indexes on ' + @SchemaName + '.InspectorRoutes''
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Routes_Inspector_Date ON [' + @SchemaName + '].InspectorRoutes(InspectorUserId, RouteDate DESC)
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Routes_Date ON [' + @SchemaName + '].InspectorRoutes(RouteDate) WHERE RouteStatus IN (''Planned'', ''InProgress'')
'
EXEC sp_executesql @CreateRoutesIndexesSql
PRINT '  - Table ' + @SchemaName + '.InspectorRoutes created successfully'
PRINT ''

/*============================================================================
  TABLE: LocationGeofences (Tenant-specific)
  Description: Geofence definitions for locations
============================================================================*/
PRINT 'Creating table: ' + @SchemaName + '.LocationGeofences'

DECLARE @CreateGeofencesSql NVARCHAR(MAX) = '
IF OBJECT_ID(''' + @SchemaName + '.LocationGeofences'', ''U'') IS NOT NULL
BEGIN
    PRINT ''  - Table already exists, dropping...''
    DROP TABLE [' + @SchemaName + '].LocationGeofences
END

CREATE TABLE [' + @SchemaName + '].LocationGeofences (
    GeofenceId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantId UNIQUEIDENTIFIER NOT NULL,
    LocationId UNIQUEIDENTIFIER NOT NULL,
    CenterLatitude DECIMAL(9,6) NOT NULL,
    CenterLongitude DECIMAL(9,6) NOT NULL,
    RadiusMeters INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_' + @SchemaName + '_Geofences PRIMARY KEY CLUSTERED (GeofenceId),
    CONSTRAINT FK_' + @SchemaName + '_Geofence_Location FOREIGN KEY (LocationId) REFERENCES [' + @SchemaName + '].Locations(LocationId),
    CONSTRAINT CK_' + @SchemaName + '_Geofence_Radius CHECK (RadiusMeters BETWEEN 10 AND 1000)
)
'
EXEC sp_executesql @CreateGeofencesSql

DECLARE @CreateGeofenceIndexesSql NVARCHAR(MAX) = '
PRINT ''  - Creating indexes on ' + @SchemaName + '.LocationGeofences''
CREATE UNIQUE NONCLUSTERED INDEX UQ_' + @SchemaName + '_Geofence_Location ON [' + @SchemaName + '].LocationGeofences(LocationId) WHERE IsActive = 1
CREATE NONCLUSTERED INDEX IX_' + @SchemaName + '_Geofence_Coords ON [' + @SchemaName + '].LocationGeofences(CenterLatitude, CenterLongitude) WHERE IsActive = 1
'
EXEC sp_executesql @CreateGeofenceIndexesSql
PRINT '  - Table ' + @SchemaName + '.LocationGeofences created successfully'
PRINT ''

/*============================================================================
  TABLE: PushNotificationSubscriptions (Shared - dbo)
  Description: Device tokens for push notifications
============================================================================*/
PRINT 'Creating table: dbo.PushNotificationSubscriptions'

IF OBJECT_ID('dbo.PushNotificationSubscriptions', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.PushNotificationSubscriptions
END

CREATE TABLE dbo.PushNotificationSubscriptions (
    SubscriptionId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    DeviceToken NVARCHAR(500) NOT NULL,
    Platform NVARCHAR(20) NOT NULL,
    DeviceName NVARCHAR(100) NULL,
    AppVersion NVARCHAR(20) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    LastUsed DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_PushNotificationSubscriptions PRIMARY KEY CLUSTERED (SubscriptionId),
    CONSTRAINT FK_PushNotificationSubscriptions_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT CK_PushNotificationSubscriptions_Platform CHECK (Platform IN ('iOS', 'Android', 'Web'))
)

PRINT '  - Creating indexes on dbo.PushNotificationSubscriptions'
CREATE UNIQUE NONCLUSTERED INDEX UQ_PushNotificationSubscriptions_Token ON dbo.PushNotificationSubscriptions(DeviceToken) WHERE IsActive = 1
CREATE NONCLUSTERED INDEX IX_PushNotificationSubscriptions_User ON dbo.PushNotificationSubscriptions(UserId) WHERE IsActive = 1

PRINT '  - Table dbo.PushNotificationSubscriptions created successfully'
PRINT ''

/*============================================================================
  TABLE: UserNotificationPreferences (Shared - dbo)
  Description: User preferences for notifications
============================================================================*/
PRINT 'Creating table: dbo.UserNotificationPreferences'

IF OBJECT_ID('dbo.UserNotificationPreferences', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.UserNotificationPreferences
END

CREATE TABLE dbo.UserNotificationPreferences (
    PreferenceId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    NotificationType NVARCHAR(100) NOT NULL,
    IsEnabled BIT NOT NULL DEFAULT 1,
    QuietHoursStart TIME NULL,
    QuietHoursEnd TIME NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_UserNotificationPreferences PRIMARY KEY CLUSTERED (PreferenceId),
    CONSTRAINT FK_UserNotificationPreferences_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
)

PRINT '  - Creating indexes on dbo.UserNotificationPreferences'
CREATE UNIQUE NONCLUSTERED INDEX UQ_UserNotificationPreferences_User_Type ON dbo.UserNotificationPreferences(UserId, NotificationType)

PRINT '  - Table dbo.UserNotificationPreferences created successfully'
PRINT ''
/*============================================================================
  SEED DATA: Insert sample scheduling data
============================================================================*/
PRINT 'Inserting seed data for scheduling...'

-- Get sample extinguisher and inspection type IDs
DECLARE @SampleExtId UNIQUEIDENTIFIER
DECLARE @MonthlyInspTypeId UNIQUEIDENTIFIER

DECLARE @GetSampleDataSql NVARCHAR(MAX) = '
SELECT TOP 1 @SampleExtId = ExtinguisherId FROM [' + @SchemaName + '].Extinguishers WHERE IsActive = 1
SELECT TOP 1 @MonthlyInspTypeId = InspectionTypeId FROM [' + @SchemaName + '].InspectionTypes WHERE TypeName = ''Monthly Visual''
'

EXEC sp_executesql @GetSampleDataSql, 
    N'@SampleExtId UNIQUEIDENTIFIER OUTPUT, @MonthlyInspTypeId UNIQUEIDENTIFIER OUTPUT',
    @SampleExtId OUTPUT, @MonthlyInspTypeId OUTPUT

-- Insert sample schedule
IF @SampleExtId IS NOT NULL AND @MonthlyInspTypeId IS NOT NULL
BEGIN
    DECLARE @InsertScheduleSql NVARCHAR(MAX) = '
    INSERT INTO [' + @SchemaName + '].InspectionSchedules (TenantId, ExtinguisherId, InspectionTypeId, FrequencyDays, LastCompletedDate, NextDueDate, ScheduleStatus)
    VALUES 
        (''' + CAST(@TenantId AS NVARCHAR(36)) + ''', ''' + CAST(@SampleExtId AS NVARCHAR(36)) + ''', ''' + CAST(@MonthlyInspTypeId AS NVARCHAR(36)) + ''', 30, DATEADD(DAY, -15, GETUTCDATE()), DATEADD(DAY, 15, GETUTCDATE()), ''Active'')
    
    PRINT ''  - Inserted sample inspection schedule''
    '
    EXEC sp_executesql @InsertScheduleSql
END

-- Insert sample geofence for first location
DECLARE @SampleLocationId UNIQUEIDENTIFIER
DECLARE @GetLocationSql NVARCHAR(MAX) = '
SELECT TOP 1 @SampleLocationId = LocationId FROM [' + @SchemaName + '].Locations WHERE Latitude IS NOT NULL AND Longitude IS NOT NULL
'
EXEC sp_executesql @GetLocationSql, N'@SampleLocationId UNIQUEIDENTIFIER OUTPUT', @SampleLocationId OUTPUT

IF @SampleLocationId IS NOT NULL
BEGIN
    DECLARE @InsertGeofenceSql NVARCHAR(MAX) = '
    INSERT INTO [' + @SchemaName + '].LocationGeofences (TenantId, LocationId, CenterLatitude, CenterLongitude, RadiusMeters, IsActive)
    SELECT ''' + CAST(@TenantId AS NVARCHAR(36)) + ''', LocationId, Latitude, Longitude, 100, 1
    FROM [' + @SchemaName + '].Locations
    WHERE LocationId = ''' + CAST(@SampleLocationId AS NVARCHAR(36)) + '''
    
    PRINT ''  - Inserted sample geofence''
    '
    EXEC sp_executesql @InsertGeofenceSql
END

-- Insert default notification preferences for sample users
INSERT INTO dbo.UserNotificationPreferences (UserId, NotificationType, IsEnabled)
SELECT u.UserId, nt.NotificationType, 1
FROM dbo.Users u
CROSS JOIN (
    VALUES 
        ('InspectionReminder'),
        ('InspectionOverdue'),
        ('GeofenceEntry'),
        ('InspectionAssigned'),
        ('SyncComplete'),
        ('ComplianceAlert')
) AS nt(NotificationType)
WHERE u.IsActive = 1
AND NOT EXISTS (
    SELECT 1 FROM dbo.UserNotificationPreferences p 
    WHERE p.UserId = u.UserId AND p.NotificationType = nt.NotificationType
)

PRINT '  - Inserted default notification preferences'
PRINT ''

/*============================================================================
  VERIFICATION
============================================================================*/
PRINT 'Verifying scheduling tables creation...'

-- Count tenant-specific tables
DECLARE @TenantTableCount INT
DECLARE @CountTenantTablesSql NVARCHAR(MAX) = '
SELECT @TenantTableCount = COUNT(*) 
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = ''' + @SchemaName + '''
AND t.name IN (''InspectionSchedules'', ''InspectorRoutes'', ''LocationGeofences'')
'
EXEC sp_executesql @CountTenantTablesSql, N'@TenantTableCount INT OUTPUT', @TenantTableCount OUTPUT

PRINT '  - Tenant-specific tables created: ' + CAST(@TenantTableCount AS NVARCHAR(10)) + '/3'

-- Count shared tables
IF OBJECT_ID('dbo.PushNotificationSubscriptions', 'U') IS NOT NULL
    PRINT '  ✓ dbo.PushNotificationSubscriptions exists'
ELSE
    PRINT '  ✗ ERROR: dbo.PushNotificationSubscriptions was not created'

IF OBJECT_ID('dbo.UserNotificationPreferences', 'U') IS NOT NULL
    PRINT '  ✓ dbo.UserNotificationPreferences exists'
ELSE
    PRINT '  ✗ ERROR: dbo.UserNotificationPreferences was not created'

-- Check row counts
DECLARE @ScheduleCount INT
DECLARE @GetScheduleCountSql NVARCHAR(MAX) = 'SELECT @ScheduleCount = COUNT(*) FROM [' + @SchemaName + '].InspectionSchedules'
EXEC sp_executesql @GetScheduleCountSql, N'@ScheduleCount INT OUTPUT', @ScheduleCount OUTPUT

DECLARE @GeofenceCount INT
DECLARE @GetGeofenceCountSql NVARCHAR(MAX) = 'SELECT @GeofenceCount = COUNT(*) FROM [' + @SchemaName + '].LocationGeofences'
EXEC sp_executesql @GetGeofenceCountSql, N'@GeofenceCount INT OUTPUT', @GeofenceCount OUTPUT

DECLARE @PrefCount INT = (SELECT COUNT(*) FROM dbo.UserNotificationPreferences)

PRINT ''
PRINT 'Row counts:'
PRINT '  - InspectionSchedules: ' + CAST(@ScheduleCount AS NVARCHAR(10))
PRINT '  - LocationGeofences: ' + CAST(@GeofenceCount AS NVARCHAR(10))
PRINT '  - UserNotificationPreferences: ' + CAST(@PrefCount AS NVARCHAR(10))

PRINT ''
PRINT '============================================================================'
PRINT 'Scheduling tables creation completed successfully!'
PRINT 'Next step: Implement scheduling services in backend API'
PRINT '============================================================================'

GO
