-- Check if stored procedures exist
USE FireProofDB;
GO

PRINT 'Checking for stored procedures...';

SELECT
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date,
    modify_date
FROM sys.procedures
WHERE name LIKE 'usp_Extinguisher%' OR name LIKE 'usp_Location%' OR name LIKE 'usp_Inspection%'
ORDER BY name;

GO
