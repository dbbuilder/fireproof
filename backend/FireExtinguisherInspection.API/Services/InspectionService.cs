using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for managing tamper-proof fire extinguisher inspections
/// </summary>
public class InspectionService : IInspectionService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ITamperProofingService _tamperProofing;
    private readonly ILogger<InspectionService> _logger;

    public InspectionService(
        IDbConnectionFactory connectionFactory,
        ITamperProofingService tamperProofing,
        ILogger<InspectionService> logger)
    {
        _connectionFactory = connectionFactory;
        _tamperProofing = tamperProofing;
        _logger = logger;
    }

    public async Task<InspectionDto> CreateInspectionAsync(Guid tenantId, CreateInspectionRequest request)
    {
        // Create hashable data object
        var hashData = new InspectionHashData
        {
            ExtinguisherId = request.ExtinguisherId,
            InspectorUserId = request.InspectorUserId,
            InspectionDate = request.InspectionDate,
            InspectionType = request.InspectionType,
            GpsLatitude = request.GpsLatitude,
            GpsLongitude = request.GpsLongitude,
            GpsAccuracyMeters = request.GpsAccuracyMeters,
            IsAccessible = request.IsAccessible,
            HasObstructions = request.HasObstructions,
            SignageVisible = request.SignageVisible,
            SealIntact = request.SealIntact,
            PinInPlace = request.PinInPlace,
            NozzleClear = request.NozzleClear,
            HoseConditionGood = request.HoseConditionGood,
            GaugeInGreenZone = request.GaugeInGreenZone,
            GaugePressurePsi = request.GaugePressurePsi,
            PhysicalDamagePresent = request.PhysicalDamagePresent,
            DamageDescription = request.DamageDescription,
            WeightPounds = request.WeightPounds,
            InspectionTagAttached = request.InspectionTagAttached,
            PreviousInspectionDate = request.PreviousInspectionDate,
            Notes = request.Notes,
            RequiresService = request.RequiresService,
            RequiresReplacement = request.RequiresReplacement,
            FailureReason = request.FailureReason,
            CorrectiveAction = request.CorrectiveAction,
            PhotoUrls = request.PhotoUrls
        };

        // Compute tamper-proof hash
        var dataHash = _tamperProofing.ComputeInspectionHash(hashData);

        // Create digital signature
        var signedDate = DateTime.UtcNow;
        var signature = _tamperProofing.CreateInspectorSignature(request.InspectorUserId, dataHash, signedDate);

        // Determine pass/fail based on checks
        var passed = DetermineInspectionPassed(request);

        // Determine location verification
        var locationVerified = request.GpsLatitude.HasValue && request.GpsLongitude.HasValue;

        // Determine weight within spec (simple check - could be more sophisticated)
        var weightWithinSpec = !request.WeightPounds.HasValue || request.WeightPounds.Value > 0;

        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_Create";

        command.Parameters.AddWithValue("@ExtinguisherId", request.ExtinguisherId);
        command.Parameters.AddWithValue("@InspectorUserId", request.InspectorUserId);
        command.Parameters.AddWithValue("@InspectionDate", request.InspectionDate);
        command.Parameters.AddWithValue("@InspectionType", request.InspectionType);
        command.Parameters.AddWithValue("@GpsLatitude", (object?)request.GpsLatitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@GpsLongitude", (object?)request.GpsLongitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@GpsAccuracyMeters", (object?)request.GpsAccuracyMeters ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationVerified", locationVerified);
        command.Parameters.AddWithValue("@IsAccessible", request.IsAccessible);
        command.Parameters.AddWithValue("@HasObstructions", request.HasObstructions);
        command.Parameters.AddWithValue("@SignageVisible", request.SignageVisible);
        command.Parameters.AddWithValue("@SealIntact", request.SealIntact);
        command.Parameters.AddWithValue("@PinInPlace", request.PinInPlace);
        command.Parameters.AddWithValue("@NozzleClear", request.NozzleClear);
        command.Parameters.AddWithValue("@HoseConditionGood", request.HoseConditionGood);
        command.Parameters.AddWithValue("@GaugeInGreenZone", request.GaugeInGreenZone);
        command.Parameters.AddWithValue("@GaugePressurePsi", (object?)request.GaugePressurePsi ?? DBNull.Value);
        command.Parameters.AddWithValue("@PhysicalDamagePresent", request.PhysicalDamagePresent);
        command.Parameters.AddWithValue("@DamageDescription", (object?)request.DamageDescription ?? DBNull.Value);
        command.Parameters.AddWithValue("@WeightPounds", (object?)request.WeightPounds ?? DBNull.Value);
        command.Parameters.AddWithValue("@WeightWithinSpec", weightWithinSpec);
        command.Parameters.AddWithValue("@InspectionTagAttached", request.InspectionTagAttached);
        command.Parameters.AddWithValue("@PreviousInspectionDate", (object?)request.PreviousInspectionDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@Passed", passed);
        command.Parameters.AddWithValue("@RequiresService", request.RequiresService);
        command.Parameters.AddWithValue("@RequiresReplacement", request.RequiresReplacement);
        command.Parameters.AddWithValue("@FailureReason", (object?)request.FailureReason ?? DBNull.Value);
        command.Parameters.AddWithValue("@CorrectiveAction", (object?)request.CorrectiveAction ?? DBNull.Value);
        command.Parameters.AddWithValue("@PhotoUrls", (object?)string.Join(",", request.PhotoUrls ?? new List<string>()) ?? DBNull.Value);
        command.Parameters.AddWithValue("@DataHash", dataHash);
        command.Parameters.AddWithValue("@InspectorSignature", signature);
        command.Parameters.AddWithValue("@SignedDate", signedDate);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync())
            throw new InvalidOperationException("Failed to create inspection");

        return MapInspectionFromReader(reader);
    }

    public async Task<IEnumerable<InspectionDto>> GetAllInspectionsAsync(
        Guid tenantId,
        Guid? extinguisherId = null,
        Guid? inspectorUserId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? inspectionType = null,
        bool? passed = null)
    {
        using var connection = await _connectionFactory.CreateConnectionAsync();
        using var command = (SqlCommand)connection.CreateCommand();

        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_GetAll";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@ExtinguisherId", (object?)extinguisherId ?? DBNull.Value);
        command.Parameters.AddWithValue("@InspectorUserId", (object?)inspectorUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@InspectionType", (object?)inspectionType ?? DBNull.Value);
        command.Parameters.AddWithValue("@Passed", (object?)passed ?? DBNull.Value);

        var inspections = new List<InspectionDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            inspections.Add(MapInspectionFromReader(reader));
        }

        return inspections;
    }

    public async Task<InspectionDto?> GetInspectionByIdAsync(Guid tenantId, Guid inspectionId)
    {
        
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_GetById";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@InspectionId", inspectionId);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return MapInspectionFromReader(reader);
        }

        return null;
    }

    public async Task<IEnumerable<InspectionDto>> GetExtinguisherInspectionHistoryAsync(Guid tenantId, Guid extinguisherId)
    {
        return await GetAllInspectionsAsync(tenantId, extinguisherId: extinguisherId);
    }

    public async Task<IEnumerable<InspectionDto>> GetInspectorInspectionsAsync(
        Guid tenantId,
        Guid inspectorUserId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        return await GetAllInspectionsAsync(tenantId, inspectorUserId: inspectorUserId, startDate: startDate, endDate: endDate);
    }

    public async Task<InspectionVerificationResponse> VerifyInspectionIntegrityAsync(Guid tenantId, Guid inspectionId)
    {
        var inspection = await GetInspectionByIdAsync(tenantId, inspectionId);
        if (inspection == null)
        {
            throw new KeyNotFoundException($"Inspection {inspectionId} not found");
        }

        // Recreate hash data from inspection
        var hashData = new InspectionHashData
        {
            ExtinguisherId = inspection.ExtinguisherId,
            InspectorUserId = inspection.InspectorUserId,
            InspectionDate = inspection.InspectionDate,
            InspectionType = inspection.InspectionType,
            GpsLatitude = inspection.GpsLatitude,
            GpsLongitude = inspection.GpsLongitude,
            GpsAccuracyMeters = inspection.GpsAccuracyMeters,
            IsAccessible = inspection.IsAccessible,
            HasObstructions = inspection.HasObstructions,
            SignageVisible = inspection.SignageVisible,
            SealIntact = inspection.SealIntact,
            PinInPlace = inspection.PinInPlace,
            NozzleClear = inspection.NozzleClear,
            HoseConditionGood = inspection.HoseConditionGood,
            GaugeInGreenZone = inspection.GaugeInGreenZone,
            GaugePressurePsi = inspection.GaugePressurePsi,
            PhysicalDamagePresent = inspection.PhysicalDamagePresent,
            DamageDescription = inspection.DamageDescription,
            WeightPounds = inspection.WeightPounds,
            InspectionTagAttached = inspection.InspectionTagAttached,
            PreviousInspectionDate = inspection.PreviousInspectionDate,
            Notes = inspection.Notes,
            RequiresService = inspection.RequiresService,
            RequiresReplacement = inspection.RequiresReplacement,
            FailureReason = inspection.FailureReason,
            CorrectiveAction = inspection.CorrectiveAction,
            PhotoUrls = inspection.PhotoUrls
        };

        // Compute current hash
        var computedHash = _tamperProofing.ComputeInspectionHash(hashData);
        var hashMatch = _tamperProofing.VerifyInspectionIntegrity(hashData, inspection.DataHash);

        // Verify signature
        var signatureValid = _tamperProofing.VerifyInspectorSignature(
            inspection.InspectorSignature,
            inspection.InspectorUserId,
            inspection.DataHash,
            inspection.SignedDate);

        var isValid = hashMatch && signatureValid;

        return new InspectionVerificationResponse
        {
            InspectionId = inspectionId,
            IsValid = isValid,
            ValidationMessage = isValid
                ? "Inspection record is valid and has not been tampered with"
                : "Inspection record has been modified or signature is invalid",
            OriginalHash = inspection.DataHash,
            ComputedHash = computedHash,
            HashMatch = hashMatch,
            VerifiedDate = DateTime.UtcNow
        };
    }

    public async Task<InspectionStatsDto> GetInspectionStatsAsync(Guid tenantId, DateTime? startDate = null, DateTime? endDate = null)
    {
        
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_GetStats";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new InspectionStatsDto
            {
                TotalInspections = reader.GetInt32(reader.GetOrdinal("TotalInspections")),
                PassedInspections = reader.GetInt32(reader.GetOrdinal("PassedInspections")),
                FailedInspections = reader.GetInt32(reader.GetOrdinal("FailedInspections")),
                RequiringService = reader.GetInt32(reader.GetOrdinal("RequiringService")),
                RequiringReplacement = reader.GetInt32(reader.GetOrdinal("RequiringReplacement")),
                PassRate = reader.GetDouble(reader.GetOrdinal("PassRate")),
                LastInspectionDate = reader.IsDBNull(reader.GetOrdinal("LastInspectionDate"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("LastInspectionDate")),
                InspectionsThisMonth = reader.GetInt32(reader.GetOrdinal("InspectionsThisMonth")),
                InspectionsThisYear = reader.GetInt32(reader.GetOrdinal("InspectionsThisYear"))
            };
        }

        return new InspectionStatsDto();
    }

    public async Task<IEnumerable<InspectionDto>> GetOverdueInspectionsAsync(Guid tenantId, string inspectionType = "Monthly")
    {
        
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_GetOverdue";

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@InspectionType", inspectionType);

        var inspections = new List<InspectionDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            inspections.Add(MapInspectionFromReader(reader));
        }

        return inspections;
    }

    public async Task<bool> DeleteInspectionAsync(Guid tenantId, Guid inspectionId)
    {
        
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_Inspection_Delete";

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();
        return rowsAffected > 0;
    }

    #region Private Helper Methods

    private bool DetermineInspectionPassed(CreateInspectionRequest request)
    {
        // Inspection passes if all critical checks pass
        var criticalChecks = new[]
        {
            request.IsAccessible,
            !request.HasObstructions,
            request.SignageVisible,
            request.SealIntact,
            request.PinInPlace,
            request.NozzleClear,
            request.HoseConditionGood,
            request.GaugeInGreenZone,
            !request.PhysicalDamagePresent,
            request.InspectionTagAttached
        };

        return criticalChecks.All(check => check);
    }

    private InspectionDto MapInspectionFromReader(SqlDataReader reader)
    {
        var photoUrlsString = reader.IsDBNull(reader.GetOrdinal("PhotoUrls"))
            ? null
            : reader.GetString(reader.GetOrdinal("PhotoUrls"));

        var photoUrls = string.IsNullOrWhiteSpace(photoUrlsString)
            ? null
            : photoUrlsString.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList();

        return new InspectionDto
        {
            InspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            ExtinguisherId = reader.GetGuid(reader.GetOrdinal("ExtinguisherId")),
            InspectorUserId = reader.GetGuid(reader.GetOrdinal("InspectorUserId")),
            InspectionDate = reader.GetDateTime(reader.GetOrdinal("InspectionDate")),
            InspectionType = reader.GetString(reader.GetOrdinal("InspectionType")),
            GpsLatitude = reader.IsDBNull(reader.GetOrdinal("GpsLatitude")) ? null : reader.GetDecimal(reader.GetOrdinal("GpsLatitude")),
            GpsLongitude = reader.IsDBNull(reader.GetOrdinal("GpsLongitude")) ? null : reader.GetDecimal(reader.GetOrdinal("GpsLongitude")),
            GpsAccuracyMeters = reader.IsDBNull(reader.GetOrdinal("GpsAccuracyMeters")) ? null : reader.GetInt32(reader.GetOrdinal("GpsAccuracyMeters")),
            LocationVerified = reader.GetBoolean(reader.GetOrdinal("LocationVerified")),
            IsAccessible = reader.GetBoolean(reader.GetOrdinal("IsAccessible")),
            HasObstructions = reader.GetBoolean(reader.GetOrdinal("HasObstructions")),
            SignageVisible = reader.GetBoolean(reader.GetOrdinal("SignageVisible")),
            SealIntact = reader.GetBoolean(reader.GetOrdinal("SealIntact")),
            PinInPlace = reader.GetBoolean(reader.GetOrdinal("PinInPlace")),
            NozzleClear = reader.GetBoolean(reader.GetOrdinal("NozzleClear")),
            HoseConditionGood = reader.GetBoolean(reader.GetOrdinal("HoseConditionGood")),
            GaugeInGreenZone = reader.GetBoolean(reader.GetOrdinal("GaugeInGreenZone")),
            GaugePressurePsi = reader.IsDBNull(reader.GetOrdinal("GaugePressurePsi")) ? null : reader.GetDecimal(reader.GetOrdinal("GaugePressurePsi")),
            PhysicalDamagePresent = reader.GetBoolean(reader.GetOrdinal("PhysicalDamagePresent")),
            DamageDescription = reader.IsDBNull(reader.GetOrdinal("DamageDescription")) ? null : reader.GetString(reader.GetOrdinal("DamageDescription")),
            WeightPounds = reader.IsDBNull(reader.GetOrdinal("WeightPounds")) ? null : reader.GetDecimal(reader.GetOrdinal("WeightPounds")),
            WeightWithinSpec = reader.GetBoolean(reader.GetOrdinal("WeightWithinSpec")),
            InspectionTagAttached = reader.GetBoolean(reader.GetOrdinal("InspectionTagAttached")),
            PreviousInspectionDate = reader.IsDBNull(reader.GetOrdinal("PreviousInspectionDate")) ? null : reader.GetString(reader.GetOrdinal("PreviousInspectionDate")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            Passed = reader.GetBoolean(reader.GetOrdinal("Passed")),
            RequiresService = reader.GetBoolean(reader.GetOrdinal("RequiresService")),
            RequiresReplacement = reader.GetBoolean(reader.GetOrdinal("RequiresReplacement")),
            FailureReason = reader.IsDBNull(reader.GetOrdinal("FailureReason")) ? null : reader.GetString(reader.GetOrdinal("FailureReason")),
            CorrectiveAction = reader.IsDBNull(reader.GetOrdinal("CorrectiveAction")) ? null : reader.GetString(reader.GetOrdinal("CorrectiveAction")),
            PhotoUrls = photoUrls,
            DataHash = reader.GetString(reader.GetOrdinal("DataHash")),
            InspectorSignature = reader.GetString(reader.GetOrdinal("InspectorSignature")),
            SignedDate = reader.GetDateTime(reader.GetOrdinal("SignedDate")),
            IsVerified = reader.GetBoolean(reader.GetOrdinal("IsVerified")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate")),
            // Navigation properties
            ExtinguisherCode = HasColumn(reader, "ExtinguisherCode") && !reader.IsDBNull(reader.GetOrdinal("ExtinguisherCode"))
                ? reader.GetString(reader.GetOrdinal("ExtinguisherCode")) : null,
            InspectorName = HasColumn(reader, "InspectorName") && !reader.IsDBNull(reader.GetOrdinal("InspectorName"))
                ? reader.GetString(reader.GetOrdinal("InspectorName")) : null,
            LocationName = HasColumn(reader, "LocationName") && !reader.IsDBNull(reader.GetOrdinal("LocationName"))
                ? reader.GetString(reader.GetOrdinal("LocationName")) : null
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
