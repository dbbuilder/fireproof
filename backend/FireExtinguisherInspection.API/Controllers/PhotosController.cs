using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for inspection photo management
/// Mobile-first design with support for native iOS/Android apps
/// Handles photo upload, EXIF extraction, thumbnail generation, and secure access
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class PhotosController : ControllerBase
{
    private readonly IPhotoService _photoService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<PhotosController> _logger;

    public PhotosController(
        IPhotoService photoService,
        TenantContext tenantContext,
        ILogger<PhotosController> logger)
    {
        _photoService = photoService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    // ==================== UPLOAD OPERATIONS (MOBILE-OPTIMIZED) ====================

    /// <summary>
    /// Uploads a single photo for an inspection
    /// Mobile-optimized: Accepts up to 50MB, extracts EXIF, generates thumbnail
    /// Supports: JPEG, PNG, HEIC (iOS native format)
    /// </summary>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [RequestSizeLimit(52428800)] // 50 MB limit
    [ProducesResponseType(typeof(PhotoUploadResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<PhotoUploadResponse>> UploadPhoto([FromForm] UploadPhotoRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            _logger.LogInformation("Uploading photo for inspection {InspectionId}, type: {PhotoType}, size: {FileSize} bytes",
                request.InspectionId, request.PhotoType, request.File.Length);

            var response = await _photoService.UploadPhotoAsync(_tenantContext.TenantId, request);

            return CreatedAtAction(
                nameof(GetPhotoById),
                new { id = response.PhotoId },
                response);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading photo for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to upload photo", error = ex.Message });
        }
    }

    /// <summary>
    /// Uploads multiple photos in batch (offline queue sync optimization)
    /// Mobile use case: Inspector works offline, syncs photos when back online
    /// </summary>
    [HttpPost("batch")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [RequestSizeLimit(524288000)] // 500 MB limit for batch
    [ProducesResponseType(typeof(IEnumerable<PhotoUploadResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<PhotoUploadResponse>>> UploadPhotosBatch([FromForm] List<UploadPhotoRequest> requests)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        if (requests.Count == 0)
            return BadRequest(new { message = "No photos provided" });

        if (requests.Count > 50) // Reasonable batch limit
            return BadRequest(new { message = "Maximum 50 photos per batch" });

        try
        {
            _logger.LogInformation("Uploading {Count} photos in batch for tenant {TenantId}",
                requests.Count, _tenantContext.TenantId);

            var responses = await _photoService.UploadPhotosAsync(_tenantContext.TenantId, requests);

            return CreatedAtAction(
                nameof(GetPhotosByInspection),
                new { inspectionId = requests.First().InspectionId },
                responses);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading photos in batch for tenant {TenantId}", _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to upload photos", error = ex.Message });
        }
    }

    // ==================== QUERY OPERATIONS ====================

    /// <summary>
    /// Gets a specific photo by ID with full EXIF data
    /// </summary>
    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(InspectionPhotoDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<InspectionPhotoDto>> GetPhotoById(Guid id, [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning not found");
                return NotFound(new { message = $"Photo {id} not found" });
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var photo = await _photoService.GetPhotoByIdAsync(effectiveTenantId, id);

            if (photo == null)
                return NotFound(new { message = $"Photo {id} not found" });

            return Ok(photo);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving photo {PhotoId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve photo", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets all photos for a specific inspection
    /// Mobile-optimized: Returns thumbnail URLs for fast list rendering
    /// </summary>
    [HttpGet("inspection/{inspectionId:guid}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhotoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhotoDto>>> GetPhotosByInspection(
        Guid inspectionId,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhotoDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var photos = await _photoService.GetPhotosByInspectionAsync(effectiveTenantId, inspectionId);
            return Ok(photos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving photos for inspection {InspectionId} for tenant {TenantId}",
                inspectionId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve photos", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets photos by type (Location, PhysicalCondition, Pressure, Label, Seal, Hose, Deficiency, Other)
    /// </summary>
    [HttpGet("inspection/{inspectionId:guid}/type/{photoType}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<InspectionPhotoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<InspectionPhotoDto>>> GetPhotosByType(
        Guid inspectionId,
        string photoType,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning empty result");
                return Ok(Array.Empty<InspectionPhotoDto>());
            }
            return Unauthorized(new { message = errorMessage });
        }

        // Validate photo type
        var validTypes = new[] { "Location", "PhysicalCondition", "Pressure", "Label", "Seal", "Hose", "Deficiency", "Other" };
        if (!validTypes.Contains(photoType, StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = $"Invalid photo type. Must be one of: {string.Join(", ", validTypes)}" });
        }

        try
        {
            var photos = await _photoService.GetPhotosByTypeAsync(effectiveTenantId, inspectionId, photoType);
            return Ok(photos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving {PhotoType} photos for inspection {InspectionId} for tenant {TenantId}",
                photoType, inspectionId, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to retrieve photos", error = ex.Message });
        }
    }

    // ==================== SECURE ACCESS (MOBILE & NATIVE APP SUPPORT) ====================

    /// <summary>
    /// Gets a signed URL for secure photo access (expires after specified minutes)
    /// Mobile/Native app use: Generate temporary links for photo viewing
    /// </summary>
    [HttpGet("{id:guid}/url")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<string>> GetPhotoUrl(
        Guid id,
        [FromQuery] int expirationMinutes = 60,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning not found");
                return NotFound(new { message = $"Photo {id} not found" });
            }
            return Unauthorized(new { message = errorMessage });
        }

        // Validate expiration range (5 minutes to 24 hours)
        if (expirationMinutes < 5 || expirationMinutes > 1440)
        {
            return BadRequest(new { message = "Expiration must be between 5 and 1440 minutes" });
        }

        try
        {
            var url = await _photoService.GetPhotoUrlAsync(effectiveTenantId, id, expirationMinutes);
            return Ok(new { url, expiresIn = expirationMinutes });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = $"Photo {id} not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating photo URL for {PhotoId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to generate photo URL", error = ex.Message });
        }
    }

    /// <summary>
    /// Gets a signed URL for thumbnail (mobile optimization for list views)
    /// Use this for image galleries and list previews to reduce bandwidth
    /// </summary>
    [HttpGet("{id:guid}/thumbnail")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<string>> GetThumbnailUrl(
        Guid id,
        [FromQuery] int expirationMinutes = 60,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                _logger.LogDebug("SystemAdmin without tenantId - returning not found");
                return NotFound(new { message = $"Thumbnail for photo {id} not found" });
            }
            return Unauthorized(new { message = errorMessage });
        }

        try
        {
            var url = await _photoService.GetThumbnailUrlAsync(effectiveTenantId, id, expirationMinutes);
            return Ok(new { url, expiresIn = expirationMinutes });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating thumbnail URL for {PhotoId} for tenant {TenantId}",
                id, effectiveTenantId);
            return StatusCode(500, new { message = "Failed to generate thumbnail URL", error = ex.Message });
        }
    }

    // ==================== DELETE OPERATIONS ====================

    /// <summary>
    /// Deletes a photo from Azure Blob Storage and database
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeletePhoto(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
            return Unauthorized(new { message = "Tenant context not found" });

        try
        {
            var success = await _photoService.DeletePhotoAsync(_tenantContext.TenantId, id);

            if (!success)
                return NotFound(new { message = $"Photo {id} not found" });

            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting photo {PhotoId} for tenant {TenantId}",
                id, _tenantContext.TenantId);
            return StatusCode(500, new { message = "Failed to delete photo", error = ex.Message });
        }
    }
}
