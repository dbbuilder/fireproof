/*============================================================================
  File:     FIX_NULL_INSPECTION_VALUES.sql
  Purpose:  Update NULL values in Inspections table to prevent SqlNullValueException
  Date:     October 18, 2025
  Issue:    Service code expects non-null values for certain columns
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Fixing NULL Values in dbo.Inspections'
PRINT '============================================================================'

-- Update NULL InspectionType values
UPDATE dbo.Inspections
SET InspectionType = 'Monthly'
WHERE InspectionType IS NULL;

PRINT '✓ Updated NULL InspectionType values to ''Monthly''';

-- Update NULL InspectorSignature values
UPDATE dbo.Inspections
SET InspectorSignature = ''
WHERE InspectorSignature IS NULL;

PRINT '✓ Updated NULL InspectorSignature values to empty string';

-- Update NULL SignedDate values
UPDATE dbo.Inspections
SET SignedDate = CreatedDate
WHERE SignedDate IS NULL;

PRINT '✓ Updated NULL SignedDate values to CreatedDate';

-- Update NULL DataHash values
UPDATE dbo.Inspections
SET DataHash = ''
WHERE DataHash IS NULL;

PRINT '✓ Updated NULL DataHash values to empty string';

-- Update NULL ModifiedDate values
UPDATE dbo.Inspections
SET ModifiedDate = CreatedDate
WHERE ModifiedDate IS NULL;

PRINT '✓ Updated NULL ModifiedDate values to CreatedDate';

PRINT ''
PRINT '============================================================================'
PRINT 'NULL Value Fixes Complete!'
PRINT '============================================================================'

-- Show count of inspections updated
SELECT COUNT(*) AS TotalInspections
FROM dbo.Inspections;

GO
