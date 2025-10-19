/*============================================================================
  File:     CREATE_SUPER_ADMIN_USERS.sql
  Purpose:  Create two new super admin users with multi-tenant access
  Date:     October 18, 2025
  Users:    Charlotte Payne (cpayne4@kumc.edu)
            Jon Dunn (jdunn@2amarketing.com)
  Password: FireProofIt!
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '============================================================================'
PRINT 'Creating Super Admin Users'
PRINT '============================================================================'

-- Variables for consistent data
DECLARE @SystemAdminRoleId UNIQUEIDENTIFIER = '465DF078-B5DC-4BDB-BD4E-FCDBC0B184B6';
DECLARE @DemoTenantId UNIQUEIDENTIFIER = '634F2B52-D32A-46DD-A045-D158E793ADCB';
DECLARE @PasswordHash NVARCHAR(MAX) = '$2a$12$j7yDQmxvZ8K5k.POMjQMf.EhW8kH6V3KGUQx7YOJQz4r9N8VXqZ7i'; -- BCrypt hash for 'FireProofIt!'
DECLARE @PasswordSalt NVARCHAR(MAX) = '$2a$12$j7yDQmxvZ8K5k.POMjQMf.';

-- Charlotte Payne
DECLARE @CharlotteUserId UNIQUEIDENTIFIER = NEWID();

PRINT ''
PRINT '--- Creating Charlotte Payne ---'

-- Insert user
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'cpayne4@kumc.edu')
BEGIN
    INSERT INTO dbo.Users (
        UserId,
        Email,
        FirstName,
        LastName,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate,
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        EmailConfirmed,
        PhoneNumber,
        MfaEnabled
    )
    VALUES (
        @CharlotteUserId,
        'cpayne4@kumc.edu',
        'Charlotte',
        'Payne',
        NULL,
        1, -- IsActive
        GETUTCDATE(),
        GETUTCDATE(),
        @PasswordHash,
        @PasswordSalt,
        NULL,
        NULL,
        NULL,
        0, -- EmailConfirmed
        NULL,
        0  -- MfaEnabled
    );

    PRINT '✓ Created user: Charlotte Payne (cpayne4@kumc.edu)';
    PRINT '  UserId: ' + CAST(@CharlotteUserId AS NVARCHAR(36));
END
ELSE
BEGIN
    SELECT @CharlotteUserId = UserId FROM dbo.Users WHERE Email = 'cpayne4@kumc.edu';
    PRINT '- User already exists: Charlotte Payne';
    PRINT '  UserId: ' + CAST(@CharlotteUserId AS NVARCHAR(36));
END

-- Add SystemAdmin role for Charlotte
IF NOT EXISTS (SELECT 1 FROM dbo.UserSystemRoles WHERE UserId = @CharlotteUserId AND SystemRoleId = @SystemAdminRoleId)
BEGIN
    INSERT INTO dbo.UserSystemRoles (
        UserSystemRoleId,
        UserId,
        SystemRoleId,
        IsActive,
        CreatedDate
    )
    VALUES (
        NEWID(),
        @CharlotteUserId,
        @SystemAdminRoleId,
        1,
        GETUTCDATE()
    );
    PRINT '✓ Added SystemAdmin role for Charlotte';
END
ELSE
    PRINT '- Charlotte already has SystemAdmin role';

-- Add TenantAdmin role for Charlotte
IF NOT EXISTS (SELECT 1 FROM dbo.UserTenantRoles WHERE UserId = @CharlotteUserId AND TenantId = @DemoTenantId)
BEGIN
    INSERT INTO dbo.UserTenantRoles (
        UserTenantRoleId,
        UserId,
        TenantId,
        RoleName,
        IsActive,
        CreatedDate
    )
    VALUES (
        NEWID(),
        @CharlotteUserId,
        @DemoTenantId,
        'TenantAdmin',
        1,
        GETUTCDATE()
    );
    PRINT '✓ Added TenantAdmin role for Charlotte (Demo Company Inc)';
END
ELSE
    PRINT '- Charlotte already has TenantAdmin role';

-- Jon Dunn
DECLARE @JonUserId UNIQUEIDENTIFIER = NEWID();

PRINT ''
PRINT '--- Creating Jon Dunn ---'

-- Insert user
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'jdunn@2amarketing.com')
BEGIN
    INSERT INTO dbo.Users (
        UserId,
        Email,
        FirstName,
        LastName,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate,
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        EmailConfirmed,
        PhoneNumber,
        MfaEnabled
    )
    VALUES (
        @JonUserId,
        'jdunn@2amarketing.com',
        'Jon',
        'Dunn',
        NULL,
        1, -- IsActive
        GETUTCDATE(),
        GETUTCDATE(),
        @PasswordHash,
        @PasswordSalt,
        NULL,
        NULL,
        NULL,
        0, -- EmailConfirmed
        NULL,
        0  -- MfaEnabled
    );

    PRINT '✓ Created user: Jon Dunn (jdunn@2amarketing.com)';
    PRINT '  UserId: ' + CAST(@JonUserId AS NVARCHAR(36));
END
ELSE
BEGIN
    SELECT @JonUserId = UserId FROM dbo.Users WHERE Email = 'jdunn@2amarketing.com';
    PRINT '- User already exists: Jon Dunn';
    PRINT '  UserId: ' + CAST(@JonUserId AS NVARCHAR(36));
END

-- Add SystemAdmin role for Jon
IF NOT EXISTS (SELECT 1 FROM dbo.UserSystemRoles WHERE UserId = @JonUserId AND SystemRoleId = @SystemAdminRoleId)
BEGIN
    INSERT INTO dbo.UserSystemRoles (
        UserSystemRoleId,
        UserId,
        SystemRoleId,
        IsActive,
        CreatedDate
    )
    VALUES (
        NEWID(),
        @JonUserId,
        @SystemAdminRoleId,
        1,
        GETUTCDATE()
    );
    PRINT '✓ Added SystemAdmin role for Jon';
END
ELSE
    PRINT '- Jon already has SystemAdmin role';

-- Add TenantAdmin role for Jon
IF NOT EXISTS (SELECT 1 FROM dbo.UserTenantRoles WHERE UserId = @JonUserId AND TenantId = @DemoTenantId)
BEGIN
    INSERT INTO dbo.UserTenantRoles (
        UserTenantRoleId,
        UserId,
        TenantId,
        RoleName,
        IsActive,
        CreatedDate
    )
    VALUES (
        NEWID(),
        @JonUserId,
        @DemoTenantId,
        'TenantAdmin',
        1,
        GETUTCDATE()
    );
    PRINT '✓ Added TenantAdmin role for Jon (Demo Company Inc)';
END
ELSE
    PRINT '- Jon already has TenantAdmin role';

PRINT ''
PRINT '============================================================================'
PRINT 'Super Admin User Creation Complete!'
PRINT '============================================================================'

-- Show all super admins
PRINT ''
PRINT 'All Users with SystemAdmin Role:'
SELECT
    u.Email,
    u.FirstName + ' ' + u.LastName AS FullName,
    'SystemAdmin' AS Role,
    u.IsActive
FROM dbo.Users u
JOIN dbo.UserSystemRoles usr ON u.UserId = usr.UserId
JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
WHERE sr.RoleName = 'SystemAdmin'
ORDER BY u.Email;

PRINT ''
PRINT 'User Credentials:'
PRINT '  Email: cpayne4@kumc.edu'
PRINT '  Password: FireProofIt!'
PRINT ''
PRINT '  Email: jdunn@2amarketing.com'
PRINT '  Password: FireProofIt!'
PRINT ''

GO
