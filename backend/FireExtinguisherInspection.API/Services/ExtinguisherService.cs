using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for managing fire extinguisher inventory
/// Uses standard schema with stored procedures (tenant-scoped data with @TenantId parameter)
/// </summary>
public class ExtinguisherService : IExtinguisherService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IBarcodeGeneratorService _barcodeGenerator;
    private readonly ILogger<ExtinguisherService> _logger;

    public ExtinguisherService(
        IDbConnectionFactory connectionFactory,
        IBarcodeGeneratorService barcodeGenerator,
        ILogger<ExtinguisherService> logger)
    {
        _connectionFactory = connectionFactory;
        _barcodeGenerator = barcodeGenerator;
        _logger = logger;
    }

    public async Task<ExtinguisherDto> CreateExtinguisherAsync(Guid tenantId, CreateExtinguisherRequest request)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_Create";

        var extinguisherId = Guid.NewGuid();
        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationId", request.LocationId);
        command.Parameters.AddWithValue("@ExtinguisherTypeId", request.ExtinguisherTypeId);
        command.Parameters.AddWithValue("@AssetTag", request.AssetTag);
        command.Parameters.AddWithValue("@Manufacturer", (object?)request.Manufacturer ?? DBNull.Value);
        command.Parameters.AddWithValue("@Model", (object?)request.Model ?? DBNull.Value);
        command.Parameters.AddWithValue("@SerialNumber", (object?)request.SerialNumber ?? DBNull.Value);
        command.Parameters.AddWithValue("@ManufactureDate", (object?)request.ManufactureDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@InstallDate", (object?)request.InstallDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@LastHydrostaticTestDate", (object?)request.LastHydrostaticTestDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Capacity", (object?)request.Capacity ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationDescription", (object?)request.LocationDescription ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new InvalidOperationException("Failed to create extinguisher");

        var extinguisher = MapExtinguisherFromReader(reader);

        // Generate barcode after creation
        await GenerateBarcodeInternalAsync(tenantId, extinguisher.ExtinguisherId);

        // Fetch the updated extinguisher with barcode data
        return await GetExtinguisherByIdAsync(tenantId, extinguisher.ExtinguisherId)
            ?? throw new InvalidOperationException("Failed to retrieve created extinguisher");
    }

    public async Task<IEnumerable<ExtinguisherDto>> GetAllExtinguishersAsync(
        Guid tenantId,
        Guid? locationId = null,
        Guid? typeId = null,
        bool? isActive = null,
        bool? isOutOfService = null)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_GetAll";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationId", (object?)locationId ?? DBNull.Value);
        command.Parameters.AddWithValue("@ExtinguisherTypeId", (object?)typeId ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", (object?)isActive ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsOutOfService", (object?)isOutOfService ?? DBNull.Value);

        var extinguishers = new List<ExtinguisherDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            extinguishers.Add(MapExtinguisherFromReader(reader));
        }

        return extinguishers;
    }

    public async Task<ExtinguisherDto?> GetExtinguisherByIdAsync(Guid tenantId, Guid extinguisherId)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_GetById";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapExtinguisherFromReader(reader);
        }

        return null;
    }

    public async Task<ExtinguisherDto?> GetExtinguisherByBarcodeAsync(Guid tenantId, string barcodeData)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_GetByBarcode";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@BarcodeData", barcodeData);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapExtinguisherFromReader(reader);
        }

        return null;
    }

    public async Task<ExtinguisherDto> UpdateExtinguisherAsync(Guid tenantId, Guid extinguisherId, UpdateExtinguisherRequest request)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_Update";

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@LocationId", request.LocationId);
        command.Parameters.AddWithValue("@ExtinguisherTypeId", request.ExtinguisherTypeId);
        command.Parameters.AddWithValue("@SerialNumber", request.SerialNumber);
        command.Parameters.AddWithValue("@AssetTag", (object?)request.AssetTag ?? DBNull.Value);
        command.Parameters.AddWithValue("@Manufacturer", (object?)request.Manufacturer ?? DBNull.Value);
        command.Parameters.AddWithValue("@ManufactureDate", (object?)request.ManufactureDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@InstallDate", (object?)request.InstallDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@LastServiceDate", (object?)request.LastServiceDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@NextServiceDueDate", (object?)request.NextServiceDueDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@LastHydroTestDate", (object?)request.LastHydroTestDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@NextHydroTestDueDate", (object?)request.NextHydroTestDueDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationDescription", (object?)request.LocationDescription ?? DBNull.Value);
        command.Parameters.AddWithValue("@FloorLevel", (object?)request.FloorLevel ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", request.IsActive);
        command.Parameters.AddWithValue("@IsOutOfService", request.IsOutOfService);
        command.Parameters.AddWithValue("@OutOfServiceReason", (object?)request.OutOfServiceReason ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new KeyNotFoundException($"Extinguisher {extinguisherId} not found");

        return MapExtinguisherFromReader(reader);
    }

    public async Task<bool> DeleteExtinguisherAsync(Guid tenantId, Guid extinguisherId)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_Delete";

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();
        return rowsAffected > 0;
    }

    public async Task<BarcodeResponse> GenerateBarcodeAsync(Guid tenantId, Guid extinguisherId)
    {
        return await GenerateBarcodeInternalAsync(tenantId, extinguisherId);
    }

    public async Task<ExtinguisherDto> MarkOutOfServiceAsync(Guid tenantId, Guid extinguisherId, string reason)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_MarkOutOfService";

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@Reason", reason);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new KeyNotFoundException($"Extinguisher {extinguisherId} not found");

        return MapExtinguisherFromReader(reader);
    }

    public async Task<ExtinguisherDto> ReturnToServiceAsync(Guid tenantId, Guid extinguisherId)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_ReturnToService";

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new KeyNotFoundException($"Extinguisher {extinguisherId} not found");

        return MapExtinguisherFromReader(reader);
    }

    public async Task<IEnumerable<ExtinguisherDto>> GetExtinguishersNeedingServiceAsync(Guid tenantId, int daysAhead = 30)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_GetNeedingService";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@DaysAhead", daysAhead);

        var extinguishers = new List<ExtinguisherDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            extinguishers.Add(MapExtinguisherFromReader(reader));
        }

        return extinguishers;
    }

    public async Task<IEnumerable<ExtinguisherDto>> GetExtinguishersNeedingHydroTestAsync(Guid tenantId, int daysAhead = 30)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Extinguisher_GetNeedingHydroTest";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@DaysAhead", daysAhead);

        var extinguishers = new List<ExtinguisherDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            extinguishers.Add(MapExtinguisherFromReader(reader));
        }

        return extinguishers;
    }

    #region Private Helper Methods

    private async Task<BarcodeResponse> GenerateBarcodeInternalAsync(Guid tenantId, Guid extinguisherId)
    {
        // Generate barcode data using extinguisher ID
        var barcodeData = $"FP-{extinguisherId:N}";

        // Generate both barcode and QR code
        var (barcode, qrCode) = _barcodeGenerator.GenerateBoth(barcodeData);

        // Update extinguisher with barcode data
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = @"
            UPDATE dbo.Extinguishers
            SET BarcodeData = @BarcodeData,
                QrCodeData = @QrCodeData,
                ModifiedDate = GETUTCDATE()
            WHERE ExtinguisherId = @ExtinguisherId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@BarcodeData", barcode);
        command.Parameters.AddWithValue("@QrCodeData", qrCode);
        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        await command.ExecuteNonQueryAsync();

        return new BarcodeResponse
        {
            BarcodeData = barcode,
            QrCodeData = qrCode,
            Format = "PNG"
        };
    }

    private ExtinguisherDto MapExtinguisherFromReader(SqlDataReader reader)
    {
        return new ExtinguisherDto
        {
            ExtinguisherId = reader.GetGuid(reader.GetOrdinal("ExtinguisherId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            LocationId = reader.GetGuid(reader.GetOrdinal("LocationId")),
            ExtinguisherTypeId = reader.GetGuid(reader.GetOrdinal("ExtinguisherTypeId")),
            AssetTag = reader.GetString(reader.GetOrdinal("AssetTag")),
            BarcodeData = reader.IsDBNull(reader.GetOrdinal("BarcodeData")) ? null : reader.GetString(reader.GetOrdinal("BarcodeData")),
            Manufacturer = reader.IsDBNull(reader.GetOrdinal("Manufacturer")) ? null : reader.GetString(reader.GetOrdinal("Manufacturer")),
            Model = reader.IsDBNull(reader.GetOrdinal("Model")) ? null : reader.GetString(reader.GetOrdinal("Model")),
            SerialNumber = reader.IsDBNull(reader.GetOrdinal("SerialNumber")) ? null : reader.GetString(reader.GetOrdinal("SerialNumber")),
            ManufactureDate = reader.IsDBNull(reader.GetOrdinal("ManufactureDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ManufactureDate")),
            InstallDate = reader.IsDBNull(reader.GetOrdinal("InstallDate")) ? null : reader.GetDateTime(reader.GetOrdinal("InstallDate")),
            LastHydrostaticTestDate = reader.IsDBNull(reader.GetOrdinal("LastHydrostaticTestDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastHydrostaticTestDate")),
            Capacity = reader.IsDBNull(reader.GetOrdinal("Capacity")) ? null : reader.GetString(reader.GetOrdinal("Capacity")),
            LocationDescription = reader.IsDBNull(reader.GetOrdinal("LocationDescription")) ? null : reader.GetString(reader.GetOrdinal("LocationDescription")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate")),
            // Navigation properties (if available in joined query)
            LocationName = HasColumn(reader, "LocationName") && !reader.IsDBNull(reader.GetOrdinal("LocationName"))
                ? reader.GetString(reader.GetOrdinal("LocationName")) : null,
            TypeName = HasColumn(reader, "TypeName") && !reader.IsDBNull(reader.GetOrdinal("TypeName"))
                ? reader.GetString(reader.GetOrdinal("TypeName")) : null,
            TypeCode = HasColumn(reader, "TypeCode") && !reader.IsDBNull(reader.GetOrdinal("TypeCode"))
                ? reader.GetString(reader.GetOrdinal("TypeCode")) : null
        };
    }

    private bool HasColumn(SqlDataReader reader, string columnName)
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
