namespace FireExtinguisherInspection.API.Models
{
    /// <summary>
    /// Summary information about a tenant for display in tenant selector
    /// </summary>
    public class TenantSummaryDto
    {
        public Guid TenantId { get; set; }
        public string TenantName { get; set; } = string.Empty;
        public string TenantCode { get; set; } = string.Empty;
        public string UserRole { get; set; } = string.Empty; // TenantAdmin, LocationManager, Inspector, Viewer
        public bool IsActive { get; set; }
        public DateTime? LastAccessedDate { get; set; }
        public int LocationCount { get; set; }
        public int ExtinguisherCount { get; set; }
    }

    /// <summary>
    /// Request to switch active tenant
    /// </summary>
    public class SwitchTenantRequest
    {
        public Guid TenantId { get; set; }
    }

    /// <summary>
    /// Response after switching tenant (includes new JWT token)
    /// </summary>
    public class SwitchTenantResponse
    {
        public Guid TenantId { get; set; }
        public string TenantName { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty; // New JWT with updated TenantId claim
        public DateTime TokenExpiration { get; set; }
    }
}
