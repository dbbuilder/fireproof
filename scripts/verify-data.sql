USE FireProofDB;
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '634f2b52-d32a-46dd-a045-d158e793adcb';

SELECT COUNT(*) as InspectionTypesCount FROM dbo.InspectionTypes WHERE TenantId = @TenantId;
SELECT COUNT(*) as LocationsCount FROM dbo.Locations WHERE TenantId = @TenantId;
SELECT COUNT(*) as ExtinguishersCount FROM dbo.Extinguishers WHERE TenantId = @TenantId;
SELECT COUNT(*) as InspectionsCount FROM dbo.Inspections WHERE TenantId = @TenantId;

GO
