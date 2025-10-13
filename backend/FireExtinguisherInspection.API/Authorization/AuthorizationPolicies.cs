namespace FireExtinguisherInspection.API.Authorization;

/// <summary>
/// Constants for authorization policy names
/// </summary>
public static class AuthorizationPolicies
{
    // System-level policies
    public const string SystemAdmin = "SystemAdmin";
    public const string SystemAdminOnly = "SystemAdminOnly";
    public const string SuperUser = "SuperUser";

    // Tenant-level policies
    public const string TenantAdmin = "TenantAdmin";
    public const string TenantManager = "TenantManager";
    public const string Inspector = "Inspector";
    public const string Viewer = "Viewer";

    // Combined policies (system OR tenant roles)
    public const string AdminOrTenantAdmin = "AdminOrTenantAdmin";
    public const string ManagerOrAbove = "ManagerOrAbove";
    public const string InspectorOrAbove = "InspectorOrAbove";
}

/// <summary>
/// Constants for role names (must match database values)
/// </summary>
public static class RoleNames
{
    // System roles
    public const string SystemAdmin = "SystemAdmin";
    public const string SuperUser = "SuperUser";

    // Tenant roles
    public const string TenantAdmin = "TenantAdmin";
    public const string TenantManager = "TenantManager";
    public const string Inspector = "Inspector";
    public const string Viewer = "Viewer";
}
