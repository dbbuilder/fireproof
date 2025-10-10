/*============================================================================
  SCRIPT: 007_FixGetByIdProcedure.sql
  Description: Update usp_User_GetById to include password fields for reset password
============================================================================*/

USE FireProofDB
GO

PRINT 'Updating usp_User_GetById to include password fields...'

-- Drop existing procedure
IF OBJECT_ID('dbo.usp_User_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_User_GetById
GO

-- Recreate with password fields
CREATE PROCEDURE dbo.usp_User_GetById
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON

    SELECT
        UserId,
        Email,
        FirstName,
        LastName,
        PasswordHash,
        PasswordSalt,
        RefreshToken,
        RefreshTokenExpiryDate,
        LastLoginDate,
        PhoneNumber,
        EmailConfirmed,
        MfaEnabled,
        AzureAdB2CObjectId,
        IsActive,
        CreatedDate,
        ModifiedDate
    FROM dbo.Users
    WHERE UserId = @UserId
END
GO

PRINT '  - Updated usp_User_GetById with password fields'
PRINT 'Update complete!'
