using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace FireExtinguisherInspection.API.Services
{
    public class ImportService : IImportService
    {
        private readonly IDbConnectionFactory _connectionFactory;
        private readonly ILogger<ImportService> _logger;

        public ImportService(
            IDbConnectionFactory connectionFactory,
            ILogger<ImportService> logger)
        {
            _connectionFactory = connectionFactory;
            _logger = logger;
        }

        // ========================================================================
        // Import Job Management
        // ========================================================================

        public async Task<ImportJobDto> CreateImportJobAsync(CreateImportJobRequest request)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_ImportJob_Create";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@TenantId", request.TenantId);
            command.Parameters.AddWithValue("@UserId", request.UserId);
            command.Parameters.AddWithValue("@JobType", request.JobType);
            command.Parameters.AddWithValue("@FileName", request.FileName);
            command.Parameters.AddWithValue("@FileSize", request.FileSize);
            command.Parameters.AddWithValue("@FileHash", request.FileHash);
            command.Parameters.AddWithValue("@BlobStorageUrl", request.BlobStorageUrl);
            command.Parameters.AddWithValue("@MappingTemplateId", (object?)request.MappingTemplateId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MappingData", (object?)request.MappingData ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsDryRun", request.IsDryRun);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapImportJobFromReader(reader);
            }

            throw new InvalidOperationException("Failed to create import job");
        }

        public async Task<ImportJobDto> UpdateImportJobStatusAsync(UpdateImportJobStatusRequest request)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_ImportJob_UpdateStatus";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@ImportJobId", request.ImportJobId);
            command.Parameters.AddWithValue("@Status", request.Status);
            command.Parameters.AddWithValue("@TotalRows", (object?)request.TotalRows ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProcessedRows", (object?)request.ProcessedRows ?? DBNull.Value);
            command.Parameters.AddWithValue("@SuccessRows", (object?)request.SuccessRows ?? DBNull.Value);
            command.Parameters.AddWithValue("@FailedRows", (object?)request.FailedRows ?? DBNull.Value);
            command.Parameters.AddWithValue("@ErrorMessage", (object?)request.ErrorMessage ?? DBNull.Value);
            command.Parameters.AddWithValue("@ErrorDetails", (object?)request.ErrorDetails ?? DBNull.Value);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapImportJobFromReader(reader);
            }

            throw new InvalidOperationException("Failed to update import job");
        }

        public async Task<ImportJobDto?> GetImportJobByIdAsync(Guid importJobId)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = @"
                SELECT
                    ImportJobId, TenantId, UserId, JobType, FileName, FileSize,
                    FileHash, BlobStorageUrl, Status, TotalRows, ProcessedRows,
                    SuccessRows, FailedRows, ErrorMessage, ErrorDetails,
                    MappingTemplateId, MappingData, IsDryRun,
                    StartedDate, CompletedDate, CreatedDate, ModifiedDate
                FROM dbo.ImportJobs
                WHERE ImportJobId = @ImportJobId";

            command.Parameters.AddWithValue("@ImportJobId", importJobId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapImportJobFromReader(reader);
            }

            return null;
        }

        public async Task<ImportHistoryResponse> GetImportHistoryAsync(GetImportHistoryRequest request)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_ImportJob_GetHistory";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@TenantId", request.TenantId);
            command.Parameters.AddWithValue("@JobType", (object?)request.JobType ?? DBNull.Value);
            command.Parameters.AddWithValue("@PageNumber", request.PageNumber);
            command.Parameters.AddWithValue("@PageSize", request.PageSize);

            var jobs = new List<ImportJobDto>();
            int totalCount = 0;

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var job = MapImportJobFromReader(reader);
                jobs.Add(job);

                if (totalCount == 0)
                {
                    totalCount = reader.GetInt32(reader.GetOrdinal("TotalCount"));
                }
            }

            return new ImportHistoryResponse
            {
                Jobs = jobs,
                TotalCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize
            };
        }

        // ========================================================================
        // CSV Parsing
        // ========================================================================

        public async Task<List<Dictionary<string, string>>> ParseCsvAsync(Stream fileStream)
        {
            var rows = new List<Dictionary<string, string>>();

            using var reader = new StreamReader(fileStream, Encoding.UTF8);

            // Read header row
            var headerLine = await reader.ReadLineAsync();
            if (string.IsNullOrWhiteSpace(headerLine))
            {
                throw new InvalidDataException("CSV file is empty");
            }

            var headers = ParseCsvLine(headerLine);
            if (headers.Count == 0)
            {
                throw new InvalidDataException("CSV header row is empty");
            }

            // Read data rows
            int lineNumber = 2; // Header is line 1
            string? line;
            while ((line = await reader.ReadLineAsync()) != null)
            {
                if (string.IsNullOrWhiteSpace(line))
                {
                    lineNumber++;
                    continue;
                }

                var values = ParseCsvLine(line);
                if (values.Count != headers.Count)
                {
                    _logger.LogWarning("Line {LineNumber} has {ValueCount} values but expected {HeaderCount}",
                        lineNumber, values.Count, headers.Count);
                }

                var row = new Dictionary<string, string>();
                for (int i = 0; i < headers.Count; i++)
                {
                    var value = i < values.Count ? values[i] : string.Empty;
                    row[headers[i]] = value;
                }

                rows.Add(row);
                lineNumber++;
            }

            _logger.LogInformation("Parsed {RowCount} rows from CSV", rows.Count);
            return rows;
        }

        private List<string> ParseCsvLine(string line)
        {
            var values = new List<string>();
            var currentValue = new StringBuilder();
            bool inQuotes = false;

            for (int i = 0; i < line.Length; i++)
            {
                char c = line[i];

                if (c == '"')
                {
                    if (inQuotes && i + 1 < line.Length && line[i + 1] == '"')
                    {
                        // Escaped quote
                        currentValue.Append('"');
                        i++; // Skip next quote
                    }
                    else
                    {
                        // Toggle quote mode
                        inQuotes = !inQuotes;
                    }
                }
                else if (c == ',' && !inQuotes)
                {
                    // End of field
                    values.Add(currentValue.ToString().Trim());
                    currentValue.Clear();
                }
                else
                {
                    currentValue.Append(c);
                }
            }

            // Add last field
            values.Add(currentValue.ToString().Trim());

            return values;
        }

        // ========================================================================
        // Validation
        // ========================================================================

        public async Task<ValidationResponse> ValidateImportDataAsync(ValidateImportRequest request)
        {
            var response = new ValidationResponse
            {
                TotalRows = request.Rows.Count
            };

            // Validate tenant permissions
            if (request.JobType == "HistoricalInspections")
            {
                var canImport = await CanTenantImportHistoricalDataAsync(request.TenantId);
                if (!canImport)
                {
                    response.GlobalErrors.Add("Historical inspection imports are disabled for this tenant");
                    return response;
                }
            }

            // Validate each row
            int rowNumber = 1;
            foreach (var row in request.Rows)
            {
                var validationResult = ValidateHistoricalInspectionRow(row, request.Mappings, rowNumber);
                response.Results.Add(validationResult);

                if (validationResult.IsValid)
                {
                    response.ValidRows++;
                }
                else
                {
                    response.InvalidRows++;
                }

                if (validationResult.Warnings.Count > 0)
                {
                    response.RowsWithWarnings++;
                }

                rowNumber++;
            }

            return response;
        }

        private RowValidationResult ValidateHistoricalInspectionRow(
            Dictionary<string, string> row,
            FieldMappingData mappings,
            int rowNumber)
        {
            var result = new RowValidationResult
            {
                RowNumber = rowNumber,
                IsValid = true
            };

            try
            {
                // Apply field mappings
                var mappedData = new Dictionary<string, string>();
                foreach (var mapping in mappings.Mappings)
                {
                    var sourceValue = row.GetValueOrDefault(mapping.SourceField, string.Empty);

                    // Use default value if source is empty
                    if (string.IsNullOrWhiteSpace(sourceValue) && !string.IsNullOrEmpty(mapping.DefaultValue))
                    {
                        sourceValue = mapping.DefaultValue;
                    }

                    // Check required fields
                    if (mapping.IsRequired && string.IsNullOrWhiteSpace(sourceValue))
                    {
                        result.Errors.Add($"{mapping.DestinationField} is required");
                        result.IsValid = false;
                    }

                    mappedData[mapping.DestinationField] = sourceValue;
                }

                // Validate specific fields
                var inspectionRow = new HistoricalInspectionRow
                {
                    ExtinguisherBarcode = mappedData.GetValueOrDefault("ExtinguisherBarcode", string.Empty),
                    InspectorName = mappedData.GetValueOrDefault("InspectorName", string.Empty),
                    InspectionType = mappedData.GetValueOrDefault("InspectionType", string.Empty),
                    PassFail = mappedData.GetValueOrDefault("PassFail", string.Empty),
                    InspectionDate = default,
                    Notes = mappedData.GetValueOrDefault("Notes"),
                    LocationName = mappedData.GetValueOrDefault("LocationName"),
                    SerialNumber = mappedData.GetValueOrDefault("SerialNumber"),
                    Manufacturer = mappedData.GetValueOrDefault("Manufacturer"),
                    ExtinguisherType = mappedData.GetValueOrDefault("ExtinguisherType")
                };

                // Required fields
                if (string.IsNullOrWhiteSpace(inspectionRow.ExtinguisherBarcode))
                {
                    result.Errors.Add("ExtinguisherBarcode is required");
                    result.IsValid = false;
                }

                // Validate dates
                var inspectionDateStr = mappedData.GetValueOrDefault("InspectionDate", string.Empty);
                if (string.IsNullOrWhiteSpace(inspectionDateStr))
                {
                    result.Errors.Add("InspectionDate is required");
                    result.IsValid = false;
                }
                else if (!DateTime.TryParse(inspectionDateStr, out var inspectionDate))
                {
                    result.Errors.Add($"Invalid InspectionDate format: {inspectionDateStr}");
                    result.IsValid = false;
                }
                else
                {
                    inspectionRow.InspectionDate = inspectionDate;

                    // Warn if date is in the future
                    if (inspectionDate > DateTime.UtcNow)
                    {
                        result.Warnings.Add("InspectionDate is in the future");
                    }
                }

                // Validate inspection type
                var validTypes = new[] { "Monthly", "Annual", "6-Year", "Hydrostatic" };
                if (!string.IsNullOrWhiteSpace(inspectionRow.InspectionType) &&
                    !validTypes.Contains(inspectionRow.InspectionType, StringComparer.OrdinalIgnoreCase))
                {
                    result.Errors.Add($"Invalid InspectionType: {inspectionRow.InspectionType}. Must be one of: {string.Join(", ", validTypes)}");
                    result.IsValid = false;
                }

                // Validate pass/fail
                var validPassFail = new[] { "Pass", "Fail" };
                if (!validPassFail.Contains(inspectionRow.PassFail, StringComparer.OrdinalIgnoreCase))
                {
                    result.Errors.Add($"Invalid PassFail value: {inspectionRow.PassFail}. Must be 'Pass' or 'Fail'");
                    result.IsValid = false;
                }

                // Validate weight if provided
                var weightStr = mappedData.GetValueOrDefault("Weight", string.Empty);
                if (!string.IsNullOrWhiteSpace(weightStr))
                {
                    if (decimal.TryParse(weightStr, out var weight))
                    {
                        if (weight <= 0)
                        {
                            result.Errors.Add("Weight must be greater than 0");
                            result.IsValid = false;
                        }
                        else
                        {
                            inspectionRow.Weight = weight;
                        }
                    }
                    else
                    {
                        result.Errors.Add($"Invalid Weight format: {weightStr}");
                        result.IsValid = false;
                    }
                }

                result.Data = inspectionRow;
            }
            catch (Exception ex)
            {
                result.Errors.Add($"Validation error: {ex.Message}");
                result.IsValid = false;
            }

            return result;
        }

        // ========================================================================
        // Background Processing
        // ========================================================================

        public async Task ProcessHistoricalInspectionImportAsync(Guid importJobId)
        {
            var job = await GetImportJobByIdAsync(importJobId);
            if (job == null)
            {
                throw new InvalidOperationException($"Import job {importJobId} not found");
            }

            // Update status to Processing
            await UpdateImportJobStatusAsync(new UpdateImportJobStatusRequest
            {
                ImportJobId = importJobId,
                Status = "Processing"
            });

            // TODO: Download file from blob storage
            // TODO: Parse CSV
            // TODO: Validate data
            // TODO: Insert inspections into database
            // TODO: Update job status with results

            _logger.LogInformation("Import job {ImportJobId} processed successfully", importJobId);
        }

        // ========================================================================
        // Historical Import Permissions
        // ========================================================================

        public async Task<bool> CanTenantImportHistoricalDataAsync(Guid tenantId)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = @"
                SELECT AllowHistoricalImports
                FROM dbo.Tenants
                WHERE TenantId = @TenantId";

            command.Parameters.AddWithValue("@TenantId", tenantId);

            var result = await command.ExecuteScalarAsync();
            return result != null && (bool)result;
        }

        public async Task<HistoricalImportsStatusResponse> ToggleHistoricalImportsAsync(ToggleHistoricalImportsRequest request)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_Tenant_ToggleHistoricalImports";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@TenantId", request.TenantId);
            command.Parameters.AddWithValue("@Enable", request.Enable);
            command.Parameters.AddWithValue("@UserId", request.UserId);
            command.Parameters.AddWithValue("@Reason", (object?)request.Reason ?? DBNull.Value);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new HistoricalImportsStatusResponse
                {
                    TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
                    AllowHistoricalImports = reader.GetBoolean(reader.GetOrdinal("AllowHistoricalImports")),
                    LastModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
                };
            }

            throw new InvalidOperationException("Failed to toggle historical imports");
        }

        public async Task<HistoricalImportsStatusResponse> GetHistoricalImportStatusAsync(Guid tenantId)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = @"
                SELECT TenantId, AllowHistoricalImports, ModifiedDate
                FROM dbo.Tenants
                WHERE TenantId = @TenantId";

            command.Parameters.AddWithValue("@TenantId", tenantId);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new HistoricalImportsStatusResponse
                {
                    TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
                    AllowHistoricalImports = reader.GetBoolean(reader.GetOrdinal("AllowHistoricalImports")),
                    LastModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
                };
            }

            throw new InvalidOperationException($"Tenant {tenantId} not found");
        }

        // ========================================================================
        // Field Mapping Templates
        // ========================================================================

        public async Task<FieldMappingTemplateDto> SaveFieldMappingTemplateAsync(SaveFieldMappingTemplateRequest request)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_FieldMappingTemplate_Save";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@MappingTemplateId", (object?)request.MappingTemplateId ?? DBNull.Value);
            command.Parameters.AddWithValue("@TenantId", request.TenantId);
            command.Parameters.AddWithValue("@TemplateName", request.TemplateName);
            command.Parameters.AddWithValue("@JobType", request.JobType);
            command.Parameters.AddWithValue("@MappingData", request.MappingData);
            command.Parameters.AddWithValue("@TransformationRules", (object?)request.TransformationRules ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsDefault", request.IsDefault);

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapFieldMappingTemplateFromReader(reader);
            }

            throw new InvalidOperationException("Failed to save field mapping template");
        }

        public async Task<List<FieldMappingTemplateDto>> GetFieldMappingTemplatesAsync(Guid tenantId, string? jobType = null)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = "dbo.usp_FieldMappingTemplate_GetByTenant";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@TenantId", tenantId);
            command.Parameters.AddWithValue("@JobType", (object?)jobType ?? DBNull.Value);

            var templates = new List<FieldMappingTemplateDto>();

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                templates.Add(MapFieldMappingTemplateFromReader(reader));
            }

            return templates;
        }

        public async Task DeleteFieldMappingTemplateAsync(Guid mappingTemplateId)
        {
            using var connection = await _connectionFactory.CreateConnectionAsync();
            using var command = (SqlCommand)connection.CreateCommand();

            command.CommandText = @"
                DELETE FROM dbo.FieldMappingTemplates
                WHERE MappingTemplateId = @MappingTemplateId";

            command.Parameters.AddWithValue("@MappingTemplateId", mappingTemplateId);

            await command.ExecuteNonQueryAsync();
        }

        // ========================================================================
        // Helper Methods
        // ========================================================================

        private ImportJobDto MapImportJobFromReader(SqlDataReader reader)
        {
            return new ImportJobDto
            {
                ImportJobId = reader.GetGuid(reader.GetOrdinal("ImportJobId")),
                TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
                UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
                JobType = reader.GetString(reader.GetOrdinal("JobType")),
                FileName = reader.GetString(reader.GetOrdinal("FileName")),
                FileSize = reader.GetInt64(reader.GetOrdinal("FileSize")),
                FileHash = reader.GetString(reader.GetOrdinal("FileHash")),
                BlobStorageUrl = reader.GetString(reader.GetOrdinal("BlobStorageUrl")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                TotalRows = reader.IsDBNull(reader.GetOrdinal("TotalRows"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("TotalRows")),
                ProcessedRows = reader.IsDBNull(reader.GetOrdinal("ProcessedRows"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("ProcessedRows")),
                SuccessRows = reader.IsDBNull(reader.GetOrdinal("SuccessRows"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("SuccessRows")),
                FailedRows = reader.IsDBNull(reader.GetOrdinal("FailedRows"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("FailedRows")),
                ErrorMessage = reader.IsDBNull(reader.GetOrdinal("ErrorMessage"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("ErrorMessage")),
                ErrorDetails = reader.IsDBNull(reader.GetOrdinal("ErrorDetails"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("ErrorDetails")),
                MappingTemplateId = reader.IsDBNull(reader.GetOrdinal("MappingTemplateId"))
                    ? null
                    : reader.GetGuid(reader.GetOrdinal("MappingTemplateId")),
                MappingData = reader.IsDBNull(reader.GetOrdinal("MappingData"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("MappingData")),
                IsDryRun = reader.GetBoolean(reader.GetOrdinal("IsDryRun")),
                StartedDate = reader.IsDBNull(reader.GetOrdinal("StartedDate"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("StartedDate")),
                CompletedDate = reader.IsDBNull(reader.GetOrdinal("CompletedDate"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("CompletedDate")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
            };
        }

        private FieldMappingTemplateDto MapFieldMappingTemplateFromReader(SqlDataReader reader)
        {
            return new FieldMappingTemplateDto
            {
                MappingTemplateId = reader.GetGuid(reader.GetOrdinal("MappingTemplateId")),
                TenantId = reader.GetGuid(reader.GetOrdinal("TenantId")),
                TemplateName = reader.GetString(reader.GetOrdinal("TemplateName")),
                JobType = reader.GetString(reader.GetOrdinal("JobType")),
                MappingData = reader.GetString(reader.GetOrdinal("MappingData")),
                TransformationRules = reader.IsDBNull(reader.GetOrdinal("TransformationRules"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("TransformationRules")),
                IsDefault = reader.GetBoolean(reader.GetOrdinal("IsDefault")),
                CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
                ModifiedDate = reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
            };
        }
    }
}
