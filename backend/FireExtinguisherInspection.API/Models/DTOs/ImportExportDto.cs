using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace FireExtinguisherInspection.API.Models.DTOs
{
    // ============================================================================
    // Import Job DTOs
    // ============================================================================

    /// <summary>
    /// Represents an import job
    /// </summary>
    public class ImportJobDto
    {
        public Guid ImportJobId { get; set; }
        public Guid TenantId { get; set; }
        public Guid UserId { get; set; }
        public required string JobType { get; set; }
        public required string FileName { get; set; }
        public long FileSize { get; set; }
        public required string FileHash { get; set; }
        public required string BlobStorageUrl { get; set; }
        public required string Status { get; set; }
        public int? TotalRows { get; set; }
        public int? ProcessedRows { get; set; }
        public int? SuccessRows { get; set; }
        public int? FailedRows { get; set; }
        public string? ErrorMessage { get; set; }
        public string? ErrorDetails { get; set; }
        public Guid? MappingTemplateId { get; set; }
        public string? MappingData { get; set; }
        public bool IsDryRun { get; set; }
        public DateTime? StartedDate { get; set; }
        public DateTime? CompletedDate { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime ModifiedDate { get; set; }
    }

    /// <summary>
    /// Request to create a new import job
    /// </summary>
    public class CreateImportJobRequest
    {
        [Required]
        public Guid TenantId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        [StringLength(50)]
        public required string JobType { get; set; }

        [Required]
        [StringLength(255)]
        public required string FileName { get; set; }

        [Required]
        public long FileSize { get; set; }

        [Required]
        [StringLength(64)]
        public required string FileHash { get; set; }

        [Required]
        [StringLength(1000)]
        public required string BlobStorageUrl { get; set; }

        public Guid? MappingTemplateId { get; set; }
        public string? MappingData { get; set; }
        public bool IsDryRun { get; set; }
    }

    /// <summary>
    /// Request to update import job status and progress
    /// </summary>
    public class UpdateImportJobStatusRequest
    {
        [Required]
        public Guid ImportJobId { get; set; }

        [Required]
        [StringLength(50)]
        public required string Status { get; set; }

        public int? TotalRows { get; set; }
        public int? ProcessedRows { get; set; }
        public int? SuccessRows { get; set; }
        public int? FailedRows { get; set; }
        public string? ErrorMessage { get; set; }
        public string? ErrorDetails { get; set; }
    }

    /// <summary>
    /// Request to get import job history
    /// </summary>
    public class GetImportHistoryRequest
    {
        [Required]
        public Guid TenantId { get; set; }

        [StringLength(50)]
        public string? JobType { get; set; }

        [Range(1, int.MaxValue)]
        public int PageNumber { get; set; } = 1;

        [Range(1, 100)]
        public int PageSize { get; set; } = 50;
    }

    /// <summary>
    /// Response containing import job history
    /// </summary>
    public class ImportHistoryResponse
    {
        public List<ImportJobDto> Jobs { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
        public bool HasNextPage => PageNumber < TotalPages;
        public bool HasPreviousPage => PageNumber > 1;
    }

    // ============================================================================
    // Field Mapping DTOs
    // ============================================================================

    /// <summary>
    /// Represents a field mapping template
    /// </summary>
    public class FieldMappingTemplateDto
    {
        public Guid MappingTemplateId { get; set; }
        public Guid TenantId { get; set; }
        public required string TemplateName { get; set; }
        public required string JobType { get; set; }
        public required string MappingData { get; set; }
        public string? TransformationRules { get; set; }
        public bool IsDefault { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime ModifiedDate { get; set; }
    }

    /// <summary>
    /// Request to save a field mapping template
    /// </summary>
    public class SaveFieldMappingTemplateRequest
    {
        public Guid? MappingTemplateId { get; set; }

        [Required]
        public Guid TenantId { get; set; }

        [Required]
        [StringLength(100)]
        public required string TemplateName { get; set; }

        [Required]
        [StringLength(50)]
        public required string JobType { get; set; }

        [Required]
        public required string MappingData { get; set; }

        public string? TransformationRules { get; set; }
        public bool IsDefault { get; set; }
    }

    /// <summary>
    /// Represents a single field mapping
    /// </summary>
    public class FieldMapping
    {
        [Required]
        public required string SourceField { get; set; }

        [Required]
        public required string DestinationField { get; set; }

        public string? DefaultValue { get; set; }
        public bool IsRequired { get; set; }
        public string? TransformationType { get; set; }
        public Dictionary<string, string>? TransformationOptions { get; set; }
    }

    /// <summary>
    /// Container for field mappings
    /// </summary>
    public class FieldMappingData
    {
        public List<FieldMapping> Mappings { get; set; } = new();
        public Dictionary<string, string>? GlobalTransformations { get; set; }
    }

    // ============================================================================
    // Historical Inspection Import DTOs
    // ============================================================================

    /// <summary>
    /// Represents a row from historical inspection CSV
    /// </summary>
    public class HistoricalInspectionRow
    {
        public required string ExtinguisherBarcode { get; set; }
        public DateTime InspectionDate { get; set; }
        public required string InspectorName { get; set; }
        public required string InspectionType { get; set; }
        public required string PassFail { get; set; }
        public string? Notes { get; set; }
        public string? LocationName { get; set; }
        public string? SerialNumber { get; set; }
        public string? Manufacturer { get; set; }
        public string? ExtinguisherType { get; set; }
        public decimal? Weight { get; set; }
        public DateTime? LastHydroTestDate { get; set; }
        public DateTime? ManufactureDate { get; set; }
    }

    /// <summary>
    /// Validation result for a single row
    /// </summary>
    public class RowValidationResult
    {
        public int RowNumber { get; set; }
        public bool IsValid { get; set; }
        public List<string> Errors { get; set; } = new();
        public List<string> Warnings { get; set; } = new();
        public HistoricalInspectionRow? Data { get; set; }
    }

    /// <summary>
    /// Request to validate import data (dry run)
    /// </summary>
    public class ValidateImportRequest
    {
        [Required]
        public Guid TenantId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        public required string JobType { get; set; }

        [Required]
        public List<Dictionary<string, string>> Rows { get; set; } = new();

        [Required]
        public required FieldMappingData Mappings { get; set; }
    }

    /// <summary>
    /// Response from validation request
    /// </summary>
    public class ValidationResponse
    {
        public int TotalRows { get; set; }
        public int ValidRows { get; set; }
        public int InvalidRows { get; set; }
        public int RowsWithWarnings { get; set; }
        public List<RowValidationResult> Results { get; set; } = new();
        public List<string> GlobalErrors { get; set; } = new();
        public bool CanProceed => InvalidRows == 0 && GlobalErrors.Count == 0;
    }

    // ============================================================================
    // Export DTOs
    // ============================================================================

    /// <summary>
    /// Request to export data
    /// </summary>
    public class ExportDataRequest
    {
        [Required]
        public Guid TenantId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        [StringLength(50)]
        public required string ExportType { get; set; }

        [Required]
        [StringLength(20)]
        public required string Format { get; set; } // CSV, Excel, PDF

        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public List<Guid>? LocationIds { get; set; }
        public List<string>? IncludeFields { get; set; }
    }

    /// <summary>
    /// Export job status
    /// </summary>
    public class ExportJobDto
    {
        public Guid ExportJobId { get; set; }
        public Guid TenantId { get; set; }
        public Guid UserId { get; set; }
        public required string ExportType { get; set; }
        public required string Format { get; set; }
        public required string Status { get; set; }
        public string? DownloadUrl { get; set; }
        public string? ErrorMessage { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime? CompletedDate { get; set; }
    }

    // ============================================================================
    // Historical Import Lockout DTOs
    // ============================================================================

    /// <summary>
    /// Request to toggle historical import feature
    /// </summary>
    public class ToggleHistoricalImportsRequest
    {
        [Required]
        public Guid TenantId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [Required]
        public bool Enable { get; set; }

        [StringLength(500)]
        public string? Reason { get; set; }
    }

    /// <summary>
    /// Response with historical import status
    /// </summary>
    public class HistoricalImportsStatusResponse
    {
        public Guid TenantId { get; set; }
        public bool AllowHistoricalImports { get; set; }
        public DateTime? LastModifiedDate { get; set; }
        public string? LastModifiedBy { get; set; }
    }
}
