/*============================================================================
  File:     001_CreateCoreSchema.sql
  Summary:  Creates the core shared schema for the FireProof multi-tenant system
  Date:     October 8, 2025
  
  Description:
    This script creates the foundational tables that are shared across all
    tenants including Tenants, Users, UserTenantRoles, and AuditLog tables.
    These tables use the dbo schema and support multi-tenancy.
    
  Notes:
    - Run this script first before any other database setup
    - All tables use UNIQUEIDENTIFIER for primary keys
    - Audit logging captures all changes to critical tables
    - Indexes optimized for common query patterns
============================================================================*/

-- Print script execution start
PRINT 'Starting 001_CreateCoreSchema.sql execution...'
PRINT 'Creating core shared tables for multi-tenant architecture'
PRINT ''

-- Check if database exists, if not provide guidance
IF DB_ID('FireProofDB') IS NULL
BEGIN
    PRINT 'ERROR: Database FireProofDB does not exist'
    PRINT 'Please create the database first using:'
    PRINT 'CREATE DATABASE FireProofDB'
    RAISERROR('Database does not exist', 16, 1)
    RETURN
END

USE FireProofDB
GO

-- Set options for script execution
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

/*============================================================================
  TABLE: dbo.Tenants
  Description: Stores information about each tenant (organization)
============================================================================*/
PRINT 'Creating table: dbo.Tenants'

IF OBJECT_ID('dbo.Tenants', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.Tenants
END

CREATE TABLE dbo.Tenants (
    TenantId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    TenantCode NVARCHAR(50) NOT NULL,
    CompanyName NVARCHAR(200) NOT NULL,
    SubscriptionTier NVARCHAR(50) NOT NULL, -- Free, Standard, Premium
    IsActive BIT NOT NULL DEFAULT 1,
    MaxLocations INT NOT NULL DEFAULT 10,
    MaxUsers INT NOT NULL DEFAULT 5,
    MaxExtinguishers INT NOT NULL DEFAULT 100,
    DatabaseSchema NVARCHAR(128) NOT NULL, -- tenant_<guid>
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Tenants PRIMARY KEY CLUSTERED (TenantId),
    CONSTRAINT UQ_Tenants_TenantCode UNIQUE (TenantCode),
    CONSTRAINT CK_Tenants_SubscriptionTier CHECK (SubscriptionTier IN ('Free', 'Standard', 'Premium'))
)

PRINT '  - Creating indexes on dbo.Tenants'
CREATE NONCLUSTERED INDEX IX_Tenants_TenantCode ON dbo.Tenants(TenantCode) INCLUDE (IsActive)
CREATE NONCLUSTERED INDEX IX_Tenants_IsActive ON dbo.Tenants(IsActive) INCLUDE (TenantCode, CompanyName)

PRINT '  - Table dbo.Tenants created successfully'
PRINT ''

/*============================================================================
  TABLE: dbo.Users
  Description: Stores user information across all tenants
============================================================================*/
PRINT 'Creating table: dbo.Users'

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.Users
END

CREATE TABLE dbo.Users (
    UserId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    Email NVARCHAR(256) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    AzureAdB2CObjectId NVARCHAR(128) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId)
)

PRINT '  - Creating indexes on dbo.Users'
CREATE UNIQUE NONCLUSTERED INDEX IX_Users_Email ON dbo.Users(Email) WHERE IsActive = 1
CREATE NONCLUSTERED INDEX IX_Users_AzureAdB2CObjectId ON dbo.Users(AzureAdB2CObjectId) WHERE AzureAdB2CObjectId IS NOT NULL
CREATE NONCLUSTERED INDEX IX_Users_IsActive ON dbo.Users(IsActive)

PRINT '  - Table dbo.Users created successfully'
PRINT ''

/*============================================================================
  TABLE: dbo.UserTenantRoles
  Description: Maps users to tenants with specific roles (RBAC)
============================================================================*/
PRINT 'Creating table: dbo.UserTenantRoles'

