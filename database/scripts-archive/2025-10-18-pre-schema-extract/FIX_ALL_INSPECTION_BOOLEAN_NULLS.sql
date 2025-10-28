/*============================================================================
  File:     FIX_ALL_INSPECTION_BOOLEAN_NULLS.sql
  Purpose:  Fix NULL values in BOOLEAN columns to prevent SqlNullValueException
  Date:     October 18, 2025
  Issue:    Service code calls reader.GetBoolean() without NULL checks
============================================================================*/

USE FireProofDB
GO

PRINT '============================================================================'
PRINT 'Fixing NULL Boolean Values in dbo.Inspections'
PRINT '============================================================================'

-- Fix NULL boolean columns with logical defaults
UPDATE dbo.Inspections SET LocationVerified = 0 WHERE LocationVerified IS NULL;
PRINT '✓ Fixed NULL LocationVerified values to FALSE (0)';

UPDATE dbo.Inspections SET IsAccessible = 0 WHERE IsAccessible IS NULL;
PRINT '✓ Fixed NULL IsAccessible values to FALSE (0)';

UPDATE dbo.Inspections SET HasObstructions = 0 WHERE HasObstructions IS NULL;
PRINT '✓ Fixed NULL HasObstructions values to FALSE (0)';

UPDATE dbo.Inspections SET SignageVisible = 0 WHERE SignageVisible IS NULL;
PRINT '✓ Fixed NULL SignageVisible values to FALSE (0)';

UPDATE dbo.Inspections SET SealIntact = 0 WHERE SealIntact IS NULL;
PRINT '✓ Fixed NULL SealIntact values to FALSE (0)';

UPDATE dbo.Inspections SET PinInPlace = 0 WHERE PinInPlace IS NULL;
PRINT '✓ Fixed NULL PinInPlace values to FALSE (0)';

UPDATE dbo.Inspections SET NozzleClear = 0 WHERE NozzleClear IS NULL;
PRINT '✓ Fixed NULL NozzleClear values to FALSE (0)';

UPDATE dbo.Inspections SET HoseConditionGood = 0 WHERE HoseConditionGood IS NULL;
PRINT '✓ Fixed NULL HoseConditionGood values to FALSE (0)';

UPDATE dbo.Inspections SET GaugeInGreenZone = 0 WHERE GaugeInGreenZone IS NULL;
PRINT '✓ Fixed NULL GaugeInGreenZone values to FALSE (0)';

UPDATE dbo.Inspections SET PhysicalDamagePresent = 0 WHERE PhysicalDamagePresent IS NULL;
PRINT '✓ Fixed NULL PhysicalDamagePresent values to FALSE (0)';

UPDATE dbo.Inspections SET WeightWithinSpec = 0 WHERE WeightWithinSpec IS NULL;
PRINT '✓ Fixed NULL WeightWithinSpec values to FALSE (0)';

UPDATE dbo.Inspections SET InspectionTagAttached = 0 WHERE InspectionTagAttached IS NULL;
PRINT '✓ Fixed NULL InspectionTagAttached values to FALSE (0)';

UPDATE dbo.Inspections SET Passed = 0 WHERE Passed IS NULL;
PRINT '✓ Fixed NULL Passed values to FALSE (0)';

UPDATE dbo.Inspections SET RequiresService = 0 WHERE RequiresService IS NULL;
PRINT '✓ Fixed NULL RequiresService values to FALSE (0)';

UPDATE dbo.Inspections SET RequiresReplacement = 0 WHERE RequiresReplacement IS NULL;
PRINT '✓ Fixed NULL RequiresReplacement values to FALSE (0)';

UPDATE dbo.Inspections SET IsVerified = 0 WHERE IsVerified IS NULL;
PRINT '✓ Fixed NULL IsVerified values to FALSE (0)';

PRINT ''
PRINT '============================================================================'
PRINT 'Boolean NULL Value Fixes Complete!'
PRINT '============================================================================'

-- Show updated inspection count
SELECT COUNT(*) AS TotalInspections FROM dbo.Inspections;

-- Show sample inspection with all boolean values
SELECT TOP 1
    InspectionId,
    NozzleClear,
    HoseConditionGood,
    GaugeInGreenZone,
    Passed
FROM dbo.Inspections
WHERE TenantId = '634f2b52-d32a-46dd-a045-d158e793adcb';

GO
