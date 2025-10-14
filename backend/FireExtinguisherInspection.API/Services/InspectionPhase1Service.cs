using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Phase 1 service for managing checklist-based inspections
/// </summary>
public class InspectionPhase1Service : IInspectionPhase1Service
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ITamperProofingService _tamperProofing;
    private readonly ILogger<InspectionPhase1Service> _logger;

    public InspectionPhase1Service(
        IDbConnectionFactory connectionFactory,
        ITamperProofingService tamperProofing,
        ILogger<InspectionPhase1Service> logger)
    {
        _connectionFactory = connectionFactory;
        _tamperProofing = tamperProofing;
        _logger = logger;
    }

    public async Task<InspectionPhase1Dto> CreateInspectionAsync(Guid tenantId, CreateInspectionPhase1Request request)
    {
        _logger.LogInformation("Creating Phase 1 inspection for extinguisher {ExtinguisherId}", request.ExtinguisherId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_Create";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@ExtinguisherId", request.ExtinguisherId);
        command.Parameters.AddWithValue("@InspectorUserId", request.InspectorUserId);
        command.Parameters.AddWithValue("@TemplateId", request.TemplateId);
        command.Parameters.AddWithValue("@InspectionType", request.InspectionType);
        command.Parameters.AddWithValue("@ScheduledDate", (object?)request.ScheduledDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@Latitude", (object?)request.Latitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@Longitude", (object?)request.Longitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationAccuracy", (object?)request.LocationAccuracy ?? DBNull.Value);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var inspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId"));

            _logger.LogInformation("Phase 1 inspection created successfully: {InspectionId}", inspectionId);

            // Fetch the created inspection
            return await GetInspectionByIdAsync(tenantId, inspectionId, false)
                ?? throw new InvalidOperationException("Failed to retrieve created inspection");
        }

        throw new InvalidOperationException("Failed to create inspection");
    }

    public async Task<InspectionPhase1Dto> UpdateInspectionAsync(Guid tenantId, Guid inspectionId, UpdateInspectionPhase1Request request)
    {
        _logger.LogInformation("Updating inspection {InspectionId}", inspectionId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_Update";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@Latitude", (object?)request.Latitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@Longitude", (object?)request.Longitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@LocationAccuracy", (object?)request.LocationAccuracy ?? DBNull.Value);
        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);

        await command.ExecuteNonQueryAsync();

        _logger.LogInformation("Inspection {InspectionId} updated successfully", inspectionId);

        return await GetInspectionByIdAsync(tenantId, inspectionId, false)
            ?? throw new InvalidOperationException("Failed to retrieve updated inspection");
    }

    public async Task<InspectionPhase1Dto> CompleteInspectionAsync(Guid tenantId, Guid inspectionId, CompleteInspectionRequest request)
    {
        _logger.LogInformation("Completing inspection {InspectionId}", inspectionId);

        // Get the inspection with all details for hash computation
        var inspection = await GetInspectionByIdAsync(tenantId, inspectionId, true)
            ?? throw new KeyNotFoundException($"Inspection {inspectionId} not found");

        // TODO: Compute hash based on checklist responses + previous inspection hash (blockchain-style)
        // For now, use a placeholder hash
        var inspectionHash = _tamperProofing.ComputeInspectionHash(new InspectionHashData
        {
            ExtinguisherId = inspection.ExtinguisherId,
            InspectorUserId = inspection.InspectorUserId,
            InspectionDate = inspection.StartTime ?? DateTime.UtcNow,
            InspectionType = inspection.InspectionType,
            GpsLatitude = inspection.Latitude,
            GpsLongitude = inspection.Longitude,
            Notes = request.Notes
        });

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_Complete";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@OverallResult", request.OverallResult);
        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
        command.Parameters.AddWithValue("@InspectorSignature", (object?)request.InspectorSignature ?? DBNull.Value);
        command.Parameters.AddWithValue("@InspectionHash", inspectionHash);
        command.Parameters.AddWithValue("@PreviousInspectionHash", (object?)inspection.PreviousInspectionHash ?? DBNull.Value);

        await command.ExecuteNonQueryAsync();

        _logger.LogInformation("Inspection {InspectionId} completed successfully", inspectionId);

        return await GetInspectionByIdAsync(tenantId, inspectionId, true)
            ?? throw new InvalidOperationException("Failed to retrieve completed inspection");
    }

    public async Task<IEnumerable<InspectionChecklistResponseDto>> SaveChecklistResponsesAsync(
        Guid tenantId,
        Guid inspectionId,
        SaveChecklistResponsesRequest request)
    {
        _logger.LogInformation("Saving {Count} checklist responses for inspection {InspectionId}",
            request.Responses.Count, inspectionId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_InspectionChecklistResponse_CreateBatch";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);

        // Create table-valued parameter for responses
        var responsesTable = new DataTable();
        responsesTable.Columns.Add("ChecklistItemId", typeof(Guid));
        responsesTable.Columns.Add("Response", typeof(string));
        responsesTable.Columns.Add("Comment", typeof(string));
        responsesTable.Columns.Add("PhotoId", typeof(Guid));

        foreach (var response in request.Responses)
        {
            responsesTable.Rows.Add(
                response.ChecklistItemId,
                response.Response,
                response.Comment ?? (object)DBNull.Value,
                response.PhotoId ?? (object)DBNull.Value
            );
        }

        var responsesParam = command.Parameters.AddWithValue("@Responses", responsesTable);
        responsesParam.SqlDbType = SqlDbType.Structured;
        responsesParam.TypeName = $"[{schemaName}].ChecklistResponseTableType";

        var savedResponses = new List<InspectionChecklistResponseDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            savedResponses.Add(MapChecklistResponseFromReader(reader));
        }

        _logger.LogInformation("Saved {Count} checklist responses for inspection {InspectionId}",
            savedResponses.Count, inspectionId);

        return savedResponses;
    }

    public async Task<IEnumerable<InspectionChecklistResponseDto>> GetChecklistResponsesAsync(Guid tenantId, Guid inspectionId)
    {
        _logger.LogDebug("Fetching checklist responses for inspection {InspectionId}", inspectionId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_InspectionChecklistResponse_GetByInspection";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);

        var responses = new List<InspectionChecklistResponseDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            responses.Add(MapChecklistResponseFromReader(reader));
        }

        return responses;
    }

    public async Task<IEnumerable<InspectionPhase1Dto>> GetAllInspectionsAsync(
        Guid tenantId,
        Guid? extinguisherId = null,
        Guid? inspectorUserId = null,
        DateTime? startDate = null,
        DateTime? endDate = null,
        string? inspectionType = null,
        string? status = null)
    {
        _logger.LogDebug("Fetching inspections for tenant {TenantId}", tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_GetByDate";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        var inspections = new List<InspectionPhase1Dto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var inspection = MapInspectionFromReader(reader);

            // Apply client-side filtering (until we have a comprehensive GetAll stored procedure)
            if (extinguisherId.HasValue && inspection.ExtinguisherId != extinguisherId.Value)
                continue;
            if (inspectorUserId.HasValue && inspection.InspectorUserId != inspectorUserId.Value)
                continue;
            if (!string.IsNullOrEmpty(inspectionType) && !inspection.InspectionType.Equals(inspectionType, StringComparison.OrdinalIgnoreCase))
                continue;
            if (!string.IsNullOrEmpty(status) && !inspection.Status.Equals(status, StringComparison.OrdinalIgnoreCase))
                continue;

            inspections.Add(inspection);
        }

        _logger.LogInformation("Retrieved {Count} inspections for tenant {TenantId}", inspections.Count, tenantId);

        return inspections;
    }

    public async Task<InspectionPhase1Dto?> GetInspectionByIdAsync(Guid tenantId, Guid inspectionId, bool includeDetails = true)
    {
        _logger.LogDebug("Fetching inspection {InspectionId}", inspectionId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_GetById";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var inspection = MapInspectionFromReader(reader);

            if (includeDetails)
            {
                // Load checklist responses
                inspection.ChecklistResponses = (await GetChecklistResponsesAsync(tenantId, inspectionId)).ToList();

                // Load photos (when IPhotoService is implemented)
                // inspection.Photos = (await _photoService.GetInspectionPhotosAsync(tenantId, inspectionId)).ToList();

                // Load deficiencies (when IDeficiencyService is implemented)
                // inspection.Deficiencies = (await _deficiencyService.GetInspectionDeficienciesAsync(tenantId, inspectionId)).ToList();
            }

            return inspection;
        }

        _logger.LogWarning("Inspection {InspectionId} not found", inspectionId);
        return null;
    }

    public async Task<IEnumerable<InspectionPhase1Dto>> GetExtinguisherInspectionHistoryAsync(Guid tenantId, Guid extinguisherId)
    {
        _logger.LogDebug("Fetching inspection history for extinguisher {ExtinguisherId}", extinguisherId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_GetByExtinguisher";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@ExtinguisherId", extinguisherId);

        var inspections = new List<InspectionPhase1Dto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            inspections.Add(MapInspectionFromReader(reader));
        }

        return inspections;
    }

    public async Task<IEnumerable<InspectionPhase1Dto>> GetInspectorInspectionsAsync(
        Guid tenantId,
        Guid inspectorUserId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        // Use GetAllInspectionsAsync with inspector filter
        return await GetAllInspectionsAsync(tenantId, inspectorUserId: inspectorUserId, startDate: startDate, endDate: endDate);
    }

    public async Task<IEnumerable<InspectionPhase1Dto>> GetDueInspectionsAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        _logger.LogDebug("Fetching due inspections for tenant {TenantId}", tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_GetDue";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        var inspections = new List<InspectionPhase1Dto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            inspections.Add(MapInspectionFromReader(reader));
        }

        return inspections;
    }

    public async Task<IEnumerable<InspectionPhase1Dto>> GetScheduledInspectionsAsync(
        Guid tenantId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        _logger.LogDebug("Fetching scheduled inspections for tenant {TenantId}", tenantId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_GetScheduled";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@StartDate", (object?)startDate ?? DBNull.Value);
        command.Parameters.AddWithValue("@EndDate", (object?)endDate ?? DBNull.Value);

        var inspections = new List<InspectionPhase1Dto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            inspections.Add(MapInspectionFromReader(reader));
        }

        return inspections;
    }

    public async Task<InspectionPhase1VerificationResponse> VerifyInspectionIntegrityAsync(Guid tenantId, Guid inspectionId)
    {
        _logger.LogInformation("Verifying integrity of inspection {InspectionId}", inspectionId);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_Inspection_VerifyHash";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionId", inspectionId);

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            return new InspectionPhase1VerificationResponse
            {
                InspectionId = inspectionId,
                IsValid = reader.GetBoolean(reader.GetOrdinal("IsValid")),
                ValidationMessage = reader.GetString(reader.GetOrdinal("ValidationMessage")),
                InspectionHash = reader.IsDBNull(reader.GetOrdinal("InspectionHash")) ? null : reader.GetString(reader.GetOrdinal("InspectionHash")),
                PreviousInspectionHash = reader.IsDBNull(reader.GetOrdinal("PreviousInspectionHash")) ? null : reader.GetString(reader.GetOrdinal("PreviousInspectionHash")),
                HashChainVerified = reader.GetBoolean(reader.GetOrdinal("HashChainVerified")),
                SignatureVerified = reader.GetBoolean(reader.GetOrdinal("SignatureVerified")),
                LocationVerified = reader.GetBoolean(reader.GetOrdinal("LocationVerified")),
                VerifiedDate = DateTime.UtcNow
            };
        }

        throw new InvalidOperationException($"Failed to verify inspection {inspectionId}");
    }

    public async Task<InspectionPhase1StatsDto> GetInspectionStatsAsync(Guid tenantId, DateTime? startDate = null, DateTime? endDate = null)
    {
        _logger.LogDebug("Fetching inspection statistics for tenant {TenantId}", tenantId);

        // Get all inspections and compute stats (until we have a dedicated stored procedure)
        var inspections = await GetAllInspectionsAsync(tenantId, startDate: startDate, endDate: endDate);
        var inspectionList = inspections.ToList();

        return new InspectionPhase1StatsDto
        {
            TotalInspections = inspectionList.Count,
            CompletedInspections = inspectionList.Count(i => i.Status == "Completed"),
            InProgressInspections = inspectionList.Count(i => i.Status == "InProgress"),
            FailedInspections = inspectionList.Count(i => i.OverallResult == "Fail"),
            PassedInspections = inspectionList.Count(i => i.OverallResult == "Pass"),
            ConditionalPassInspections = inspectionList.Count(i => i.OverallResult == "ConditionalPass"),
            TotalDeficiencies = inspectionList.Sum(i => i.Deficiencies?.Count ?? 0),
            CriticalDeficiencies = inspectionList.Sum(i => i.Deficiencies?.Count(d => d.Severity == "Critical") ?? 0),
            PassRate = inspectionList.Count > 0 ? (double)inspectionList.Count(i => i.OverallResult == "Pass") / inspectionList.Count * 100 : 0,
            LastInspectionDate = inspectionList.Where(i => i.CompletedTime.HasValue).Max(i => i.CompletedTime),
            InspectionsThisMonth = inspectionList.Count(i => i.CreatedDate >= DateTime.UtcNow.AddMonths(-1)),
            InspectionsThisYear = inspectionList.Count(i => i.CreatedDate >= DateTime.UtcNow.AddYears(-1))
        };
    }

    public async Task<bool> DeleteInspectionAsync(Guid tenantId, Guid inspectionId)
    {
        _logger.LogInformation("Deleting inspection {InspectionId}", inspectionId);

        // Verify inspection is InProgress (only allow deletion of incomplete inspections)
        var inspection = await GetInspectionByIdAsync(tenantId, inspectionId, false);
        if (inspection == null)
        {
            return false;
        }

        if (inspection.Status == "Completed")
        {
            throw new InvalidOperationException("Cannot delete completed inspections (audit trail preservation)");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].Inspections
            SET Status = 'Deleted',
                ModifiedDate = GETUTCDATE()
            WHERE InspectionId = @InspectionId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@InspectionId", inspectionId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected > 0)
        {
            _logger.LogInformation("Inspection {InspectionId} deleted successfully", inspectionId);
            return true;
        }

        return false;
    }

    #region Private Helper Methods

    private static InspectionPhase1Dto MapInspectionFromReader(SqlDataReader reader)
    {
        return new InspectionPhase1Dto
        {
            InspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId")),
            TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
            ExtinguisherId = reader.GetGuid(reader.GetOrdinal("ExtinguisherId")),
            InspectorUserId = reader.GetGuid(reader.GetOrdinal("InspectorUserId")),
            TemplateId = reader.GetGuid(reader.GetOrdinal("TemplateId")),
            InspectionType = reader.GetString(reader.GetOrdinal("InspectionType")),
            Status = reader.GetString(reader.GetOrdinal("Status")),
            ScheduledDate = reader.IsDBNull(reader.GetOrdinal("ScheduledDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ScheduledDate")),
            StartTime = reader.IsDBNull(reader.GetOrdinal("StartTime")) ? null : reader.GetDateTime(reader.GetOrdinal("StartTime")),
            CompletedTime = reader.IsDBNull(reader.GetOrdinal("CompletedTime")) ? null : reader.GetDateTime(reader.GetOrdinal("CompletedTime")),
            Latitude = reader.IsDBNull(reader.GetOrdinal("Latitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Latitude")),
            Longitude = reader.IsDBNull(reader.GetOrdinal("Longitude")) ? null : reader.GetDecimal(reader.GetOrdinal("Longitude")),
            LocationAccuracy = reader.IsDBNull(reader.GetOrdinal("LocationAccuracy")) ? null : reader.GetDecimal(reader.GetOrdinal("LocationAccuracy")),
            InspectionHash = reader.IsDBNull(reader.GetOrdinal("InspectionHash")) ? null : reader.GetString(reader.GetOrdinal("InspectionHash")),
            PreviousInspectionHash = reader.IsDBNull(reader.GetOrdinal("PreviousInspectionHash")) ? null : reader.GetString(reader.GetOrdinal("PreviousInspectionHash")),
            HashVerified = reader.IsDBNull(reader.GetOrdinal("HashVerified")) ? null : reader.GetBoolean(reader.GetOrdinal("HashVerified")),
            InspectorSignature = reader.IsDBNull(reader.GetOrdinal("InspectorSignature")) ? null : reader.GetString(reader.GetOrdinal("InspectorSignature")),
            SignedDate = reader.IsDBNull(reader.GetOrdinal("SignedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("SignedDate")),
            OverallResult = reader.IsDBNull(reader.GetOrdinal("OverallResult")) ? null : reader.GetString(reader.GetOrdinal("OverallResult")),
            Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedDate")),
            // Navigation properties (if available)
            ExtinguisherCode = HasColumn(reader, "ExtinguisherCode") && !reader.IsDBNull(reader.GetOrdinal("ExtinguisherCode"))
                ? reader.GetString(reader.GetOrdinal("ExtinguisherCode")) : null,
            InspectorName = HasColumn(reader, "InspectorName") && !reader.IsDBNull(reader.GetOrdinal("InspectorName"))
                ? reader.GetString(reader.GetOrdinal("InspectorName")) : null,
            LocationName = HasColumn(reader, "LocationName") && !reader.IsDBNull(reader.GetOrdinal("LocationName"))
                ? reader.GetString(reader.GetOrdinal("LocationName")) : null,
            TemplateName = HasColumn(reader, "TemplateName") && !reader.IsDBNull(reader.GetOrdinal("TemplateName"))
                ? reader.GetString(reader.GetOrdinal("TemplateName")) : null
        };
    }

    private static InspectionChecklistResponseDto MapChecklistResponseFromReader(SqlDataReader reader)
    {
        return new InspectionChecklistResponseDto
        {
            ResponseId = reader.GetGuid(reader.GetOrdinal("ResponseId")),
            InspectionId = reader.GetGuid(reader.GetOrdinal("InspectionId")),
            ChecklistItemId = reader.GetGuid(reader.GetOrdinal("ChecklistItemId")),
            Response = reader.GetString(reader.GetOrdinal("Response")),
            Comment = reader.IsDBNull(reader.GetOrdinal("Comment")) ? null : reader.GetString(reader.GetOrdinal("Comment")),
            PhotoId = reader.IsDBNull(reader.GetOrdinal("PhotoId")) ? null : reader.GetGuid(reader.GetOrdinal("PhotoId")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            // Navigation properties (if available)
            ItemText = HasColumn(reader, "ItemText") && !reader.IsDBNull(reader.GetOrdinal("ItemText"))
                ? reader.GetString(reader.GetOrdinal("ItemText")) : null,
            Category = HasColumn(reader, "Category") && !reader.IsDBNull(reader.GetOrdinal("Category"))
                ? reader.GetString(reader.GetOrdinal("Category")) : null,
            Order = HasColumn(reader, "ItemOrder") && !reader.IsDBNull(reader.GetOrdinal("ItemOrder"))
                ? reader.GetInt32(reader.GetOrdinal("ItemOrder")) : null
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
