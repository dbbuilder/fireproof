using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for tenant management operations
/// </summary>
public class TenantService : ITenantService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<TenantService> _logger;

    public TenantService(
        IDbConnectionFactory connectionFactory,
        ILogger<TenantService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<IEnumerable<TenantDto>> GetAllTenantsAsync()
    {
        _logger.LogDebug("Fetching all tenants");

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_Tenant_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        var tenants = new List<TenantDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            tenants.Add(MapTenantFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} tenants", tenants.Count);

        return tenants;
    }

    public async Task<IEnumerable<TenantDto>> GetAvailableTenantsForUserAsync(Guid userId)
    {
        _logger.LogDebug("Fetching available tenants for user {UserId}", userId);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_Tenant_GetAvailableForUser";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@UserId", userId);

        var tenants = new List<TenantDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var tenant = MapTenantFromReader(reader);

            // Add role information if available
            var roleOrdinal = reader.GetOrdinal("RoleName");
            if (!reader.IsDBNull(roleOrdinal))
            {
                tenant.RoleName = reader.GetString(roleOrdinal);
            }

            tenants.Add(tenant);
        }

        _logger.LogInformation("Retrieved {Count} tenants for user {UserId}", tenants.Count, userId);

        return tenants;
    }

    public async Task<TenantDto?> GetTenantByIdAsync(Guid tenantId)
    {
        _logger.LogDebug("Fetching tenant {TenantId}", tenantId);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_Tenant_GetById";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapTenantFromReader(reader);
        }

        _logger.LogWarning("Tenant {TenantId} not found", tenantId);
        return null;
    }

    public async Task<TenantDto> CreateTenantAsync(CreateTenantRequest request)
    {
        _logger.LogInformation("Creating tenant: {TenantCode}", request.TenantCode);

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_Tenant_Create";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantCode", request.TenantCode);
        command.Parameters.AddWithValue("@CompanyName", request.TenantName);
        command.Parameters.AddWithValue("@SubscriptionTier", request.SubscriptionTier);
        command.Parameters.AddWithValue("@MaxLocations", request.MaxLocations);
        command.Parameters.AddWithValue("@MaxUsers", request.MaxUsers);
        command.Parameters.AddWithValue("@MaxExtinguishers", request.MaxExtinguishers);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var tenant = MapTenantFromReader(reader);
            _logger.LogInformation("Tenant created successfully: {TenantId}", tenant.TenantId);
            return tenant;
        }

        throw new InvalidOperationException("Failed to create tenant");
    }

    public async Task<TenantDto> UpdateTenantAsync(Guid tenantId, UpdateTenantRequest request)
    {
        _logger.LogInformation("Updating tenant {TenantId}", tenantId);

        // First verify the tenant exists
        var existingTenant = await GetTenantByIdAsync(tenantId);
        if (existingTenant == null)
        {
            throw new KeyNotFoundException($"Tenant {tenantId} not found");
        }

        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = "dbo.usp_Tenant_Update";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@CompanyName", request.TenantName);
        command.Parameters.AddWithValue("@SubscriptionTier", request.SubscriptionTier);
        command.Parameters.AddWithValue("@MaxLocations", request.MaxLocations);
        command.Parameters.AddWithValue("@MaxUsers", request.MaxUsers);
        command.Parameters.AddWithValue("@MaxExtinguishers", request.MaxExtinguishers);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var tenant = MapTenantFromReader(reader);
            _logger.LogInformation("Tenant {TenantId} updated successfully", tenantId);
            return tenant;
        }

        throw new InvalidOperationException("Failed to update tenant");
    }

    private static TenantDto MapTenantFromReader(SqlDataReader reader)
    {
        return new TenantDto
        {
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            TenantCode = reader.GetString(reader.GetOrdinal("TenantCode")),
            TenantName = reader.GetString(reader.GetOrdinal("TenantName")),
            SubscriptionTier = reader.GetString(reader.GetOrdinal("SubscriptionTier")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            MaxLocations = reader.GetInt32(reader.GetOrdinal("MaxLocations")),
            MaxUsers = reader.GetInt32(reader.GetOrdinal("MaxUsers")),
            MaxExtinguishers = reader.GetInt32(reader.GetOrdinal("MaxExtinguishers")),
            DatabaseSchema = reader.GetString(reader.GetOrdinal("DatabaseSchema")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }
}
