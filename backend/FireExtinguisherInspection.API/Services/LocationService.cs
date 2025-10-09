using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for location management operations
/// </summary>
public class LocationService : ILocationService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<LocationService> _logger;

    public LocationService(
        IDbConnectionFactory connectionFactory,
        ILogger<LocationService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<LocationDto> CreateLocationAsync(Guid tenantId, CreateLocationRequest request)
    {
        _logger.LogInformation("Creating location for tenant {TenantId}: {LocationCode}", tenantId, request.LocationCode);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Location_Create";
        command.CommandType = CommandType.StoredProcedure;

        // Input parameters
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationCode", request.LocationCode);
        command.Parameters.AddWithValue("@LocationName", request.LocationName);
        command.Parameters.AddWithValue("@AddressLine1", (object?)request.AddressLine1 ?? DBNull.Value);
        command.Parameters.AddWithValue("@AddressLine2", (object?)request.AddressLine2 ?? DBNull.Value);
        command.Parameters.AddWithValue("@City", (object?)request.City ?? DBNull.Value);
        command.Parameters.AddWithValue("@StateProvince", (object?)request.StateProvince ?? DBNull.Value);
        command.Parameters.AddWithValue("@PostalCode", (object?)request.PostalCode ?? DBNull.Value);
        command.Parameters.AddWithValue("@Country", (object?)request.Country ?? DBNull.Value);
        command.Parameters.AddWithValue("@Latitude", (object?)request.Latitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@Longitude", (object?)request.Longitude ?? DBNull.Value);

        // Output parameter
        var locationIdParam = new SqlParameter("@LocationId", SqlDbType.UniqueIdentifier)
        {
            Direction = ParameterDirection.Output
        };
        command.Parameters.Add(locationIdParam);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var locationId = reader.GetGuid(reader.GetOrdinal("LocationId"));
            var barcodeData = reader.GetString(reader.GetOrdinal("BarcodeData"));

            _logger.LogInformation("Location created successfully: {LocationId}", locationId);

            // Fetch the created location to return full details
            return await GetLocationByIdAsync(tenantId, locationId)
                ?? throw new InvalidOperationException("Failed to retrieve created location");
        }

        throw new InvalidOperationException("Failed to create location");
    }

    public async Task<IEnumerable<LocationDto>> GetAllLocationsAsync(Guid tenantId, bool? isActive = null)
    {
        _logger.LogDebug("Fetching locations for tenant {TenantId}, isActive: {IsActive}", tenantId, isActive);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Location_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@IsActive", (object?)isActive ?? DBNull.Value);

        var locations = new List<LocationDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            locations.Add(MapLocationFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} locations for tenant {TenantId}", locations.Count, tenantId);

        return locations;
    }

    public async Task<LocationDto?> GetLocationByIdAsync(Guid tenantId, Guid locationId)
    {
        _logger.LogDebug("Fetching location {LocationId} for tenant {TenantId}", locationId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Location_GetById";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@LocationId", locationId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapLocationFromReader(reader);
        }

        _logger.LogWarning("Location {LocationId} not found for tenant {TenantId}", locationId, tenantId);
        return null;
    }

    public async Task<LocationDto> UpdateLocationAsync(Guid tenantId, Guid locationId, UpdateLocationRequest request)
    {
        _logger.LogInformation("Updating location {LocationId} for tenant {TenantId}", locationId, tenantId);

        // First verify the location exists
        var existingLocation = await GetLocationByIdAsync(tenantId, locationId);
        if (existingLocation == null)
        {
            throw new KeyNotFoundException($"Location {locationId} not found");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        // Note: Update stored procedure will be created in a future enhancement
        // For now, we'll do a direct UPDATE (not ideal, but functional)
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].Locations
            SET LocationName = @LocationName,
                AddressLine1 = @AddressLine1,
                AddressLine2 = @AddressLine2,
                City = @City,
                StateProvince = @StateProvince,
                PostalCode = @PostalCode,
                Country = @Country,
                Latitude = @Latitude,
                Longitude = @Longitude,
                IsActive = @IsActive,
                ModifiedDate = GETUTCDATE()
            WHERE LocationId = @LocationId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@LocationId", locationId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationName", request.LocationName);
        command.Parameters.AddWithValue("@AddressLine1", (object?)request.AddressLine1 ?? DBNull.Value);
        command.Parameters.AddWithValue("@AddressLine2", (object?)request.AddressLine2 ?? DBNull.Value);
        command.Parameters.AddWithValue("@City", (object?)request.City ?? DBNull.Value);
        command.Parameters.AddWithValue("@StateProvince", (object?)request.StateProvince ?? DBNull.Value);
        command.Parameters.AddWithValue("@PostalCode", (object?)request.PostalCode ?? DBNull.Value);
        command.Parameters.AddWithValue("@Country", (object?)request.Country ?? DBNull.Value);
        command.Parameters.AddWithValue("@Latitude", (object?)request.Latitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@Longitude", (object?)request.Longitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected == 0)
        {
            throw new InvalidOperationException("Failed to update location");
        }

        _logger.LogInformation("Location {LocationId} updated successfully", locationId);

        // Return updated location
        return await GetLocationByIdAsync(tenantId, locationId)
            ?? throw new InvalidOperationException("Failed to retrieve updated location");
    }

    public async Task<bool> DeleteLocationAsync(Guid tenantId, Guid locationId)
    {
        _logger.LogInformation("Deleting location {LocationId} for tenant {TenantId}", locationId, tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        // Soft delete by setting IsActive = 0
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].Locations
            SET IsActive = 0,
                ModifiedDate = GETUTCDATE()
            WHERE LocationId = @LocationId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@LocationId", locationId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected > 0)
        {
            _logger.LogInformation("Location {LocationId} deleted successfully", locationId);
            return true;
        }

        _logger.LogWarning("Location {LocationId} not found or already deleted", locationId);
        return false;
    }

    private static LocationDto MapLocationFromReader(SqlDataReader reader)
    {
        return new LocationDto
        {
            LocationId = reader.GetGuid(reader.GetOrdinal("LocationId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            LocationCode = reader.GetString(reader.GetOrdinal("LocationCode")),
            LocationName = reader.GetString(reader.GetOrdinal("LocationName")),
            AddressLine1 = reader.IsDBNull(reader.GetOrdinal("AddressLine1")) ? null : reader.GetString(reader.GetOrdinal("AddressLine1")),
            AddressLine2 = reader.IsDBNull(reader.GetOrdinal("AddressLine2")) ? null : reader.GetString(reader.GetOrdinal("AddressLine2")),
            City = reader.IsDBNull(reader.GetOrdinal("City")) ? null : reader.GetString(reader.GetOrdinal("City")),
            StateProvince = reader.IsDBNull(reader.GetOrdinal("StateProvince")) ? null : reader.GetString(reader.GetOrdinal("StateProvince")),
            PostalCode = reader.IsDBNull(reader.GetOrdinal("PostalCode")) ? null : reader.GetString(reader.GetOrdinal("PostalCode")),
            Country = reader.IsDBNull(reader.GetOrdinal("Country")) ? null : reader.GetString(reader.GetOrdinal("Country")),
            Latitude = reader.IsDBNull(reader.GetOrdinal("Latitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Latitude")),
            Longitude = reader.IsDBNull(reader.GetOrdinal("Longitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Longitude")),
            LocationBarcodeData = reader.IsDBNull(reader.GetOrdinal("LocationBarcodeData")) ? null : reader.GetString(reader.GetOrdinal("LocationBarcodeData")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }
}
