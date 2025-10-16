USE FireProofDB;
GO

DECLARE @TenantId UNIQUEIDENTIFIER = '634f2b52-d32a-46dd-a045-d158e793adcb';

PRINT 'Testing usp_Extinguisher_GetAll...';
BEGIN TRY
    EXEC dbo.usp_Extinguisher_GetAll @TenantId = @TenantId;
    PRINT '✓ usp_Extinguisher_GetAll succeeded';
END TRY
BEGIN CATCH
    PRINT '✗ usp_Extinguisher_GetAll FAILED:';
    PRINT ERROR_MESSAGE();
END CATCH;

PRINT '';
PRINT 'Testing usp_Location_GetAll...';
BEGIN TRY
    EXEC dbo.usp_Location_GetAll @TenantId = @TenantId;
    PRINT '✓ usp_Location_GetAll succeeded';
END TRY
BEGIN CATCH
    PRINT '✗ usp_Location_GetAll FAILED:';
    PRINT ERROR_MESSAGE();
END CATCH;

GO
