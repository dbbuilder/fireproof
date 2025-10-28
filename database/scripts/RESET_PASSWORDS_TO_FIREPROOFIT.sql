/*============================================================================
  File:     RESET_PASSWORDS_TO_FIREPROOFIT.sql
  Purpose:  Reset Jon and Charlotte passwords to "FireProofIt!"
  Date:     October 18, 2025
  Password: FireProofIt!
============================================================================*/

USE FireProofDB
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

PRINT '============================================================================'
PRINT 'Resetting Passwords to FireProofIt!'
PRINT '============================================================================'

-- Update Jon Dunn's password to "FireProofIt!"
UPDATE dbo.Users
SET PasswordHash = '$2a$12$bVHRanQb9FoMMLeU2Hob3en990lJPsop/vaTVtb8YUssNBF.9S7GW',
    PasswordSalt = '$2a$12$bVHRanQb9FoMMLeU2Hob3e'
WHERE Email = 'jdunn@2amarketing.com';

PRINT '✓ Reset password for jdunn@2amarketing.com to FireProofIt!';

-- Update Charlotte Payne's password to "FireProofIt!"
UPDATE dbo.Users
SET PasswordHash = '$2a$12$bVHRanQb9FoMMLeU2Hob3en990lJPsop/vaTVtb8YUssNBF.9S7GW',
    PasswordSalt = '$2a$12$bVHRanQb9FoMMLeU2Hob3e'
WHERE Email = 'cpayne4@kumc.edu';

PRINT '✓ Reset password for cpayne4@kumc.edu to FireProofIt!';

PRINT ''
PRINT '============================================================================'
PRINT 'Password Reset Complete!'
PRINT '============================================================================'
PRINT 'Both users can now login with password: FireProofIt!'
PRINT ''

-- Verify the update
SELECT
    Email,
    FirstName + ' ' + LastName AS FullName,
    'Password: FireProofIt!' AS Credentials
FROM dbo.Users
WHERE Email IN ('jdunn@2amarketing.com', 'cpayne4@kumc.edu')
ORDER BY Email;

GO
