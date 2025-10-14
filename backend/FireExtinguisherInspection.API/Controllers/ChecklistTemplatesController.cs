using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Helpers;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FireExtinguisherInspection.API.Controllers;

/// <summary>
/// API controller for checklist template management (NFPA, Title19, ULC standards)
/// Supports system templates (read-only) and tenant-specific custom templates
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] // Require authentication for all endpoints
public class ChecklistTemplatesController : ControllerBase
{
    private readonly IChecklistTemplateService _templateService;
    private readonly TenantContext _tenantContext;
    private readonly ILogger<ChecklistTemplatesController> _logger;

    public ChecklistTemplatesController(
        IChecklistTemplateService templateService,
        TenantContext tenantContext,
        ILogger<ChecklistTemplatesController> logger)
    {
        _templateService = templateService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Retrieves all system templates (NFPA 10, Title 19, ULC standards)
    /// </summary>
    /// <returns>List of system checklist templates</returns>
    [HttpGet("system")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ChecklistTemplateDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IEnumerable<ChecklistTemplateDto>>> GetSystemTemplates()
    {
        _logger.LogDebug("Fetching system checklist templates");
        var templates = await _templateService.GetSystemTemplatesAsync();
        return Ok(templates);
    }

    /// <summary>
    /// Retrieves all templates available to the current tenant (system + custom)
    /// SystemAdmin users can optionally specify a tenantId parameter
    /// </summary>
    /// <param name="activeOnly">Filter by active status (default: true)</param>
    /// <param name="tenantId">Tenant ID (SystemAdmin only)</param>
    /// <returns>List of available checklist templates</returns>
    [HttpGet]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ChecklistTemplateDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ChecklistTemplateDto>>> GetAllTemplates(
        [FromQuery] bool activeOnly = true,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                // SystemAdmin without tenant - return system templates only
                _logger.LogDebug("SystemAdmin without tenantId - returning system templates");
                var systemTemplates = await _templateService.GetSystemTemplatesAsync();
                return Ok(systemTemplates);
            }
            return Unauthorized(new { message = errorMessage });
        }

        _logger.LogDebug("Fetching templates for tenant {TenantId}", effectiveTenantId);
        var templates = await _templateService.GetTenantTemplatesAsync(effectiveTenantId, activeOnly);
        return Ok(templates);
    }

