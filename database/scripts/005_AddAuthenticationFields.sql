/*============================================================================
  File:     005_AddAuthenticationFields.sql
  Summary:  Adds JWT authentication fields to Users table
  Date:     October 9, 2025

  Description:
    This script adds password hash, salt, and refresh token fields to the
    Users table to support JWT authentication. This is a temporary solution
    before migrating to Entra External ID.

  Notes:
    - Run this after 001_CreateCoreSchema.sql
    - Adds BCrypt password hashing support
    - Supports refresh token mechanism
    - Will be replaced by Entra External ID in Phase 3
============================================================================*/

PRINT 'Starting 005_AddAuthenticationFields.sql execution...'
PRINT 'Adding JWT authentication fields to Users table'
PRINT ''

USE FireProofDB
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON
GO

/*============================================================================
  ALTER TABLE: dbo.Users
  Add authentication fields for JWT
============================================================================*/
PRINT 'Adding authentication fields to dbo.Users'

-- Add password hash field (BCrypt hash)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PasswordHash')
BEGIN
    ALTER TABLE dbo.Users ADD PasswordHash NVARCHAR(500) NULL
    PRINT '  - Added PasswordHash column'
END
ELSE
    PRINT '  - PasswordHash column already exists'

-- Add password salt field
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE dbo.Users ADD PasswordSalt NVARCHAR(500) NULL
    PRINT '  - Added PasswordSalt column'
END
ELSE
    PRINT '  - PasswordSalt column already exists'

-- Add refresh token field
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'RefreshToken')
BEGIN
    ALTER TABLE dbo.Users ADD RefreshToken NVARCHAR(500) NULL
    PRINT '  - Added RefreshToken column'
END
ELSE
    PRINT '  - RefreshToken column already exists'

-- Add refresh token expiry
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'RefreshTokenExpiryDate')
BEGIN
    ALTER TABLE dbo.Users ADD RefreshTokenExpiryDate DATETIME2 NULL
    PRINT '  - Added RefreshTokenExpiryDate column'
END
ELSE
    PRINT '  - RefreshTokenExpiryDate column already exists'

-- Add last login date
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'LastLoginDate')
BEGIN
    ALTER TABLE dbo.Users ADD LastLoginDate DATETIME2 NULL
    PRINT '  - Added LastLoginDate column'
END
ELSE
    PRINT '  - LastLoginDate column already exists'

-- Add email confirmed field
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'EmailConfirmed')
BEGIN
    ALTER TABLE dbo.Users ADD EmailConfirmed BIT NOT NULL DEFAULT 0
    PRINT '  - Added EmailConfirmed column'
END
ELSE
    PRINT '  - EmailConfirmed column already exists'

-- Add phone number for MFA
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PhoneNumber')
BEGIN
    ALTER TABLE dbo.Users ADD PhoneNumber NVARCHAR(20) NULL
    PRINT '  - Added PhoneNumber column'
END
ELSE
    PRINT '  - PhoneNumber column already exists'

-- Add MFA enabled flag
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'MfaEnabled')
BEGIN
    ALTER TABLE dbo.Users ADD MfaEnabled BIT NOT NULL DEFAULT 0
    PRINT '  - Added MfaEnabled column'
END
ELSE
    PRINT '  - MfaEnabled column already exists'

PRINT '  - All authentication fields added successfully'
PRINT ''

/*============================================================================
  CREATE TABLE: dbo.SystemRoles
  Description: System-wide roles that work across all tenants
============================================================================*/
PRINT 'Creating table: dbo.SystemRoles'

