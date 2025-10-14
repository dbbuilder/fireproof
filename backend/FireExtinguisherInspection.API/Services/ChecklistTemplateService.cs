using System.Data;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using Microsoft.Data.SqlClient;

namespace FireExtinguisherInspection.API.Services;

/// <summary>
/// Service for checklist template management operations
/// </summary>
public class ChecklistTemplateService : IChecklistTemplateService
{
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly ILogger<ChecklistTemplateService> _logger;

    public ChecklistTemplateService(
        IDbConnectionFactory connectionFactory,
        ILogger<ChecklistTemplateService> logger)
    {
        _connectionFactory = connectionFactory;
        _logger = logger;
    }

    public async Task<IEnumerable<ChecklistTemplateDto>> GetSystemTemplatesAsync()
    {
        _logger.LogDebug("Fetching system checklist templates");

        // System templates are stored in tenant schemas with TenantId = NULL
        // We'll query from DEMO001 schema as a reference schema
        var schemaName = "tenant_8b27e8a1-5a5b-4e8a-8f5e-1a2b3c4d5e6f"; // DEMO001 TenantId
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistTemplate_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", DBNull.Value); // NULL for system templates
        command.Parameters.AddWithValue("@IsActive", true);

        var templates = new List<ChecklistTemplateDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            templates.Add(MapTemplateFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} system templates", templates.Count);

        return templates;
    }

    public async Task<IEnumerable<ChecklistTemplateDto>> GetTenantTemplatesAsync(Guid tenantId, bool activeOnly = true)
    {
        _logger.LogDebug("Fetching checklist templates for tenant {TenantId}, activeOnly: {ActiveOnly}", tenantId, activeOnly);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistTemplate_GetAll";
        command.CommandType = CommandType.StoredProcedure;

        // Pass NULL to get both system and tenant templates
        command.Parameters.AddWithValue("@TenantId", DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", activeOnly ? (object)true : DBNull.Value);

        var templates = new List<ChecklistTemplateDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            templates.Add(MapTemplateFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} templates for tenant {TenantId}", templates.Count, tenantId);

        return templates;
    }

    public async Task<ChecklistTemplateDto?> GetTemplateByIdAsync(Guid templateId)
    {
        _logger.LogDebug("Fetching checklist template {TemplateId}", templateId);

        // We need to query from a tenant schema - use DEMO001 as default
        // In production, you might want to pass tenantId as well
        var schemaName = "tenant_8b27e8a1-5a5b-4e8a-8f5e-1a2b3c4d5e6f"; // DEMO001
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistTemplate_GetById";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TemplateId", templateId);

        ChecklistTemplateDto? template = null;

        using var reader = await command.ExecuteReaderAsync();

        // First result set: Template
        if (await reader.ReadAsync())
        {
            template = MapTemplateFromReader(reader);
        }

        // Second result set: ChecklistItems
        if (template != null && await reader.NextResultAsync())
        {
            template.Items = new List<ChecklistItemDto>();
            while (await reader.ReadAsync())
            {
                template.Items.Add(MapChecklistItemFromReader(reader));
            }
        }

        if (template == null)
        {
            _logger.LogWarning("Template {TemplateId} not found", templateId);
        }

        return template;
    }

    public async Task<IEnumerable<ChecklistTemplateDto>> GetTemplatesByTypeAsync(Guid tenantId, string inspectionType)
    {
        _logger.LogDebug("Fetching checklist templates for tenant {TenantId}, type: {InspectionType}", tenantId, inspectionType);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistTemplate_GetByType";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@InspectionType", inspectionType);
        command.Parameters.AddWithValue("@IsActive", true);