    /// <summary>
    /// Retrieves a specific template by ID with all checklist items
    /// </summary>
    /// <param name="id">Template ID</param>
    /// <returns>Template details with checklist items</returns>
    [HttpGet("{id}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(ChecklistTemplateDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<ChecklistTemplateDto>> GetTemplateById(Guid id)
    {
        _logger.LogDebug("Fetching template {TemplateId}", id);

        var template = await _templateService.GetTemplateByIdAsync(id);

        if (template == null)
        {
            return NotFound(new { message = $"Template {id} not found" });
        }

        return Ok(template);
    }

    /// <summary>
    /// Retrieves templates by inspection type (Monthly, Annual, SixYear, TwelveYear, Hydrostatic)
    /// </summary>
    /// <param name="inspectionType">Inspection type</param>
    /// <param name="tenantId">Tenant ID (SystemAdmin only)</param>
    /// <returns>List of templates for the specified inspection type</returns>
    [HttpGet("type/{inspectionType}")]
    [Authorize(Policy = AuthorizationPolicies.InspectorOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ChecklistTemplateDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IEnumerable<ChecklistTemplateDto>>> GetTemplatesByType(
        string inspectionType,
        [FromQuery] Guid? tenantId = null)
    {
        if (!TenantResolver.TryResolveTenantId(User, _tenantContext, tenantId, out var effectiveTenantId, out var errorMessage))
        {
            if (TenantResolver.IsSystemAdmin(User) && !tenantId.HasValue)
            {
                // SystemAdmin without tenant - return system templates only
                _logger.LogDebug("SystemAdmin without tenantId - returning system templates for type {InspectionType}", inspectionType);
                var systemTemplates = await _templateService.GetSystemTemplatesAsync();
                var filtered = systemTemplates.Where(t => t.InspectionType.Equals(inspectionType, StringComparison.OrdinalIgnoreCase));
                return Ok(filtered);
            }
            return Unauthorized(new { message = errorMessage });
        }

        _logger.LogDebug("Fetching templates of type {InspectionType} for tenant {TenantId}", inspectionType, effectiveTenantId);
        var templates = await _templateService.GetTemplatesByTypeAsync(effectiveTenantId, inspectionType);
        return Ok(templates);
    }

    /// <summary>
    /// Creates a custom checklist template for the current tenant
    /// </summary>
    /// <param name="request">Template creation request</param>
    /// <returns>Created template</returns>
    [HttpPost]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ChecklistTemplateDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ChecklistTemplateDto>> CreateCustomTemplate([FromBody] CreateChecklistTemplateRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Creating custom template for tenant {TenantId}: {TemplateName}",
            _tenantContext.TenantId, request.TemplateName);

        var template = await _templateService.CreateCustomTemplateAsync(_tenantContext.TenantId, request);

        return CreatedAtAction(
            nameof(GetTemplateById),
            new { id = template.TemplateId },
            template);
    }

    /// <summary>
    /// Adds checklist items to a template (system or custom)
    /// Only tenant admins can add items to custom templates they own
    /// </summary>
    /// <param name="id">Template ID</param>
    /// <param name="request">Checklist items to add</param>
    /// <returns>Created checklist items</returns>
    [HttpPost("{id}/items")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(IEnumerable<ChecklistItemDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<ChecklistItemDto>>> AddTemplateItems(
        Guid id,
        [FromBody] CreateChecklistItemsRequest request)
    {
        _logger.LogInformation("Adding {Count} items to template {TemplateId}", request.Items.Count, id);

        // Verify template exists
        var template = await _templateService.GetTemplateByIdAsync(id);
        if (template == null)
        {
            return NotFound(new { message = $"Template {id} not found" });
        }

        // Verify template belongs to this tenant (if not system template)
        if (!template.IsSystemTemplate && template.TenantId != _tenantContext.TenantId)
        {
            return Forbid();
        }

        // Cannot modify system templates
        if (template.IsSystemTemplate)
        {
            return BadRequest(new { message = "Cannot add items to system templates" });
        }

        var items = await _templateService.AddTemplateItemsAsync(id, request);

        return CreatedAtAction(
            nameof(GetTemplateById),
            new { id },
            items);
    }

    /// <summary>
    /// Updates a custom checklist template
    /// Cannot modify system templates
    /// </summary>
    /// <param name="id">Template ID</param>
    /// <param name="request">Template update request</param>
    /// <returns>Updated template</returns>
    [HttpPut("{id}")]
    [Authorize(Policy = AuthorizationPolicies.ManagerOrAbove)]
    [ProducesResponseType(typeof(ChecklistTemplateDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ChecklistTemplateDto>> UpdateTemplate(
        Guid id,
        [FromBody] UpdateChecklistTemplateRequest request)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Updating template {TemplateId} for tenant {TenantId}", id, _tenantContext.TenantId);

        try
        {
            var template = await _templateService.UpdateTemplateAsync(_tenantContext.TenantId, id, request);
            return Ok(template);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Deactivates a custom checklist template (soft delete)
    /// Cannot delete system templates
    /// </summary>
    /// <param name="id">Template ID</param>
    /// <returns>No content on success</returns>
    [HttpDelete("{id}")]
    [Authorize(Policy = AuthorizationPolicies.AdminOrTenantAdmin)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeactivateTemplate(Guid id)
    {
        if (_tenantContext.TenantId == Guid.Empty)
        {
            return Unauthorized(new { message = "Tenant context not found" });
        }

        _logger.LogInformation("Deactivating template {TemplateId} for tenant {TenantId}", id, _tenantContext.TenantId);

        try
        {
            var success = await _templateService.DeactivateTemplateAsync(_tenantContext.TenantId, id);

            if (!success)
            {
                return NotFound(new { message = $"Template {id} not found" });
            }

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }
}
