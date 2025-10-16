using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for fire extinguisher type management operations
/// Uses standard schema with stored procedures (shared reference data - no tenant isolation)
/// </summary>
public class ExtinguisherTypeService : IExtinguisherTypeService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<ExtinguisherTypeService> _logger;

    public ExtinguisherTypeService(
        IDbConnectionFactory connectionFactory,
        ILogger<ExtinguisherTypeService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<ExtinguisherTypeDto> CreateExtinguisherTypeAsync(Guid tenantId, CreateExtinguisherTypeRequest request)
    {
        _logger.LogInformation("Creating extinguisher type: {TypeCode}", request.TypeCode);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_ExtinguisherType_Create";

        var typeId = Guid.NewGuid();
        command.Parameters.AddWithValue("@ExtinguisherTypeId", typeId);
        command.Parameters.AddWithValue("@TypeCode", request.TypeCode);
        command.Parameters.AddWithValue("@TypeName", request.TypeName);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@MonthlyInspectionRequired", request.MonthlyInspectionRequired);
        command.Parameters.AddWithValue("@AnnualInspectionRequired", request.AnnualInspectionRequired);
        command.Parameters.AddWithValue("@HydrostaticTestYears", (object?)request.HydrostaticTestYears ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var result = MapFromReader(reader, tenantId);
            _logger.LogInformation("Extinguisher type created successfully: {ExtinguisherTypeId}", typeId);
            return result;
        }

        throw new InvalidOperationException("Failed to create extinguisher type");
    }

    public async Task<IEnumerable<ExtinguisherTypeDto>> GetAllExtinguisherTypesAsync(Guid tenantId, bool? isActive = null)
    {
        _logger.LogDebug("Fetching all extinguisher types");

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_ExtinguisherType_GetAll";

        var types = new List<ExtinguisherTypeDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            types.Add(MapFromReader(reader, tenantId));
        }

        _logger.LogInformation("Retrieved {Count} extinguisher types", types.Count);
        return types;
    }

    public async Task<ExtinguisherTypeDto?> GetExtinguisherTypeByIdAsync(Guid tenantId, Guid extinguisherTypeId)
    {
        _logger.LogDebug("Fetching extinguisher type {ExtinguisherTypeId}", extinguisherTypeId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_ExtinguisherType_GetById";
        command.Parameters.AddWithValue("@ExtinguisherTypeId", extinguisherTypeId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapFromReader(reader, tenantId);
        }

        _logger.LogWarning("Extinguisher type {ExtinguisherTypeId} not found", extinguisherTypeId);
        return null;
    }

    public async Task<ExtinguisherTypeDto> UpdateExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId, UpdateExtinguisherTypeRequest request)
    {
        _logger.LogInformation("Updating extinguisher type {ExtinguisherTypeId}", extinguisherTypeId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_ExtinguisherType_Update";

        command.Parameters.AddWithValue("@ExtinguisherTypeId", extinguisherTypeId);
        command.Parameters.AddWithValue("@TypeCode", string.Empty); // Cannot update TypeCode
        command.Parameters.AddWithValue("@TypeName", request.TypeName);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@MonthlyInspectionRequired", request.MonthlyInspectionRequired);
        command.Parameters.AddWithValue("@AnnualInspectionRequired", request.AnnualInspectionRequired);
        command.Parameters.AddWithValue("@HydrostaticTestYears", (object?)request.HydrostaticTestYears ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var result = MapFromReader(reader, tenantId);
            _logger.LogInformation("Extinguisher type {ExtinguisherTypeId} updated successfully", extinguisherTypeId);
            return result;
        }

        throw new InvalidOperationException("Failed to update extinguisher type");
    }

    public async Task<bool> DeleteExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId)
    {
        _logger.LogInformation("Soft deleting extinguisher type {ExtinguisherTypeId}", extinguisherTypeId);

        // Soft delete via update
        var type = await GetExtinguisherTypeByIdAsync(tenantId, extinguisherTypeId);
        if (type == null)
        {
            return false;
        }

        var updateRequest = new UpdateExtinguisherTypeRequest
        {
            TypeName = type.TypeName,
            Description = type.Description,
            MonthlyInspectionRequired = type.MonthlyInspectionRequired,
            AnnualInspectionRequired = type.AnnualInspectionRequired,
            HydrostaticTestYears = type.HydrostaticTestYears,
            IsActive = false
        };

        await UpdateExtinguisherTypeAsync(tenantId, extinguisherTypeId, updateRequest);
        _logger.LogInformation("Extinguisher type {ExtinguisherTypeId} deleted successfully", extinguisherTypeId);
        return true;
    }

    private static ExtinguisherTypeDto MapFromReader(SqlDataReader reader, Guid tenantId)
    {
        return new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = reader.GetGuid(reader.GetOrdinal("ExtinguisherTypeId")),
            TenantId = tenantId, // Populate with request tenantId for compatibility
            TypeCode = reader.GetString(reader.GetOrdinal("TypeCode")),
            TypeName = reader.GetString(reader.GetOrdinal("TypeName")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            MonthlyInspectionRequired = reader.GetBoolean(reader.GetOrdinal("MonthlyInspectionRequired")),
            AnnualInspectionRequired = reader.GetBoolean(reader.GetOrdinal("AnnualInspectionRequired")),
            HydrostaticTestYears = reader.IsDBNull(reader.GetOrdinal("HydrostaticTestYears")) ? null : reader.GetInt32(reader.GetOrdinal("HydrostaticTestYears")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }
}