IF OBJECT_ID('dbo.UserTenantRoles', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.UserTenantRoles
END

CREATE TABLE dbo.UserTenantRoles (
    UserTenantRoleId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    RoleName NVARCHAR(50) NOT NULL, -- TenantAdmin, LocationManager, Inspector, Viewer
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_UserTenantRoles PRIMARY KEY CLUSTERED (UserTenantRoleId),
    CONSTRAINT FK_UserTenantRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_UserTenantRoles_Tenants FOREIGN KEY (TenantId) REFERENCES dbo.Tenants(TenantId),
    CONSTRAINT CK_UserTenantRoles_RoleName CHECK (RoleName IN ('TenantAdmin', 'LocationManager', 'Inspector', 'Viewer'))
)

PRINT '  - Creating indexes on dbo.UserTenantRoles'
CREATE NONCLUSTERED INDEX IX_UserTenantRoles_UserId_TenantId ON dbo.UserTenantRoles(UserId, TenantId) INCLUDE (RoleName, IsActive)
CREATE NONCLUSTERED INDEX IX_UserTenantRoles_TenantId ON dbo.UserTenantRoles(TenantId) WHERE IsActive = 1
CREATE UNIQUE NONCLUSTERED INDEX UQ_UserTenantRoles_User_Tenant_Role ON dbo.UserTenantRoles(UserId, TenantId, RoleName) WHERE IsActive = 1

PRINT '  - Table dbo.UserTenantRoles created successfully'
PRINT ''

/*============================================================================
  TABLE: dbo.AuditLog
  Description: Immutable audit trail of all system actions
============================================================================*/
PRINT 'Creating table: dbo.AuditLog'

IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.AuditLog
END

CREATE TABLE dbo.AuditLog (
    AuditLogId BIGINT IDENTITY(1,1) NOT NULL,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NULL,
    Action NVARCHAR(100) NOT NULL, -- Create, Update, Delete, Login, etc
    EntityType NVARCHAR(100) NULL, -- Table or entity name
    EntityId NVARCHAR(128) NULL,
    OldValues NVARCHAR(MAX) NULL, -- JSON
    NewValues NVARCHAR(MAX) NULL, -- JSON
    IpAddress NVARCHAR(45) NULL,
    UserAgent NVARCHAR(500) NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_AuditLog PRIMARY KEY CLUSTERED (AuditLogId)
)

PRINT '  - Creating indexes on dbo.AuditLog'
CREATE NONCLUSTERED INDEX IX_AuditLog_TenantId_Timestamp ON dbo.AuditLog(TenantId, Timestamp DESC)
CREATE NONCLUSTERED INDEX IX_AuditLog_UserId_Timestamp ON dbo.AuditLog(UserId, Timestamp DESC) WHERE UserId IS NOT NULL
CREATE NONCLUSTERED INDEX IX_AuditLog_EntityType_EntityId ON dbo.AuditLog(EntityType, EntityId) INCLUDE (Action, Timestamp)

PRINT '  - Table dbo.AuditLog created successfully'
PRINT ''

/*============================================================================
  SEED DATA: Insert default values for testing
============================================================================*/
PRINT 'Inserting seed data for testing...'

-- Insert sample tenant
DECLARE @SampleTenantId UNIQUEIDENTIFIER = NEWID()
DECLARE @SampleTenantCode NVARCHAR(50) = 'DEMO001'
DECLARE @SampleSchema NVARCHAR(128) = 'tenant_' + CAST(@SampleTenantId AS NVARCHAR(36))

INSERT INTO dbo.Tenants (TenantId, TenantCode, CompanyName, SubscriptionTier, IsActive, MaxLocations, MaxUsers, MaxExtinguishers, DatabaseSchema)
VALUES (@SampleTenantId, @SampleTenantCode, 'Demo Company Inc', 'Standard', 1, 50, 25, 500, @SampleSchema)

PRINT '  - Inserted sample tenant: ' + @SampleTenantCode
PRINT '  - Tenant ID: ' + CAST(@SampleTenantId AS NVARCHAR(36))
PRINT '  - Database Schema: ' + @SampleSchema

-- Insert sample users
DECLARE @AdminUserId UNIQUEIDENTIFIER = NEWID()
DECLARE @InspectorUserId UNIQUEIDENTIFIER = NEWID()

INSERT INTO dbo.Users (UserId, Email, FirstName, LastName, IsActive)
VALUES 
    (@AdminUserId, 'admin@democompany.com', 'Admin', 'User', 1),
    (@InspectorUserId, 'inspector@democompany.com', 'Inspector', 'Smith', 1)

PRINT '  - Inserted sample users'

-- Assign roles to users
INSERT INTO dbo.UserTenantRoles (UserId, TenantId, RoleName, IsActive)
VALUES 
    (@AdminUserId, @SampleTenantId, 'TenantAdmin', 1),
    (@InspectorUserId, @SampleTenantId, 'Inspector', 1)

PRINT '  - Assigned roles to users'
PRINT ''

/*============================================================================
  VERIFICATION: Check that all tables were created successfully
============================================================================*/
PRINT 'Verifying table creation...'

IF OBJECT_ID('dbo.Tenants', 'U') IS NOT NULL
    PRINT '  ✓ dbo.Tenants exists'
ELSE
    PRINT '  ✗ ERROR: dbo.Tenants was not created'

IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
    PRINT '  ✓ dbo.Users exists'
ELSE
    PRINT '  ✗ ERROR: dbo.Users was not created'

IF OBJECT_ID('dbo.UserTenantRoles', 'U') IS NOT NULL
    PRINT '  ✓ dbo.UserTenantRoles exists'
ELSE
    PRINT '  ✗ ERROR: dbo.UserTenantRoles was not created'

IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL
    PRINT '  ✓ dbo.AuditLog exists'
ELSE
    PRINT '  ✗ ERROR: dbo.AuditLog was not created'

-- Check row counts
DECLARE @TenantCount INT = (SELECT COUNT(*) FROM dbo.Tenants)
DECLARE @UserCount INT = (SELECT COUNT(*) FROM dbo.Users)
DECLARE @RoleCount INT = (SELECT COUNT(*) FROM dbo.UserTenantRoles)

PRINT ''
PRINT 'Row counts:'
PRINT '  - Tenants: ' + CAST(@TenantCount AS NVARCHAR(10))
PRINT '  - Users: ' + CAST(@UserCount AS NVARCHAR(10))
PRINT '  - UserTenantRoles: ' + CAST(@RoleCount AS NVARCHAR(10))

PRINT ''
PRINT '============================================================================'
PRINT 'Core schema creation completed successfully!'
PRINT 'Next step: Run 002_CreateTenantSchema.sql to create tenant-specific tables'
PRINT '============================================================================'

GO
