USE FireProofDB;
GO

SELECT
    t.name AS TableName,
    COUNT(c.column_id) AS ColumnCount
FROM sys.tables t
LEFT JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('Extinguishers', 'Locations', 'Inspections', 'InspectionTypes', 'ExtinguisherTypes')
GROUP BY t.name
ORDER BY t.name;

GO
