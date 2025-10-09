/*============================================================================
  File:     005_AddAuthenticationFields_Fixed.sql
  Summary:  Adds JWT authentication fields to Users table (FIXED VERSION)
  Date:     October 9, 2025
============================================================================*/

USE FireProofDB
GO

PRINT 'Starting authentication fields migration...'
PRINT ''

-- Add all authentication columns
PRINT 'Adding authentication fields to dbo.Users...'

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PasswordHash')
    ALTER TABLE dbo.Users ADD PasswordHash NVARCHAR(500) NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PasswordSalt')
    ALTER TABLE dbo.Users ADD PasswordSalt NVARCHAR(500) NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'RefreshToken')
    ALTER TABLE dbo.Users ADD RefreshToken NVARCHAR(500) NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'RefreshTokenExpiryDate')
    ALTER TABLE dbo.Users ADD RefreshTokenExpiryDate DATETIME2 NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'LastLoginDate')
    ALTER TABLE dbo.Users ADD LastLoginDate DATETIME2 NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'EmailConfirmed')
    ALTER TABLE dbo.Users ADD EmailConfirmed BIT NOT NULL DEFAULT 0

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'PhoneNumber')
    ALTER TABLE dbo.Users ADD PhoneNumber NVARCHAR(20) NULL

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'MfaEnabled')
    ALTER TABLE dbo.Users ADD MfaEnabled BIT NOT NULL DEFAULT 0

PRINT '  - All authentication fields added'
GO

-- Create SystemRoles table
PRINT 'Creating SystemRoles table...'

IF OBJECT_ID('dbo.SystemRoles', 'U') IS NOT NULL
    DROP TABLE dbo.SystemRoles

CREATE TABLE dbo.SystemRoles (
    SystemRoleId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    RoleName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_SystemRoles PRIMARY KEY CLUSTERED (SystemRoleId),
    CONSTRAINT UQ_SystemRoles_RoleName UNIQUE (RoleName)
)

PRINT '  - SystemRoles table created'
GO

-- Create UserSystemRoles table
PRINT 'Creating UserSystemRoles table...'

IF OBJECT_ID('dbo.UserSystemRoles', 'U') IS NOT NULL
    DROP TABLE dbo.UserSystemRoles

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

CREATE NONCLUSTERED INDEX IX_UserSystemRoles_UserId ON dbo.UserSystemRoles(UserId) WHERE IsActive = 1
CREATE NONCLUSTERED INDEX IX_UserSystemRoles_SystemRoleId ON dbo.UserSystemRoles(SystemRoleId) WHERE IsActive = 1

PRINT '  - UserSystemRoles table created'
GO

-- Insert system roles
PRINT 'Inserting system roles...'

INSERT INTO dbo.SystemRoles (RoleName, Description, IsActive)
VALUES
    ('SystemAdmin', 'Full system access across all tenants', 1),
    ('Support', 'Customer support access to assist tenants', 1)

PRINT '  - System roles inserted'
GO

-- Create indexes on Users table
PRINT 'Creating authentication indexes...'

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'IX_Users_RefreshToken')
    CREATE NONCLUSTERED INDEX IX_Users_RefreshToken ON dbo.Users(RefreshToken) WHERE RefreshToken IS NOT NULL AND IsActive = 1

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'IX_Users_EmailConfirmed')
    CREATE NONCLUSTERED INDEX IX_Users_EmailConfirmed ON dbo.Users(EmailConfirmed, IsActive) INCLUDE (Email)

PRINT '  - Indexes created'
GO

PRINT ''
PRINT 'Authentication fields migration completed successfully!'
PRINT ''
GO
