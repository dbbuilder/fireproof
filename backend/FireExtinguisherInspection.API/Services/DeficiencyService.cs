using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for inspection deficiency management
/// </summary>
public class DeficiencyService : IDeficiencyService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<DeficiencyService> _logger;

    public DeficiencyService(
        IDbConnectionFactory connectionFactory,
        ILogger<DeficiencyService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<InspectionDeficiencyDto> CreateDeficiencyAsync(Guid tenantId, CreateDeficiencyRequest request)
    {
        _logger.LogInformation("Creating deficiency for inspection {InspectionId}: {DeficiencyType} - {Severity}",
            request.InspectionId, request.DeficiencyType, request.Severity);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_InspectionDeficiency_Create";
        command.CommandType = CommandType.StoredProcedure;

        var deficiencyId = Guid.NewGuid();
        command.Parameters.AddWithValue("@DeficiencyId", deficiencyId).Direction = ParameterDirection.InputOutput;
        command.Parameters.AddWithValue("@InspectionId", request.InspectionId);
        command.Parameters.AddWithValue("@DeficiencyType", request.DeficiencyType);
        command.Parameters.AddWithValue("@Severity", request.Severity);
        command.Parameters.AddWithValue("@Description", request.Description);
        command.Parameters.AddWithValue("@ActionRequired", (object?)request.ActionRequired ?? DBNull.Value);
        command.Parameters.AddWithValue("@EstimatedCost", (object?)request.EstimatedCost ?? DBNull.Value);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        await command.ExecuteNonQueryAsync();

        var createdDeficiencyId = (Guid)command.Parameters["@DeficiencyId"].Value;
        _logger.LogInformation("Deficiency created successfully: {DeficiencyId}", createdDeficiencyId);

        // Fetch the created deficiency to return full details
        return await GetDeficiencyByIdAsync(tenantId, createdDeficiencyId)
            ?? throw new InvalidOperationException("Failed to retrieve created deficiency");
    }

    public async Task<InspectionDeficiencyDto?> GetDeficiencyByIdAsync(Guid tenantId, Guid deficiencyId)
    {
        _logger.LogDebug("Fetching deficiency {DeficiencyId} for tenant {TenantId}", deficiencyId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            SELECT
                d.*,
                e.AssetTag AS ExtinguisherAssetTag,
                e.BarcodeData AS ExtinguisherBarcode,
                l.LocationName,
                u1.FirstName + ' ' + u1.LastName AS AssignedToName,
                u2.FirstName + ' ' + u2.LastName AS ResolvedByName
            FROM [{schemaName}].InspectionDeficiencies d
            INNER JOIN [{schemaName}].Inspections i ON d.InspectionId = i.InspectionId
            INNER JOIN [{schemaName}].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
            INNER JOIN [{schemaName}].Locations l ON e.LocationId = l.LocationId
            LEFT JOIN dbo.Users u1 ON d.AssignedToUserId = u1.UserId
            LEFT JOIN dbo.Users u2 ON d.ResolvedByUserId = u2.UserId
            WHERE d.DeficiencyId = @DeficiencyId";

        command.Parameters.AddWithValue("@DeficiencyId", deficiencyId);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            return MapDeficiencyFromReader(reader);
        }

        _logger.LogWarning("Deficiency {DeficiencyId} not found for tenant {TenantId}", deficiencyId, tenantId);
        return null;
    }

    public async Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesByInspectionAsync(Guid tenantId, Guid inspectionId)
    {
        _logger.LogDebug("Fetching deficiencies for inspection {InspectionId}", inspectionId);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_InspectionDeficiency_GetByInspection";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var deficiencies = new List<InspectionDeficiencyDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            deficiencies.Add(MapDeficiencyFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} deficiencies for inspection {InspectionId}",
            deficiencies.Count, inspectionId);

        return deficiencies;
    }

    public async Task<IEnumerable<InspectionDeficiencyDto>> GetOpenDeficienciesAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        _logger.LogDebug("Fetching open deficiencies for tenant {TenantId}", tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_InspectionDeficiency_GetOpen";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        var deficiencies = new List<InspectionDeficiencyDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            deficiencies.Add(MapDeficiencyFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} open deficiencies for tenant {TenantId}",
            deficiencies.Count, tenantId);

        return deficiencies;
    }

    public async Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesBySeverityAsync(
        Guid tenantId,
        string severity,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        _logger.LogDebug("Fetching {Severity} deficiencies for tenant {TenantId}", severity, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_InspectionDeficiency_GetBySeverity";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@Severity", severity);
        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        var deficiencies = new List<InspectionDeficiencyDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            deficiencies.Add(MapDeficiencyFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} {Severity} deficiencies for tenant {TenantId}",
            deficiencies.Count, severity, tenantId);

        return deficiencies;
    }

    public async Task<IEnumerable<InspectionDeficiencyDto>> GetDeficienciesByAssigneeAsync(
        Guid tenantId,
        Guid assignedToUserId,
        bool openOnly = true)
    {
        _logger.LogDebug("Fetching deficiencies assigned to user {AssignedToUserId}", assignedToUserId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            SELECT
                d.*,
                e.AssetTag AS ExtinguisherAssetTag,
                e.BarcodeData AS ExtinguisherBarcode,
                l.LocationName,
                u1.FirstName + ' ' + u1.LastName AS AssignedToName,
                u2.FirstName + ' ' + u2.LastName AS ResolvedByName
            FROM [{schemaName}].InspectionDeficiencies d
            INNER JOIN [{schemaName}].Inspections i ON d.InspectionId = i.InspectionId
            INNER JOIN [{schemaName}].Extinguishers e ON i.ExtinguisherId = e.ExtinguisherId
            INNER JOIN [{schemaName}].Locations l ON e.LocationId = l.LocationId
            LEFT JOIN dbo.Users u1 ON d.AssignedToUserId = u1.UserId
            LEFT JOIN dbo.Users u2 ON d.ResolvedByUserId = u2.UserId
            WHERE d.AssignedToUserId = @AssignedToUserId";

        if (openOnly)
        {
            command.CommandText += " AND d.Status IN ('Open', 'InProgress')";
        }

        command.CommandText += " ORDER BY d.CreatedDate DESC";

        command.Parameters.AddWithValue("@AssignedToUserId", assignedToUserId);

        var deficiencies = new List<InspectionDeficiencyDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            deficiencies.Add(MapDeficiencyFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} deficiencies assigned to user {AssignedToUserId}",
            deficiencies.Count, assignedToUserId);

        return deficiencies;
    }

    public async Task<InspectionDeficiencyDto> UpdateDeficiencyAsync(
        Guid tenantId,
        Guid deficiencyId,
        UpdateDeficiencyRequest request)
    {
        _logger.LogInformation("Updating deficiency {DeficiencyId}", deficiencyId);

        // Verify deficiency exists
        var existingDeficiency = await GetDeficiencyByIdAsync(tenantId, deficiencyId);
        if (existingDeficiency == null)
        {
            throw new KeyNotFoundException($"Deficiency {deficiencyId} not found");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_InspectionDeficiency_Update";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@DeficiencyId", deficiencyId);
        command.Parameters.AddWithValue("@Status", (object?)request.Status ?? DBNull.Value);
        command.Parameters.AddWithValue("@ActionRequired", (object?)request.ActionRequired ?? DBNull.Value);
        command.Parameters.AddWithValue("@EstimatedCost", (object?)request.EstimatedCost ?? DBNull.Value);
        command.Parameters.AddWithValue("@AssignedToUserId", (object?)request.AssignedToUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("@DueDate", (object?)request.DueDate ?? DBNull.Value);

        await command.ExecuteNonQueryAsync();

        _logger.LogInformation("Deficiency {DeficiencyId} updated successfully", deficiencyId);

        return await GetDeficiencyByIdAsync(tenantId, deficiencyId)
            ?? throw new InvalidOperationException("Failed to retrieve updated deficiency");
    }

    public async Task<InspectionDeficiencyDto> ResolveDeficiencyAsync(
        Guid tenantId,
        Guid deficiencyId,
        ResolveDeficiencyRequest request)
    {
        _logger.LogInformation("Resolving deficiency {DeficiencyId} by user {ResolvedByUserId}",
            deficiencyId, request.ResolvedByUserId);

        // Verify deficiency exists
        var existingDeficiency = await GetDeficiencyByIdAsync(tenantId, deficiencyId);
        if (existingDeficiency == null)
        {
            throw new KeyNotFoundException($"Deficiency {deficiencyId} not found");
        }

        if (existingDeficiency.Status == "Resolved")
        {
            throw new InvalidOperationException("Deficiency is already resolved");
        }

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_InspectionDeficiency_Resolve";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@DeficiencyId", deficiencyId);
        command.Parameters.AddWithValue("@ResolvedByUserId", request.ResolvedByUserId);
        command.Parameters.AddWithValue("@ResolutionNotes", (object?)request.ResolutionNotes ?? DBNull.Value);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        await command.ExecuteNonQueryAsync();

        _logger.LogInformation("Deficiency {DeficiencyId} resolved successfully", deficiencyId);

        return await GetDeficiencyByIdAsync(tenantId, deficiencyId)
            ?? throw new InvalidOperationException("Failed to retrieve resolved deficiency");
    }

    public async Task<bool> DeleteDeficiencyAsync(Guid tenantId, Guid deficiencyId)
    {
        _logger.LogInformation("Deleting deficiency {DeficiencyId} for tenant {TenantId}", deficiencyId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        // Soft delete by setting Status = 'Deleted'
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].InspectionDeficiencies
            SET Status = 'Deleted',
                ModifiedDate = GETUTCDATE()
            WHERE DeficiencyId = @DeficiencyId";

        command.Parameters.AddWithValue("@DeficiencyId", deficiencyId);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected > 0)
        {
            _logger.LogInformation("Deficiency {DeficiencyId} deleted successfully", deficiencyId);
            return true;
        }

        _logger.LogWarning("Deficiency {DeficiencyId} not found or already deleted", deficiencyId);
        return false;
    }

    #region Private Helper Methods

    private static InspectionDeficiencyDto MapDeficiencyFromReader(SqlDataReader reader)
    {
        // Parse PhotoIds JSON array
        List<Guid>? photoIds = null;
        if (!reader.IsDBNull(reader.GetOrdinal("PhotoIds")))
        {
            var photoIdsJson = reader.GetString(reader.GetOrdinal("PhotoIds"));
            if (!string.IsNullOrWhiteSpace(photoIdsJson))
            {
                try
                {
                    photoIds = System.Text.Json.JsonSerializer.Deserialize<List<Guid>>(photoIdsJson);
                }
                catch
                {
                    // If JSON parsing fails, leave as null
                    photoIds = null;
                }
            }
        }

        return new InspectionDeficiencyDto
        {
            DeficiencyId = reader.GetGuid(reader.GetOrdinal("DeficiencyId")),
            InspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId")),
            DeficiencyType = reader.GetString(reader.GetOrdinal("DeficiencyType")),
            Severity = reader.GetString(reader.GetOrdinal("Severity")),
            Description = reader.GetString(reader.GetOrdinal("Description")),
            Status = reader.GetString(reader.GetOrdinal("Status")),
            ActionRequired = reader.IsDBNull(reader.GetOrdinal("ActionRequired")) ? null : reader.GetString(reader.GetOrdinal("ActionRequired")),
            EstimatedCost = reader.IsDBNull(reader.GetOrdinal("EstimatedCost")) ? null : reader.GetDecimal(reader.GetOrdinal("EstimatedCost")),
            AssignedToUserId = reader.IsDBNull(reader.GetOrdinal("AssignedToUserId")) ? null : reader.GetGuid(reader.GetOrdinal("AssignedToUserId")),
            DueDate = reader.IsDBNull(reader.GetOrdinal("DueDate")) ? null : reader.GetDateTime(reader.GetOrdinal("DueDate")),
            ResolutionNotes = reader.IsDBNull(reader.GetOrdinal("ResolutionNotes")) ? null : reader.GetString(reader.GetOrdinal("ResolutionNotes")),
            ResolvedDate = reader.IsDBNull(reader.GetOrdinal("ResolvedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ResolvedDate")),
            ResolvedByUserId = reader.IsDBNull(reader.GetOrdinal("ResolvedByUserId")) ? null : reader.GetGuid(reader.GetOrdinal("ResolvedByUserId")),
            PhotoIds = photoIds,
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedDate")),
            // Navigation properties
            ExtinguisherAssetTag = HasColumn(reader, "ExtinguisherAssetTag") && !reader.IsDBNull(reader.GetOrdinal("ExtinguisherAssetTag"))
                ? reader.GetString(reader.GetOrdinal("ExtinguisherAssetTag")) : null,
            ExtinguisherBarcode = HasColumn(reader, "ExtinguisherBarcode") && !reader.IsDBNull(reader.GetOrdinal("ExtinguisherBarcode"))
                ? reader.GetString(reader.GetOrdinal("ExtinguisherBarcode")) : null,
            LocationName = HasColumn(reader, "LocationName") && !reader.IsDBNull(reader.GetOrdinal("LocationName"))
                ? reader.GetString(reader.GetOrdinal("LocationName")) : null,
            AssignedToName = HasColumn(reader, "AssignedToName") && !reader.IsDBNull(reader.GetOrdinal("AssignedToName"))
                ? reader.GetString(reader.GetOrdinal("AssignedToName")) : null,
            ResolvedByName = HasColumn(reader, "ResolvedByName") && !reader.IsDBNull(reader.GetOrdinal("ResolvedByName"))
                ? reader.GetString(reader.GetOrdinal("ResolvedByName")) : null
        };
    }

    private static bool HasColumn(SqlDataReader reader, string columnName)
    {
        for (int i = 0; i < reader.FieldCount; i++)
        {
            if (reader.GetName(i).Equals(columnName, StringComparison.OrdinalIgnoreCase))
                return true;
        }
        return false;
    }

    #endregion
}
