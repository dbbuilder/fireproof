using System.Security.Claims;
using FireExtinguisherInspection.API.Models;

namespace FireExtinguisherInspection.API.Middleware;

/// <summary>
/// Middleware to resolve tenant context from JWT claims
/// Sets the TenantContext for the current request
/// </summary>
public class TenantResolutionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TenantResolutionMiddleware> _logger;

    public TenantResolutionMiddleware(
        RequestDelegate next,
        ILogger<TenantResolutionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, TenantContext tenantContext)
    {
        // Skip tenant resolution for health checks and swagger
        if (context.Request.Path.StartsWithSegments("/health") ||
            context.Request.Path.StartsWithSegments("/swagger"))
        {
            await _next(context);
            return;
        }

        // Extract tenant information from claims
        var user = context.User;

        if (user.Identity?.IsAuthenticated == true)
        {
            // Get tenant ID from claims
            var tenantIdClaim = user.FindFirst("tenant_id") ?? user.FindFirst("tenantId");
            if (tenantIdClaim != null && Guid.TryParse(tenantIdClaim.Value, out var tenantId))
            {
                tenantContext.TenantId = tenantId;
                _logger.LogDebug("Resolved tenant ID: {TenantId}", tenantId);
            }
            else
            {
                _logger.LogWarning("Tenant ID claim not found or invalid for authenticated user");
            }

            // Get user ID from claims
            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier) ?? user.FindFirst("sub");
            if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var userId))
            {
                tenantContext.UserId = userId;
            }

            // Get role from claims
            var roleClaim = user.FindFirst(ClaimTypes.Role) ?? user.FindFirst("role");
            if (roleClaim != null)
            {
                tenantContext.Role = roleClaim.Value;
            }

            // Get tenant code from claims
            var tenantCodeClaim = user.FindFirst("tenant_code") ?? user.FindFirst("tenantCode");
            if (tenantCodeClaim != null)
            {
                tenantContext.TenantCode = tenantCodeClaim.Value;
            }
        }
        else
        {
            _logger.LogDebug("Request is not authenticated, skipping tenant resolution");
        }

        await _next(context);
    }
}

/// <summary>
/// Extension methods for registering tenant resolution middleware
/// </summary>
public static class TenantResolutionMiddlewareExtensions
{
    public static IApplicationBuilder UseTenantResolution(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<TenantResolutionMiddleware>();
    }
}
