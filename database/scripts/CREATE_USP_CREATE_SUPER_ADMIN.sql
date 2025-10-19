/*============================================================================
  File:     CREATE_USP_CREATE_SUPER_ADMIN.sql
  Purpose:  Stored procedure to create super admin users
  Date:     October 18, 2025
  Usage:    EXEC dbo.usp_CreateSuperAdmin
              @FirstName = 'John',
              @LastName = 'Doe',
              @Email = 'jdoe@example.com',
              @TemplatUserEmail = 'chris@servicevision.net'
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateSuperAdmin
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Email NVARCHAR(256),
    @TemplateUserEmail NVARCHAR(256) = 'chris@servicevision.net', -- Default template user
    @DefaultPassword NVARCHAR(256) = 'FireProofIt!' -- Default password (will be hashed)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewUserId UNIQUEIDENTIFIER = NEWID();
    DECLARE @TemplateUserId UNIQUEIDENTIFIER;
    DECLARE @ErrorMessage NVARCHAR(4000);

    -- Default password hash for "FireProofIt!" (BCrypt WorkFactor 12)
    DECLARE @PasswordHash NVARCHAR(MAX) = '$2a$12$bVHRanQb9FoMMLeU2Hob3en990lJPsop/vaTVtb8YUssNBF.9S7GW';
    DECLARE @PasswordSalt NVARCHAR(MAX) = '$2a$12$bVHRanQb9FoMMLeU2Hob3e';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate email doesn't already exist
        IF EXISTS (SELECT 1 FROM dbo.Users WHERE Email = @Email)
        BEGIN
            SET @ErrorMessage = 'User with email ' + @Email + ' already exists';
            THROW 50001, @ErrorMessage, 1;
        END

        -- Get template user
        SELECT @TemplateUserId = UserId
        FROM dbo.Users
        WHERE Email = @TemplateUserEmail;

        IF @TemplateUserId IS NULL
        BEGIN
            SET @ErrorMessage = 'Template user not found: ' + @TemplateUserEmail;
            THROW 50002, @ErrorMessage, 1;
        END

        -- Create the new user
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
            @NewUserId,
            @Email,
            @FirstName,
            @LastName,
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

        PRINT 'Created user: ' + @FirstName + ' ' + @LastName + ' (' + @Email + ')';
        PRINT 'UserId: ' + CAST(@NewUserId AS NVARCHAR(36));

        -- Copy SystemRoles from template user
        INSERT INTO dbo.UserSystemRoles (
            UserSystemRoleId,
            UserId,
            SystemRoleId,
            IsActive,
            CreatedDate
        )
        SELECT
            NEWID(),
            @NewUserId,
            usr.SystemRoleId,
            1,
            GETUTCDATE()
        FROM dbo.UserSystemRoles usr
        WHERE usr.UserId = @TemplateUserId
        AND usr.IsActive = 1;

        DECLARE @SystemRolesCount INT = @@ROWCOUNT;
        PRINT 'Copied ' + CAST(@SystemRolesCount AS NVARCHAR(10)) + ' system role(s)';

        -- Copy TenantRoles from template user
        INSERT INTO dbo.UserTenantRoles (
            UserTenantRoleId,
            UserId,
            TenantId,
            RoleName,
            IsActive,
            CreatedDate
        )
        SELECT
            NEWID(),
            @NewUserId,
            utr.TenantId,
            utr.RoleName,
            1,
            GETUTCDATE()
        FROM dbo.UserTenantRoles utr
        WHERE utr.UserId = @TemplateUserId
        AND utr.IsActive = 1;

        DECLARE @TenantRolesCount INT = @@ROWCOUNT;
        PRINT 'Copied ' + CAST(@TenantRolesCount AS NVARCHAR(10)) + ' tenant role(s)';

        COMMIT TRANSACTION;

        -- Return summary
        SELECT
            @NewUserId AS UserId,
            @Email AS Email,
            @FirstName + ' ' + @LastName AS FullName,
            @SystemRolesCount AS SystemRolesAssigned,
            @TenantRolesCount AS TenantRolesAssigned,
            'User created successfully. Default password: ' + @DefaultPassword AS Message;

        -- Show assigned roles
        PRINT '';
        PRINT 'System Roles:';
        SELECT
            sr.RoleName,
            sr.Description
        FROM dbo.UserSystemRoles usr
        JOIN dbo.SystemRoles sr ON usr.SystemRoleId = sr.SystemRoleId
        WHERE usr.UserId = @NewUserId;

        PRINT '';
        PRINT 'Tenant Roles:';
        SELECT
            t.CompanyName AS Tenant,
            utr.RoleName
        FROM dbo.UserTenantRoles utr
        JOIN dbo.Tenants t ON utr.TenantId = t.TenantId
        WHERE utr.UserId = @NewUserId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        THROW 50000, @ErrorMessage, 1;
    END CATCH
END
GO

PRINT '============================================================================'
PRINT 'Stored Procedure Created: dbo.usp_CreateSuperAdmin'
PRINT '============================================================================'
PRINT ''
PRINT 'Usage Example:'
PRINT '  EXEC dbo.usp_CreateSuperAdmin'
PRINT '    @FirstName = ''Jane'','
PRINT '    @LastName = ''Smith'','
PRINT '    @Email = ''jsmith@example.com'','
PRINT '    @TemplateUserEmail = ''chris@servicevision.net'''
PRINT ''
PRINT 'Optional Parameters:'
PRINT '  @TemplateUserEmail - Email of user to copy roles from (default: chris@servicevision.net)'
PRINT '  @DefaultPassword - Default password (default: FireProofIt!)'
PRINT ''
GO
