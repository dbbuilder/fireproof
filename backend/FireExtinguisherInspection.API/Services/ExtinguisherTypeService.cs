using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for fire extinguisher type management operations
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
        _logger.LogInformation("Creating extinguisher type for tenant {TenantId}: {TypeCode}", tenantId, request.TypeCode);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ExtinguisherType_Create";
        command.CommandType = CommandType.StoredProcedure;

        // Input parameters
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@TypeCode", request.TypeCode);
        command.Parameters.AddWithValue("@TypeName", request.TypeName);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@AgentType", (object?)request.AgentType ?? DBNull.Value);
        command.Parameters.AddWithValue("@Capacity", (object?)request.Capacity ?? DBNull.Value);
        command.Parameters.AddWithValue("@CapacityUnit", (object?)request.CapacityUnit ?? DBNull.Value);
        command.Parameters.AddWithValue("@FireClassRating", (object?)request.FireClassRating ?? DBNull.Value);
        command.Parameters.AddWithValue("@ServiceLifeYears", (object?)request.ServiceLifeYears ?? DBNull.Value);
        command.Parameters.AddWithValue("@HydroTestIntervalYears", (object?)request.HydroTestIntervalYears ?? DBNull.Value);

        // Output parameter
        var typeIdParam = new SqlParameter("@ExtinguisherTypeId", SqlDbType.UniqueIdentifier)
        {
            Direction = ParameterDirection.Output
        };
        command.Parameters.Add(typeIdParam);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var typeId = reader.GetGuid(reader.GetOrdinal("ExtinguisherTypeId"));
            _logger.LogInformation("Extinguisher type created successfully: {ExtinguisherTypeId}", typeId);

            return await GetExtinguisherTypeByIdAsync(tenantId, typeId)
                ?? throw new InvalidOperationException("Failed to retrieve created extinguisher type");
        }

        throw new InvalidOperationException("Failed to create extinguisher type");
    }

    public async Task<IEnumerable<ExtinguisherTypeDto>> GetAllExtinguisherTypesAsync(Guid tenantId, bool? isActive = null)
    {
        _logger.LogDebug("Fetching extinguisher types for tenant {TenantId}, isActive: {IsActive}", tenantId, isActive);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ExtinguisherType_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@IsActive", (object?)isActive ?? DBNull.Value);

        var types = new List<ExtinguisherTypeDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            types.Add(MapExtinguisherTypeFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} extinguisher types for tenant {TenantId}", types.Count, tenantId);

        return types;
    }

    public async Task<ExtinguisherTypeDto?> GetExtinguisherTypeByIdAsync(Guid tenantId, Guid extinguisherTypeId)
    {
        _logger.LogDebug("Fetching extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", extinguisherTypeId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ExtinguisherType_GetById";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@ExtinguisherTypeId", extinguisherTypeId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapExtinguisherTypeFromReader(reader);
        }

        _logger.LogWarning("Extinguisher type {ExtinguisherTypeId} not found for tenant {TenantId}", extinguisherTypeId, tenantId);
        return null;
    }

    public async Task<ExtinguisherTypeDto> UpdateExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId, UpdateExtinguisherTypeRequest request)
    {
        _logger.LogInformation("Updating extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", extinguisherTypeId, tenantId);

        // First verify the type exists
        var existingType = await GetExtinguisherTypeByIdAsync(tenantId, extinguisherTypeId);
        if (existingType == null)
        {
            throw new KeyNotFoundException($"Extinguisher type {extinguisherTypeId} not found");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].ExtinguisherTypes
            SET TypeName = @TypeName,
                Description = @Description,
                AgentType = @AgentType,
                Capacity = @Capacity,
                CapacityUnit = @CapacityUnit,
                FireClassRating = @FireClassRating,
                ServiceLifeYears = @ServiceLifeYears,
                HydroTestIntervalYears = @HydroTestIntervalYears,
                IsActive = @IsActive,
                ModifiedDate = GETUTCDATE()
            WHERE ExtinguisherTypeId = @ExtinguisherTypeId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@ExtinguisherTypeId", extinguisherTypeId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@TypeName", request.TypeName);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@AgentType", (object?)request.AgentType ?? DBNull.Value);
        command.Parameters.AddWithValue("@Capacity", (object?)request.Capacity ?? DBNull.Value);
        command.Parameters.AddWithValue("@CapacityUnit", (object?)request.CapacityUnit ?? DBNull.Value);
        command.Parameters.AddWithValue("@FireClassRating", (object?)request.FireClassRating ?? DBNull.Value);
        command.Parameters.AddWithValue("@ServiceLifeYears", (object?)request.ServiceLifeYears ?? DBNull.Value);
        command.Parameters.AddWithValue("@HydroTestIntervalYears", (object?)request.HydroTestIntervalYears ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected == 0)
        {
            throw new InvalidOperationException("Failed to update extinguisher type");
        }

        _logger.LogInformation("Extinguisher type {ExtinguisherTypeId} updated successfully", extinguisherTypeId);

        return await GetExtinguisherTypeByIdAsync(tenantId, extinguisherTypeId)
            ?? throw new InvalidOperationException("Failed to retrieve updated extinguisher type");
    }

    public async Task<bool> DeleteExtinguisherTypeAsync(Guid tenantId, Guid extinguisherTypeId)
    {
        _logger.LogInformation("Deleting extinguisher type {ExtinguisherTypeId} for tenant {TenantId}", extinguisherTypeId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        // Soft delete by setting IsActive = 0
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].ExtinguisherTypes
            SET IsActive = 0,
                ModifiedDate = GETUTCDATE()
            WHERE ExtinguisherTypeId = @ExtinguisherTypeId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@ExtinguisherTypeId", extinguisherTypeId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected > 0)
        {
            _logger.LogInformation("Extinguisher type {ExtinguisherTypeId} deleted successfully", extinguisherTypeId);
            return true;
        }

        _logger.LogWarning("Extinguisher type {ExtinguisherTypeId} not found or already deleted", extinguisherTypeId);
        return false;
    }

    private static ExtinguisherTypeDto MapExtinguisherTypeFromReader(SqlDataReader reader)
    {
        return new ExtinguisherTypeDto
        {
            ExtinguisherTypeId = reader.GetGuid(reader.GetOrdinal("ExtinguisherTypeId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            TypeCode = reader.GetString(reader.GetOrdinal("TypeCode")),
            TypeName = reader.GetString(reader.GetOrdinal("TypeName")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            AgentType = reader.IsDBNull(reader.GetOrdinal("AgentType")) ? null : reader.GetString(reader.GetOrdinal("AgentType")),
            Capacity = reader.IsDBNull(reader.GetOrdinal("Capacity")) ? null : reader.GetDecimal(reader.GetOrdinal("Capacity")),
            CapacityUnit = reader.IsDBNull(reader.GetOrdinal("CapacityUnit")) ? null : reader.GetString(reader.GetOrdinal("CapacityUnit")),
            FireClassRating = reader.IsDBNull(reader.GetOrdinal("FireClassRating")) ? null : reader.GetString(reader.GetOrdinal("FireClassRating")),
            ServiceLifeYears = reader.IsDBNull(reader.GetOrdinal("ServiceLifeYears")) ? null : reader.GetInt32(reader.GetOrdinal("ServiceLifeYears")),
            HydroTestIntervalYears = reader.IsDBNull(reader.GetOrdinal("HydroTestIntervalYears")) ? null : reader.GetInt32(reader.GetOrdinal("HydroTestIntervalYears")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }
}