        var templates = new List<ChecklistTemplateDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            templates.Add(MapTemplateFromReader(reader));
        }

        _logger.LogInformation("Retrieved {Count} templates of type {InspectionType} for tenant {TenantId}",
            templates.Count, inspectionType, tenantId);

        return templates;
    }

    public async Task<ChecklistTemplateDto> CreateCustomTemplateAsync(Guid tenantId, CreateChecklistTemplateRequest request)
    {
        _logger.LogInformation("Creating custom checklist template for tenant {TenantId}: {TemplateName}",
            tenantId, request.TemplateName);

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistTemplate_Create";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@TemplateName", request.TemplateName);
        command.Parameters.AddWithValue("@InspectionType", request.InspectionType);
        command.Parameters.AddWithValue("@Standard", request.Standard);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsSystemTemplate", false); // Custom templates are never system templates

        using var reader = await command.ExecuteReaderAsync();

        if (await reader.ReadAsync())
        {
            var templateId = reader.GetGuid(reader.GetOrdinal("TemplateId"));

            _logger.LogInformation("Custom template created successfully: {TemplateId}", templateId);

            // Fetch the created template to return full details
            return await GetTemplateByIdAsync(templateId)
                ?? throw new InvalidOperationException("Failed to retrieve created template");
        }

        throw new InvalidOperationException("Failed to create custom template");
    }

    public async Task<IEnumerable<ChecklistItemDto>> AddTemplateItemsAsync(Guid templateId, CreateChecklistItemsRequest request)
    {
        _logger.LogInformation("Adding {Count} items to template {TemplateId}", request.Items.Count, templateId);

        // We need to determine the schema - for now use DEMO001
        var schemaName = "tenant_8b27e8a1-5a5b-4e8a-8f5e-1a2b3c4d5e6f"; // DEMO001
        using var connection = await _connectionFactory.CreateConnectionAsync();

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $"[{schemaName}].usp_ChecklistItem_CreateBatch";
        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@TemplateId", templateId);

        // Create table-valued parameter for items
        var itemsTable = new DataTable();
        itemsTable.Columns.Add("ItemText", typeof(string));
        itemsTable.Columns.Add("ItemDescription", typeof(string));
        itemsTable.Columns.Add("ItemOrder", typeof(int));
        itemsTable.Columns.Add("Category", typeof(string));
        itemsTable.Columns.Add("Required", typeof(bool));
        itemsTable.Columns.Add("RequiresPhoto", typeof(bool));
        itemsTable.Columns.Add("RequiresComment", typeof(bool));
        itemsTable.Columns.Add("PassFailNA", typeof(bool));
        itemsTable.Columns.Add("VisualAid", typeof(string));

        foreach (var item in request.Items)
        {
            itemsTable.Rows.Add(
                item.ItemText,
                item.ItemDescription ?? (object)DBNull.Value,
                item.Order,
                item.Category,
                item.Required,
                item.RequiresPhoto,
                item.RequiresComment,
                item.PassFailNA,
                item.VisualAid ?? (object)DBNull.Value
            );
        }

        var itemsParam = command.Parameters.AddWithValue("@Items", itemsTable);
        itemsParam.SqlDbType = SqlDbType.Structured;
        itemsParam.TypeName = $"[{schemaName}].ChecklistItemTableType";

        var createdItems = new List<ChecklistItemDto>();

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            createdItems.Add(MapChecklistItemFromReader(reader));
        }

        _logger.LogInformation("Added {Count} items to template {TemplateId}", createdItems.Count, templateId);

        return createdItems;
    }

    public async Task<ChecklistTemplateDto> UpdateTemplateAsync(Guid tenantId, Guid templateId, UpdateChecklistTemplateRequest request)
    {
        _logger.LogInformation("Updating template {TemplateId} for tenant {TenantId}", templateId, tenantId);

        // First verify the template exists and belongs to this tenant (not a system template)
        var existingTemplate = await GetTemplateByIdAsync(templateId);
        if (existingTemplate == null)
        {
            throw new KeyNotFoundException($"Template {templateId} not found");
        }

        if (existingTemplate.IsSystemTemplate)
        {
            throw new InvalidOperationException("Cannot modify system templates");
        }

        if (existingTemplate.TenantId != tenantId)
        {
            throw new UnauthorizedAccessException("Template does not belong to this tenant");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        // Direct UPDATE since we don't have an update stored procedure yet
        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].ChecklistTemplates
            SET TemplateName = COALESCE(@TemplateName, TemplateName),
                Description = COALESCE(@Description, Description),
                IsActive = COALESCE(@IsActive, IsActive),
                ModifiedDate = GETUTCDATE()
            WHERE TemplateId = @TemplateId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@TemplateId", templateId);
        command.Parameters.AddWithValue("@TenantId", tenantId);
        command.Parameters.AddWithValue("@TemplateName", (object?)request.TemplateName ?? DBNull.Value);
        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
        command.Parameters.AddWithValue("@IsActive", (object?)request.IsActive ?? DBNull.Value);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected == 0)
        {
            throw new InvalidOperationException("Failed to update template");
        }

        _logger.LogInformation("Template {TemplateId} updated successfully", templateId);

        return await GetTemplateByIdAsync(templateId)
            ?? throw new InvalidOperationException("Failed to retrieve updated template");
    }

    public async Task<bool> DeactivateTemplateAsync(Guid tenantId, Guid templateId)
    {
        _logger.LogInformation("Deactivating template {TemplateId} for tenant {TenantId}", templateId, tenantId);

        // Verify template is not a system template
        var existingTemplate = await GetTemplateByIdAsync(templateId);
        if (existingTemplate == null)
        {
            return false;
        }

        if (existingTemplate.IsSystemTemplate)
        {
            throw new InvalidOperationException("Cannot deactivate system templates");
        }

        if (existingTemplate.TenantId != tenantId)
        {
            throw new UnauthorizedAccessException("Template does not belong to this tenant");
        }

        var schemaName = await _connectionFactory.GetTenantSchemaAsync(tenantId);
        using var connection = await _connectionFactory.CreateTenantConnectionAsync(tenantId);

        using var command = (SqlCommand)connection.CreateCommand();
        command.CommandText = $@"
            UPDATE [{schemaName}].ChecklistTemplates
            SET IsActive = 0,
                ModifiedDate = GETUTCDATE()
            WHERE TemplateId = @TemplateId AND TenantId = @TenantId";

        command.Parameters.AddWithValue("@TemplateId", templateId);
        command.Parameters.AddWithValue("@TenantId", tenantId);

        var rowsAffected = await command.ExecuteNonQueryAsync();

        if (rowsAffected > 0)
        {
            _logger.LogInformation("Template {TemplateId} deactivated successfully", templateId);
            return true;
        }

        _logger.LogWarning("Template {TemplateId} not found or already deactivated", templateId);
        return false;
    }

    private static ChecklistTemplateDto MapTemplateFromReader(SqlDataReader reader)
    {
        return new ChecklistTemplateDto
        {
            TemplateId = reader.GetGuid(reader.GetOrdinal("TemplateId")),
            TenantId = reader.IsDBNull(reader.GetOrdinal("TenantId")) ? null : reader.GetGuid(reader.GetOrdinal("TenantId")),
            TemplateName = reader.GetString(reader.GetOrdinal("TemplateName")),
            InspectionType = reader.GetString(reader.GetOrdinal("InspectionType")),
            Standard = reader.GetString(reader.GetOrdinal("Standard")),
            IsSystemTemplate = reader.GetBoolean(reader.GetOrdinal("IsSystemTemplate")),
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
            Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate")),
            ModifiedDate = reader.IsDBNull(reader.GetOrdinal("ModifiedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedDate"))
        };
    }

    private static ChecklistItemDto MapChecklistItemFromReader(SqlDataReader reader)
    {
        return new ChecklistItemDto
        {
            ChecklistItemId = reader.GetGuid(reader.GetOrdinal("ChecklistItemId")),
            TemplateId = reader.GetGuid(reader.GetOrdinal("TemplateId")),
            ItemText = reader.GetString(reader.GetOrdinal("ItemText")),
            ItemDescription = reader.IsDBNull(reader.GetOrdinal("ItemDescription")) ? null : reader.GetString(reader.GetOrdinal("ItemDescription")),
            Order = reader.GetInt32(reader.GetOrdinal("ItemOrder")),
            Category = reader.GetString(reader.GetOrdinal("Category")),
            Required = reader.GetBoolean(reader.GetOrdinal("Required")),
            RequiresPhoto = reader.GetBoolean(reader.GetOrdinal("RequiresPhoto")),
            RequiresComment = reader.GetBoolean(reader.GetOrdinal("RequiresComment")),
            PassFailNA = reader.GetBoolean(reader.GetOrdinal("PassFailNA")),
            VisualAid = reader.IsDBNull(reader.GetOrdinal("VisualAid")) ? null : reader.GetString(reader.GetOrdinal("VisualAid")),
            CreatedDate = reader.GetDateTime(reader.GetOrdinal("CreatedDate"))
        };
    }
}
