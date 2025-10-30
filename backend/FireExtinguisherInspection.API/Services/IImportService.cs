using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using FireExtinguisherInspection.API.Models.DTOs;

namespace FireExtinguisherInspection.API.Services
{
    /// <summary>
    /// Service for importing data from external files (CSV, Excel)
    /// </summary>
    public interface IImportService
    {
        /// <summary>
        /// Creates a new import job
        /// </summary>
        Task<ImportJobDto> CreateImportJobAsync(CreateImportJobRequest request);

        /// <summary>
        /// Updates import job status and progress
        /// </summary>
        Task<ImportJobDto> UpdateImportJobStatusAsync(UpdateImportJobStatusRequest request);

        /// <summary>
        /// Gets import job by ID
        /// </summary>
        Task<ImportJobDto?> GetImportJobByIdAsync(Guid importJobId);

        /// <summary>
        /// Gets import job history for a tenant
        /// </summary>
        Task<ImportHistoryResponse> GetImportHistoryAsync(GetImportHistoryRequest request);

        /// <summary>
        /// Parses CSV file and returns rows
        /// </summary>
        Task<List<Dictionary<string, string>>> ParseCsvAsync(Stream fileStream);

        /// <summary>
        /// Validates import data against business rules (dry run)
        /// </summary>
        Task<ValidationResponse> ValidateImportDataAsync(ValidateImportRequest request);

        /// <summary>
        /// Processes historical inspection import (background job)
        /// </summary>
        Task ProcessHistoricalInspectionImportAsync(Guid importJobId);

        /// <summary>
        /// Checks if tenant allows historical imports
        /// </summary>
        Task<bool> CanTenantImportHistoricalDataAsync(Guid tenantId);

        /// <summary>
        /// Toggles historical import feature for tenant
        /// </summary>
        Task<HistoricalImportsStatusResponse> ToggleHistoricalImportsAsync(ToggleHistoricalImportsRequest request);

        /// <summary>
        /// Gets historical import status for tenant
        /// </summary>
        Task<HistoricalImportsStatusResponse> GetHistoricalImportStatusAsync(Guid tenantId);

        /// <summary>
        /// Saves field mapping template
        /// </summary>
        Task<FieldMappingTemplateDto> SaveFieldMappingTemplateAsync(SaveFieldMappingTemplateRequest request);

        /// <summary>
        /// Gets field mapping templates for tenant
        /// </summary>
        Task<List<FieldMappingTemplateDto>> GetFieldMappingTemplatesAsync(Guid tenantId, string? jobType = null);

        /// <summary>
        /// Deletes field mapping template
        /// </summary>
        Task DeleteFieldMappingTemplateAsync(Guid mappingTemplateId);
    }
}
