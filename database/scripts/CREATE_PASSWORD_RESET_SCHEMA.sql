/*============================================================================
  File:     CREATE_PASSWORD_RESET_SCHEMA.sql
  Purpose:  Create password reset functionality
  Date:     October 18, 2025
  Usage:    sqlcmd -S server -d FireProofDB -U user -P password -i CREATE_PASSWORD_RESET_SCHEMA.sql
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create PasswordResetTokens table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PasswordResetTokens')
BEGIN
    CREATE TABLE dbo.PasswordResetTokens (
        TokenId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
        UserId UNIQUEIDENTIFIER NOT NULL,
        Token NVARCHAR(500) NOT NULL,
        ExpiresAt DATETIME2 NOT NULL,
        IsUsed BIT NOT NULL DEFAULT 0,
        UsedAt DATETIME2 NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT FK_PasswordResetTokens_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
    )

    CREATE NONCLUSTERED INDEX IX_PasswordResetTokens_Token ON dbo.PasswordResetTokens(Token)
    CREATE NONCLUSTERED INDEX IX_PasswordResetTokens_UserId ON dbo.PasswordResetTokens(UserId)
    CREATE NONCLUSTERED INDEX IX_PasswordResetTokens_ExpiresAt ON dbo.PasswordResetTokens(ExpiresAt)

    PRINT '✓ Created PasswordResetTokens table'
END
ELSE
    PRINT '  PasswordResetTokens table already exists'
GO

-- Stored Procedure: Create Password Reset Token
CREATE OR ALTER PROCEDURE dbo.usp_PasswordResetToken_Create
    @Email NVARCHAR(256),
    @Token NVARCHAR(500),
    @ExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER
    DECLARE @TokenId UNIQUEIDENTIFIER = NEWID()

    BEGIN TRY
        -- Find user by email
        SELECT @UserId = UserId
        FROM dbo.Users
        WHERE Email = @Email
          AND IsActive = 1

        IF @UserId IS NULL
        BEGIN
            -- Don't reveal if email exists or not (security)
            -- Return success anyway
            SELECT @TokenId AS TokenId, 0 AS UserExists
            RETURN
        END

        -- Invalidate any existing unused tokens for this user
        UPDATE dbo.PasswordResetTokens
        SET IsUsed = 1,
            UsedAt = GETUTCDATE()
        WHERE UserId = @UserId
          AND IsUsed = 0
          AND ExpiresAt > GETUTCDATE()

        -- Create new token
        INSERT INTO dbo.PasswordResetTokens (TokenId, UserId, Token, ExpiresAt, IsUsed, CreatedDate)
        VALUES (@TokenId, @UserId, @Token, @ExpiresAt, 0, GETUTCDATE())

        -- Return token info and user details
        SELECT
            @TokenId AS TokenId,
            1 AS UserExists,
            @UserId AS UserId,
            @Email AS Email,
            u.FirstName,
            u.LastName
        FROM dbo.Users u
        WHERE u.UserId = @UserId

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrMsg, 16, 1)
    END CATCH
END
GO

-- Stored Procedure: Validate Password Reset Token
CREATE OR ALTER PROCEDURE dbo.usp_PasswordResetToken_Validate
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TokenId,
        t.UserId,
        t.Token,
        t.ExpiresAt,
        t.IsUsed,
        u.Email,
        u.FirstName,
        u.LastName,
        CASE
            WHEN t.IsUsed = 1 THEN 'Already Used'
            WHEN t.ExpiresAt < GETUTCDATE() THEN 'Expired'
            ELSE 'Valid'
        END AS TokenStatus
    FROM dbo.PasswordResetTokens t
    JOIN dbo.Users u ON t.UserId = u.UserId
    WHERE t.Token = @Token
END
GO

-- Stored Procedure: Reset Password with Token
CREATE OR ALTER PROCEDURE dbo.usp_PasswordResetToken_ResetPassword
    @Token NVARCHAR(500),
    @NewPasswordHash NVARCHAR(500),
    @NewPasswordSalt NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER
    DECLARE @TokenId UNIQUEIDENTIFIER
    DECLARE @IsUsed BIT
    DECLARE @ExpiresAt DATETIME2
    DECLARE @ErrorMessage NVARCHAR(4000)

    BEGIN TRY
        BEGIN TRANSACTION

        -- Get token details
        SELECT
            @TokenId = TokenId,
            @UserId = UserId,
            @IsUsed = IsUsed,
            @ExpiresAt = ExpiresAt
        FROM dbo.PasswordResetTokens
        WHERE Token = @Token

        IF @TokenId IS NULL
        BEGIN
            SET @ErrorMessage = 'Invalid password reset token'
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN
        END

        IF @IsUsed = 1
        BEGIN
            SET @ErrorMessage = 'This password reset token has already been used'
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN
        END

        IF @ExpiresAt < GETUTCDATE()
        BEGIN
            SET @ErrorMessage = 'This password reset token has expired'
            RAISERROR(@ErrorMessage, 16, 1)
            RETURN
        END

        -- Update user password
        UPDATE dbo.Users
        SET PasswordHash = @NewPasswordHash,
            PasswordSalt = @NewPasswordSalt,
            ModifiedDate = GETUTCDATE()
        WHERE UserId = @UserId

        -- Mark token as used
        UPDATE dbo.PasswordResetTokens
        SET IsUsed = 1,
            UsedAt = GETUTCDATE()
        WHERE TokenId = @TokenId

        COMMIT TRANSACTION

        -- Return success
        SELECT
            @UserId AS UserId,
            u.Email,
            u.FirstName + ' ' + u.LastName AS FullName,
            'Password reset successful' AS Message
        FROM dbo.Users u
        WHERE u.UserId = @UserId

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        DECLARE @ErrMsg2 NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR(@ErrMsg2, 16, 1)
    END CATCH
END
GO

-- Stored Procedure: Cleanup Expired Tokens (for background job)
CREATE OR ALTER PROCEDURE dbo.usp_PasswordResetToken_CleanupExpired
    @DaysToKeep INT = 7
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CutoffDate DATETIME2 = DATEADD(DAY, -@DaysToKeep, GETUTCDATE())
    DECLARE @DeletedCount INT

    DELETE FROM dbo.PasswordResetTokens
    WHERE ExpiresAt < @CutoffDate

    SET @DeletedCount = @@ROWCOUNT

    SELECT
        @DeletedCount AS TokensDeleted,
        @CutoffDate AS CutoffDate,
        'Cleanup completed successfully' AS Message
END
GO

PRINT ''
PRINT '============================================================================'
PRINT 'Password Reset Schema Created Successfully'
PRINT '============================================================================'
PRINT 'Tables:'
PRINT '  ✓ PasswordResetTokens'
PRINT ''
PRINT 'Stored Procedures:'
PRINT '  ✓ usp_PasswordResetToken_Create'
PRINT '  ✓ usp_PasswordResetToken_Validate'
PRINT '  ✓ usp_PasswordResetToken_ResetPassword'
PRINT '  ✓ usp_PasswordResetToken_CleanupExpired'
PRINT ''
PRINT 'Indexes:'
PRINT '  ✓ IX_PasswordResetTokens_Token'
PRINT '  ✓ IX_PasswordResetTokens_UserId'
PRINT '  ✓ IX_PasswordResetTokens_ExpiresAt'
PRINT ''
GO
