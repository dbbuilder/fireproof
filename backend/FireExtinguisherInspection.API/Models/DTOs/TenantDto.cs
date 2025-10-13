namespace FireExtinguisherInspection.API.Models.DTOs;

/// <summary>
/// Data transfer object for Tenant information
/// </summary>
public class TenantDto
{
    public Guid TenantId { get; set; }
    public string TenantCode { get; set; } = string.Empty;
    public string TenantName { get; set; } = string.Empty;
    public string SubscriptionTier { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int MaxLocations { get; set; }
    public int MaxUsers { get; set; }
    public int MaxExtinguishers { get; set; }
    public string DatabaseSchema { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public DateTime ModifiedDate { get; set; }

    // Optional role information (populated for user-specific queries)
    public string? RoleName { get; set; }
}

/// <summary>
/// Request model for creating a new tenant
/// </summary>
public class CreateTenantRequest
{
    public string TenantCode { get; set; } = string.Empty;
    public string TenantName { get; set; } = string.Empty;
    public string SubscriptionTier { get; set; } = "Free";
    public int MaxLocations { get; set; } = 10;
    public int MaxUsers { get; set; } = 5;
    public int MaxExtinguishers { get; set; } = 100;
}

/// <summary>
/// Request model for updating an existing tenant
/// </summary>
public class UpdateTenantRequest
{
    public string TenantName { get; set; } = string.Empty;
    public string SubscriptionTier { get; set; } = string.Empty;
    public int MaxLocations { get; set; }
    public int MaxUsers { get; set; }
    public int MaxExtinguishers { get; set; }
    public bool IsActive { get; set; }
}
