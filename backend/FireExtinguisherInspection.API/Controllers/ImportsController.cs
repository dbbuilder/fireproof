using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text.Json;
using System.Threading.Tasks;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace FireExtinguisherInspection.API.Controllers
{
    /// <summary>
    /// API endpoints for data import functionality
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "TenantAdminOrAbove")]
    public class ImportsController : ControllerBase
    {
        private readonly IImportService _importService;
        private readonly ILogger<ImportsController> _logger;

        // Maximum file size: 10MB
        private const long MaxFileSize = 10 * 1024 * 1024;

        // Allowed file extensions
        private static readonly string[] AllowedExtensions = { ".csv", ".xlsx" };

        public ImportsController(
            IImportService importService,
            ILogger<ImportsController> logger)
        {
            _importService = importService;
            _logger = logger;
        }

        // ========================================================================
        // Import Job Management
        // ========================================================================

        /// <summary>
        /// Gets import job history for the current tenant
        /// </summary>
        /// <remarks>
        /// GET /api/imports/history?jobType=HistoricalInspections&pageNumber=1&pageSize=50
        /// </remarks>
        [HttpGet("history")]
        [ProducesResponseType(typeof(ImportHistoryResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<ImportHistoryResponse>> GetImportHistory(
            [FromQuery] string? jobType = null,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var tenantId = GetCurrentTenantId();

                var request = new GetImportHistoryRequest
                {
                    TenantId = tenantId,
                    JobType = jobType,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };

                var result = await _importService.GetImportHistoryAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting import history");
                return StatusCode(500, new { error = "Failed to retrieve import history" });
            }
        }

        /// <summary>
        /// Gets import job details by ID
        /// </summary>
        /// <remarks>
        /// GET /api/imports/{id}
        /// </remarks>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ImportJobDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<ImportJobDto>> GetImportJob(Guid id)
        {
            try
            {
                var job = await _importService.GetImportJobByIdAsync(id);
                if (job == null)
                {
                    return NotFound(new { error = "Import job not found" });
                }

                return Ok(job);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting import job {ImportJobId}", id);
                return StatusCode(500, new { error = "Failed to retrieve import job" });
            }
        }

        // ========================================================================
        // File Upload
        // ========================================================================

        /// <summary>
        /// Uploads a file for import
        /// </summary>
        /// <remarks>
        /// POST /api/imports/upload
        /// Content-Type: multipart/form-data
        /// </remarks>
        [HttpPost("upload")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult> UploadFile([FromForm] IFormFile file, [FromForm] string jobType)
        {
            try
            {
                // Validate file
                if (file == null || file.Length == 0)
                {
                    return BadRequest(new { error = "No file uploaded" });
                }

                if (file.Length > MaxFileSize)
                {
                    return BadRequest(new { error = $"File size exceeds maximum of {MaxFileSize / (1024 * 1024)}MB" });
                }

                var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!AllowedExtensions.Contains(extension))
                {
                    return BadRequest(new { error = $"Invalid file type. Allowed types: {string.Join(", ", AllowedExtensions)}" });
                }

                // Calculate file hash
                string fileHash;
                using (var stream = file.OpenReadStream())
                {
                    using var sha256 = SHA256.Create();
                    var hashBytes = await sha256.ComputeHashAsync(stream);
                    fileHash = BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();
                }

                // Parse CSV and return preview
                List<Dictionary<string, string>> rows;
                using (var stream = file.OpenReadStream())
                {
                    rows = await _importService.ParseCsvAsync(stream);
                }

                // Return first 10 rows for preview
                var previewRows = rows.Take(10).ToList();

                // Detect column headers
                var headers = rows.FirstOrDefault()?.Keys.ToList() ?? new List<string>();

                return Ok(new
                {
                    fileName = file.FileName,
                    fileSize = file.Length,
                    fileHash = fileHash,
                    totalRows = rows.Count,
                    headers = headers,
                    previewRows = previewRows
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading file");
                return StatusCode(500, new { error = $"Failed to upload file: {ex.Message}" });
            }
        }

        // ========================================================================
        // Validation
        // ========================================================================

        /// <summary>
        /// Validates import data (dry run)
        /// </summary>
        /// <remarks>
        /// POST /api/imports/validate
        /// </remarks>
        [HttpPost("validate")]
        [ProducesResponseType(typeof(ValidationResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<ValidationResponse>> ValidateImportData([FromBody] ValidateImportRequest request)
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                var userId = GetCurrentUserId();

                request.TenantId = tenantId;
                request.UserId = userId;

                var result = await _importService.ValidateImportDataAsync(request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating import data");
                return StatusCode(500, new { error = $"Validation failed: {ex.Message}" });
            }
        }

        // ========================================================================
        // Import Execution
        // ========================================================================

        /// <summary>
        /// Creates an import job and starts processing
        /// </summary>
        /// <remarks>
        /// POST /api/imports
        /// </remarks>
        [HttpPost]
        [ProducesResponseType(typeof(ImportJobDto), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<ImportJobDto>> CreateImportJob([FromBody] CreateImportJobRequest request)
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                var userId = GetCurrentUserId();

                request.TenantId = tenantId;
                request.UserId = userId;

                // Validate historical import permissions
                if (request.JobType == "HistoricalInspections")
                {
                    var canImport = await _importService.CanTenantImportHistoricalDataAsync(tenantId);
                    if (!canImport)
                    {
                        return BadRequest(new { error = "Historical inspection imports are disabled for this tenant" });
                    }
                }

                var job = await _importService.CreateImportJobAsync(request);

                // TODO: Queue background job for processing
                // BackgroundJob.Enqueue(() => _importService.ProcessHistoricalInspectionImportAsync(job.ImportJobId));

                return CreatedAtAction(nameof(GetImportJob), new { id = job.ImportJobId }, job);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating import job");
                return StatusCode(500, new { error = $"Failed to create import job: {ex.Message}" });
            }
        }

        // ========================================================================
        // Field Mapping Templates
        // ========================================================================

        /// <summary>
        /// Gets field mapping templates for the current tenant
        /// </summary>
        /// <remarks>
        /// GET /api/imports/mapping-templates?jobType=HistoricalInspections
        /// </remarks>
        [HttpGet("mapping-templates")]
        [ProducesResponseType(typeof(List<FieldMappingTemplateDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<List<FieldMappingTemplateDto>>> GetMappingTemplates([FromQuery] string? jobType = null)
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                var templates = await _importService.GetFieldMappingTemplatesAsync(tenantId, jobType);
                return Ok(templates);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting mapping templates");
                return StatusCode(500, new { error = "Failed to retrieve mapping templates" });
            }
        }

        /// <summary>
        /// Saves a field mapping template
        /// </summary>
        /// <remarks>
        /// POST /api/imports/mapping-templates
        /// </remarks>
        [HttpPost("mapping-templates")]
        [ProducesResponseType(typeof(FieldMappingTemplateDto), StatusCodes.Status201Created)]
        public async Task<ActionResult<FieldMappingTemplateDto>> SaveMappingTemplate([FromBody] SaveFieldMappingTemplateRequest request)
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                request.TenantId = tenantId;

                var template = await _importService.SaveFieldMappingTemplateAsync(request);
                return CreatedAtAction(nameof(GetMappingTemplates), new { jobType = template.JobType }, template);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving mapping template");
                return StatusCode(500, new { error = $"Failed to save mapping template: {ex.Message}" });
            }
        }

        /// <summary>
        /// Deletes a field mapping template
        /// </summary>
        /// <remarks>
        /// DELETE /api/imports/mapping-templates/{id}
        /// </remarks>
        [HttpDelete("mapping-templates/{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> DeleteMappingTemplate(Guid id)
        {
            try
            {
                await _importService.DeleteFieldMappingTemplateAsync(id);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting mapping template {MappingTemplateId}", id);
                return StatusCode(500, new { error = "Failed to delete mapping template" });
            }
        }

        // ========================================================================
        // Historical Import Settings
        // ========================================================================

        /// <summary>
        /// Gets historical import status for current tenant
        /// </summary>
        /// <remarks>
        /// GET /api/imports/historical-status
        /// </remarks>
        [HttpGet("historical-status")]
        [ProducesResponseType(typeof(HistoricalImportsStatusResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<HistoricalImportsStatusResponse>> GetHistoricalImportStatus()
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                var status = await _importService.GetHistoricalImportStatusAsync(tenantId);
                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting historical import status");
                return StatusCode(500, new { error = "Failed to retrieve historical import status" });
            }
        }

        /// <summary>
        /// Toggles historical import feature for current tenant (TenantAdmin only)
        /// </summary>
        /// <remarks>
        /// PUT /api/imports/historical-imports/toggle
        /// </remarks>
        [HttpPut("historical-imports/toggle")]
        [Authorize(Policy = "TenantAdminOrAbove")]
        [ProducesResponseType(typeof(HistoricalImportsStatusResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<HistoricalImportsStatusResponse>> ToggleHistoricalImports([FromBody] ToggleHistoricalImportsRequest request)
        {
            try
            {
                var tenantId = GetCurrentTenantId();
                var userId = GetCurrentUserId();

                request.TenantId = tenantId;
                request.UserId = userId;

                var result = await _importService.ToggleHistoricalImportsAsync(request);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { error = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error toggling historical imports");
                return StatusCode(500, new { error = "Failed to toggle historical imports" });
            }
        }

        // ========================================================================
        // Helper Methods
        // ========================================================================

        private Guid GetCurrentTenantId()
        {
            var tenantIdClaim = User.FindFirst("TenantId")?.Value;
            if (string.IsNullOrEmpty(tenantIdClaim) || !Guid.TryParse(tenantIdClaim, out var tenantId))
            {
                throw new UnauthorizedAccessException("Tenant ID not found in token");
            }
            return tenantId;
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            {
                throw new UnauthorizedAccessException("User ID not found in token");
            }
            return userId;
        }
    }
}