IF OBJECT_ID('dbo.SystemRoles', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.SystemRoles
END

CREATE TABLE dbo.SystemRoles (
    SystemRoleId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    RoleName NVARCHAR(50) NOT NULL, -- SystemAdmin, Support
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_SystemRoles PRIMARY KEY CLUSTERED (SystemRoleId),
    CONSTRAINT UQ_SystemRoles_RoleName UNIQUE (RoleName)
)

PRINT '  - Table dbo.SystemRoles created successfully'
PRINT ''

/*============================================================================
  CREATE TABLE: dbo.UserSystemRoles
  Description: Maps users to system-wide roles
============================================================================*/
PRINT 'Creating table: dbo.UserSystemRoles'

IF OBJECT_ID('dbo.UserSystemRoles', 'U') IS NOT NULL
BEGIN
    PRINT '  - Table already exists, dropping...'
    DROP TABLE dbo.UserSystemRoles
END

CREATE TABLE dbo.UserSystemRoles (
    UserSystemRoleId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    SystemRoleId UNIQUEIDENTIFIER NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_UserSystemRoles PRIMARY KEY CLUSTERED (UserSystemRoleId),
    CONSTRAINT FK_UserSystemRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
    CONSTRAINT FK_UserSystemRoles_SystemRoles FOREIGN KEY (SystemRoleId) REFERENCES dbo.SystemRoles(SystemRoleId),
    CONSTRAINT UQ_UserSystemRoles_User_Role UNIQUE (UserId, SystemRoleId)
)

PRINT '  - Creating indexes on dbo.UserSystemRoles'
CREATE NONCLUSTERED INDEX IX_UserSystemRoles_UserId ON dbo.UserSystemRoles(UserId) WHERE IsActive = 1
CREATE NONCLUSTERED INDEX IX_UserSystemRoles_SystemRoleId ON dbo.UserSystemRoles(SystemRoleId) WHERE IsActive = 1

PRINT '  - Table dbo.UserSystemRoles created successfully'
PRINT ''

/*============================================================================
  SEED DATA: Insert default system roles
============================================================================*/
PRINT 'Inserting default system roles...'

DECLARE @SystemAdminRoleId UNIQUEIDENTIFIER = NEWID()
DECLARE @SupportRoleId UNIQUEIDENTIFIER = NEWID()

INSERT INTO dbo.SystemRoles (SystemRoleId, RoleName, Description, IsActive)
VALUES
    (@SystemAdminRoleId, 'SystemAdmin', 'Full system access across all tenants', 1),
    (@SupportRoleId, 'Support', 'Customer support access to assist tenants', 1)

PRINT '  - Inserted system roles: SystemAdmin, Support'
PRINT ''

/*============================================================================
  CREATE INDEXES: Add indexes for authentication queries
============================================================================*/
PRINT 'Creating authentication indexes...'

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'IX_Users_RefreshToken')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Users_RefreshToken ON dbo.Users(RefreshToken)
    WHERE RefreshToken IS NOT NULL AND IsActive = 1
    PRINT '  - Created index IX_Users_RefreshToken'
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'IX_Users_EmailConfirmed')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Users_EmailConfirmed ON dbo.Users(EmailConfirmed, IsActive)
    INCLUDE (Email)
    PRINT '  - Created index IX_Users_EmailConfirmed'
END

PRINT ''

/*============================================================================
  VERIFICATION: Check that all fields and tables were created successfully
============================================================================*/
PRINT 'Verifying schema changes...'

-- Check fields
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PasswordHash')
    PRINT '  ✓ Users.PasswordHash exists'
ELSE
    PRINT '  ✗ ERROR: Users.PasswordHash was not created'

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'RefreshToken')
    PRINT '  ✓ Users.RefreshToken exists'
ELSE
    PRINT '  ✗ ERROR: Users.RefreshToken was not created'

IF OBJECT_ID('dbo.SystemRoles', 'U') IS NOT NULL
    PRINT '  ✓ dbo.SystemRoles exists'
ELSE
    PRINT '  ✗ ERROR: dbo.SystemRoles was not created'

IF OBJECT_ID('dbo.UserSystemRoles', 'U') IS NOT NULL
    PRINT '  ✓ dbo.UserSystemRoles exists'
ELSE
    PRINT '  ✗ ERROR: dbo.UserSystemRoles was not created'

-- Check row counts
DECLARE @SystemRoleCount INT = (SELECT COUNT(*) FROM dbo.SystemRoles)
PRINT ''
PRINT 'Row counts:'
PRINT '  - SystemRoles: ' + CAST(@SystemRoleCount AS NVARCHAR(10))

PRINT ''
PRINT '============================================================================'
PRINT 'Authentication fields migration completed successfully!'
PRINT 'Users table now supports JWT authentication with BCrypt password hashing'
PRINT '============================================================================'

GO
