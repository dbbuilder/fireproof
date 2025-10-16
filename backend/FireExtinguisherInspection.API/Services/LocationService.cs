using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for location management operations
/// Uses standard schema with stored procedures (tenant-scoped data with @TenantId parameter)
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

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Location_Create";

        var locationId = Guid.NewGuid();

        command.Parameters.AddWithValue("@LocationId", locationId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationCode", request.LocationCode);
        command.Parameters.AddWithValue("@LocationName", request.LocationName);
        command.Parameters.AddWithValue("@AddressLine1", (object?)request.AddressLine1 ?? DBNull.Value);
        command.Parameters.AddWithValue("@AddressLine2", (object?)request.AddressLine2 ?? DBNull.Value);
        command.Parameters.AddWithValue("@City", (object?)request.City ?? DBNull.Value);
        command.Parameters.AddWithValue("@StateProvince", (object?)request.StateProvince ?? DBNull.Value);
        command.Parameters.AddWithValue("@PostalCode", (object?)request.PostalCode ?? DBNull.Value);
        command.Parameters.AddWithValue("@Country", (object?)request.Country ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var result = MapLocationFromReader(reader);
            _logger.LogInformation("Location created successfully: {LocationId}", locationId);
            return result;
        }

        throw new InvalidOperationException("Failed to create location");
    }

    public async Task<IEnumerable<LocationDto>> GetAllLocationsAsync(Guid tenantId, bool? isActive = null)
    {
        _logger.LogDebug("Fetching locations for tenant {TenantId}, isActive: {IsActive}", tenantId, isActive);

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Location_GetAll";
        command.Parameters.AddWithValue("@TenantId", tenantId);

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

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Location_GetById";
        command.Parameters.AddWithValue("@TenantId", tenantId);
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

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Location_Update";

        command.Parameters.AddWithValue("@LocationId", locationId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationName", request.LocationName);
        command.Parameters.AddWithValue("@AddressLine1", (object?)request.AddressLine1 ?? DBNull.Value);
        command.Parameters.AddWithValue("@AddressLine2", (object?)request.AddressLine2 ?? DBNull.Value);
        command.Parameters.AddWithValue("@City", (object?)request.City ?? DBNull.Value);
        command.Parameters.AddWithValue("@StateProvince", (object?)request.StateProvince ?? DBNull.Value);
        command.Parameters.AddWithValue("@PostalCode", (object?)request.PostalCode ?? DBNull.Value);
        command.Parameters.AddWithValue("@Country", (object?)request.Country ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            var result = MapLocationFromReader(reader);
            _logger.LogInformation("Location {LocationId} updated successfully", locationId);
            return result;
        }

        throw new InvalidOperationException("Failed to update location");
    }

    public async Task<bool> DeleteLocationAsync(Guid tenantId, Guid locationId)
    {
        _logger.LogInformation("Soft deleting location {LocationId} for tenant {TenantId}", locationId, tenantId);

        // Soft delete via update
        var location = await GetLocationByIdAsync(tenantId, locationId);
        if (location == null)
        {
            return false;
        }

        var updateRequest = new UpdateLocationRequest
        {
            LocationName = location.LocationName,
            AddressLine1 = location.AddressLine1,
            AddressLine2 = location.AddressLine2,
            City = location.City,
            StateProvince = location.StateProvince,
            PostalCode = location.PostalCode,
            Country = location.Country,
            Latitude = location.Latitude,
            Longitude = location.Longitude,
            IsActive = false
        };

        await UpdateLocationAsync(tenantId, locationId, updateRequest);
        _logger.LogInformation("Location {LocationId} deleted successfully", locationId);
        return true;
    }

    private static LocationDto MapLocationFromReader(SqlDataReader reader)
    {
        // Helper to safely get ordinal (returns -1 if column doesn't exist)
        int SafeGetOrdinal(string name)
        {
            try { return reader.GetOrdinal(name); }
            catch { return -1; }
        }

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
            // Optional columns that may not exist in all stored procedure results
            Latitude = SafeGetOrdinal("Latitude") >= 0 && !reader.IsDBNull(SafeGetOrdinal("Latitude")) ? reader.GetDecimal(SafeGetOrdinal("Latitude")) : null,
            Longitude = SafeGetOrdinal("Longitude") >= 0 && !reader.IsDBNull(SafeGetOrdinal("Longitude")) ? reader.GetDecimal(SafeGetOrdinal("Longitude")) : null,
            LocationBarcodeData = SafeGetOrdinal("LocationBarcodeData") >= 0 && !reader.IsDBNull(SafeGetOrdinal("LocationBarcodeData")) ? reader.GetString(SafeGetOrdinal("LocationBarcodeData")) : null,
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }
}
