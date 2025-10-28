/*============================================================================
  File:     FIX_ALL_INSPECTION_NULLS.sql
  Purpose:  Comprehensive NULL value fix for ALL inspection columns
  Date:     October 18, 2025
  Issue:    Ensure NO NULL values in columns that service code expects
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Comprehensive NULL Fix for ALL Inspection Columns'
PRINT '============================================================================'

-- Update ALL NULL string columns to empty string or defaults
UPDATE dbo.Inspections SET InspectionType = 'Monthly' WHERE InspectionType IS NULL OR LEN(LTRIM(RTRIM(InspectionType))) = 0;
UPDATE dbo.Inspections SET InspectorSignature = '' WHERE InspectorSignature IS NULL;
UPDATE dbo.Inspections SET DataHash = '' WHERE DataHash IS NULL;
UPDATE dbo.Inspections SET DamageDescription = '' WHERE DamageDescription IS NULL;
UPDATE dbo.Inspections SET Notes = '' WHERE Notes IS NULL;
UPDATE dbo.Inspections SET FailureReason = '' WHERE FailureReason IS NULL;
UPDATE dbo.Inspections SET CorrectiveAction = '' WHERE CorrectiveAction IS NULL;
UPDATE dbo.Inspections SET PhotoUrls = '' WHERE PhotoUrls IS NULL;
UPDATE dbo.Inspections SET PreviousInspectionDate = '' WHERE PreviousInspectionDate IS NULL;

-- Update NULL datetime columns
UPDATE dbo.Inspections SET SignedDate = CreatedDate WHERE SignedDate IS NULL;
UPDATE dbo.Inspections SET ModifiedDate = CreatedDate WHERE ModifiedDate IS NULL;

PRINT '✓ Fixed all NULL string and datetime values';

-- Show inspection count and sample data
SELECT COUNT(*) AS TotalInspections FROM dbo.Inspections;

SELECT TOP 1
    InspectionId,
    InspectionType,
    InspectorSignature,
    DataHash,
    SignedDate,
    ModifiedDate
FROM dbo.Inspections
WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';

PRINT ''
PRINT '============================================================================'
PRINT 'Comprehensive NULL Fix Complete!'
PRINT '============================================================================'

GO
