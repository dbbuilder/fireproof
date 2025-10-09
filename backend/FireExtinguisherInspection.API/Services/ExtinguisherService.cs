using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for managing fire extinguisher inventory
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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_Create";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@LocationId", request.LocationId);
        command.Parameters.AddWithValue("@ExtinguisherTypeId", request.ExtinguisherTypeId);
        command.Parameters.AddWithValue("@ExtinguisherCode", request.ExtinguisherCode);
        command.Parameters.AddWithValue("@SerialNumber", request.SerialNumber);
        command.Parameters.AddWithValue("@AssetTag", (object?)request.AssetTag ?? DBNull.Value);
        command.Parameters.AddWithValue("@Manufacturer", (object?)request.Manufacturer ?? DBNull.Value);
        command.Parameters.AddWithValue("@ManufactureDate", (object?)request.ManufactureDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@InstallDate", (object?)request.InstallDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationDescription", (object?)request.LocationDescription ?? DBNull.Value);
        command.Parameters.AddWithValue("@FloorLevel", (object?)request.FloorLevel ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new InvalidOperationException("Failed to create extinguisher");

        var extinguisher = MapExtinguisherFromReader(reader);

        // Generate barcode after creation
        await GenerateBarcodeInternalAsync(tenantId, extinguisher.ExtinguisherId, schemaName);

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_GetAll";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_GetById";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_GetByBarcode";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_Update";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_Delete";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();
        return rowsAffected > 0;
    }

    public async Task<BarcodeResponse> GenerateBarcodeAsync(Guid tenantId, Guid extinguisherId)
    {
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        return await GenerateBarcodeInternalAsync(tenantId, extinguisherId, schemaName);
    }

    public async Task<ExtinguisherDto> MarkOutOfServiceAsync(Guid tenantId, Guid extinguisherId, string reason)
    {
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_MarkOutOfService";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_ReturnToService";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new KeyNotFoundException($"Extinguisher {extinguisherId} not found");

        return MapExtinguisherFromReader(reader);
    }

    public async Task<IEnumerable<ExtinguisherDto>> GetExtinguishersNeedingServiceAsync(Guid tenantId, int daysAhead = 30)
    {
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_GetNeedingService";
        command.CommandType = CommandType.StoredProcedure;

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
        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Extinguisher_GetNeedingHydroTest";
        command.CommandType = CommandType.StoredProcedure;

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

    private async Task<BarcodeResponse> GenerateBarcodeInternalAsync(Guid tenantId, Guid extinguisherId, string schemaName)
    {
        // Generate barcode data using extinguisher ID
        var barcodeData = $"FP-{extinguisherId:N}";

        // Generate both barcode and QR code
        var (barcode, qrCode) = _barcodeGenerator.GenerateBoth(barcodeData);

        // Update extinguisher with barcode data
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].Extinguishers
            SET BarcodeData = @BarcodeData,
                QrCodeData = @QrCodeData,
                ModifiedDate = GETUTCDATE()
            WHERE ExtinguisherId = @ExtinguisherId";

        command.Parameters.AddWithValue("@BarcodeData", barcode);
        command.Parameters.AddWithValue("@QrCodeData", qrCode);
        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);

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
            ExtinguisherCode = reader.GetString(reader.GetOrdinal("ExtinguisherCode")),
            SerialNumber = reader.GetString(reader.GetOrdinal("SerialNumber")),
            AssetTag = reader.IsDBNull(reader.GetOrdinal("AssetTag")) ? null : reader.GetString(reader.GetOrdinal("AssetTag")),
            Manufacturer = reader.IsDBNull(reader.GetOrdinal("Manufacturer")) ? null : reader.GetString(reader.GetOrdinal("Manufacturer")),
            ManufactureDate = reader.IsDBNull(reader.GetOrdinal("ManufactureDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ManufactureDate")),
            InstallDate = reader.IsDBNull(reader.GetOrdinal("InstallDate")) ? null : reader.GetDateTime(reader.GetOrdinal("InstallDate")),
            LastServiceDate = reader.IsDBNull(reader.GetOrdinal("LastServiceDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastServiceDate")),
            NextServiceDueDate = reader.IsDBNull(reader.GetOrdinal("NextServiceDueDate")) ? null : reader.GetDateTime(reader.GetOrdinal("NextServiceDueDate")),
            LastHydroTestDate = reader.IsDBNull(reader.GetOrdinal("LastHydroTestDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastHydroTestDate")),
            NextHydroTestDueDate = reader.IsDBNull(reader.GetOrdinal("NextHydroTestDueDate")) ? null : reader.GetDateTime(reader.GetOrdinal("NextHydroTestDueDate")),
            LocationDescription = reader.IsDBNull(reader.GetOrdinal("LocationDescription")) ? null : reader.GetString(reader.GetOrdinal("LocationDescription")),
            FloorLevel = reader.IsDBNull(reader.GetOrdinal("FloorLevel")) ? null : reader.GetString(reader.GetOrdinal("FloorLevel")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            BarcodeData = reader.IsDBNull(reader.GetOrdinal("BarcodeData")) ? null : reader.GetString(reader.GetOrdinal("BarcodeData")),
            QrCodeData = reader.IsDBNull(reader.GetOrdinal("QrCodeData")) ? null : reader.GetString(reader.GetOrdinal("QrCodeData")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            IsOutOfService = reader.GetBoolean(reader.GetOrdinal("IsOutOfService")),
            OutOfServiceReason = reader.IsDBNull(reader.GetOrdinal("OutOfServiceReason")) ? null : reader.GetString(reader.GetOrdinal("OutOfServiceReason")),
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
