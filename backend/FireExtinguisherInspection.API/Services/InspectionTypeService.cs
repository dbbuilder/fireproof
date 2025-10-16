using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for inspection type management operations
/// Uses standard schema with stored procedures (shared reference data - no tenant isolation)
/// </summary>
public class InspectionTypeService : IInspectionTypeService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<InspectionTypeService> _logger;

    public InspectionTypeService(
        IDbConnectionFactory connectionFactory,
        ILogger<InspectionTypeService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<InspectionTypeDto> CreateInspectionTypeAsync(Guid tenantId, CreateInspectionTypeRequest request)
    {
        _logger.LogInformation("Creating inspection type: {TypeName}", request.TypeName);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_InspectionType_Create";

        var typeId = Guid.NewGuid();
        command.Parameters.AddWithValue("@InspectionTypeId", typeId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@TypeName", request.TypeName);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@RequiresServiceTechnician", request.RequiresServiceTechnician);
        command.Parameters.AddWithValue("@FrequencyDays", request.FrequencyDays);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var result = MapFromReader(reader);
            _logger.LogInformation("Inspection type created successfully: {InspectionTypeId}", typeId);
            return result;
        }

        throw new InvalidOperationException("Failed to create inspection type");
    }

    public async Task<IEnumerable<InspectionTypeDto>> GetAllInspectionTypesAsync(Guid tenantId, bool? isActive = null)
    {
        _logger.LogDebug("Fetching all inspection types");

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_InspectionType_GetAll";

        var types = new List<InspectionTypeDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            types.Add(MapFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} inspection types", types.Count);
        return types;
    }

    public async Task<InspectionTypeDto?> GetInspectionTypeByIdAsync(Guid tenantId, Guid inspectionTypeId)
    {
        _logger.LogDebug("Fetching inspection type {InspectionTypeId}", inspectionTypeId);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_InspectionType_GetById";
        command.Parameters.AddWithValue("@InspectionTypeId", inspectionTypeId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapFromReader(reader);
        }

        _logger.LogWarning("Inspection type {InspectionTypeId} not found", inspectionTypeId);
        return null;
    }

    public async Task<InspectionTypeDto> UpdateInspectionTypeAsync(Guid tenantId, Guid inspectionTypeId, UpdateInspectionTypeRequest request)
    {
        _logger.LogInformation("Updating inspection type {InspectionTypeId}", inspectionTypeId);

        // Update stored procedure doesn't exist yet, implement as needed
        throw new NotImplementedException("Update inspection type not yet implemented for standard schema");
    }

    public async Task<bool> DeleteInspectionTypeAsync(Guid tenantId, Guid inspectionTypeId)
    {
        _logger.LogInformation("Soft deleting inspection type {InspectionTypeId}", inspectionTypeId);

        // Soft delete via deactivation - not implemented yet
        throw new NotImplementedException("Delete inspection type not yet implemented for standard schema");
    }

    private static InspectionTypeDto MapFromReader(SqlDataReader reader)
    {
        return new InspectionTypeDto
        {
            InspectionTypeId = reader.GetGuid(reader.GetOrdinal("InspectionTypeId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            TypeName = reader.GetString(reader.GetOrdinal("TypeName")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            RequiresServiceTechnician = reader.GetBoolean(reader.GetOrdinal("RequiresServiceTechnician")),
            FrequencyDays = reader.GetInt32(reader.GetOrdinal("FrequencyDays")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }
}
