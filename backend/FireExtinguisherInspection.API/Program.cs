using System.Text;
using Azure.Identity;
using FireExtinguisherInspection.API.Authorization;
using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Middleware;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Azure Key Vault if VaultUri is provided
var keyVaultUri = builder.Configuration["KeyVault:VaultUri"];
if (!string.IsNullOrEmpty(keyVaultUri))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUri),
        new DefaultAzureCredential());

    Log.Information("Azure Key Vault configured: {VaultUri}", keyVaultUri);
}

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "FireProof API",
        Version = "v1",
        Description = "Fire Extinguisher Inspection System API",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "FireProof Support",
            Email = "support@fireproof.app"
        }
    });

    // Add JWT authentication to Swagger
    options.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\""
    });

    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Add memory cache
builder.Services.AddMemoryCache();

// Register core services
builder.Services.AddScoped<TenantContext>();
builder.Services.AddSingleton<IDbConnectionFactory, DbConnectionFactory>();

// Register application services
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IExtinguisherTypeService, ExtinguisherTypeService>();
builder.Services.AddScoped<IExtinguisherService, ExtinguisherService>();
builder.Services.AddScoped<IInspectionService, InspectionService>();
builder.Services.AddSingleton<IBarcodeGeneratorService, BarcodeGeneratorService>();
builder.Services.AddSingleton<ITamperProofingService, TamperProofingService>();

// Register authentication services
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthenticationService, AuthenticationService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5173",  // Vite dev server
                "http://localhost:3000",   // Alternative frontend port
                "https://fireproofapp.net",  // Production domain
                "https://www.fireproofapp.net",
                "https://nice-smoke-08dbc500f.2.azurestaticapps.net"  // Azure Static Web App
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

// Configure JWT Authentication
var jwtSecretKey = builder.Configuration["Jwt:SecretKey"]
    ?? throw new InvalidOperationException("JWT SecretKey not configured");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "FireProofAPI";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "FireProofApp";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
        ClockSkew = TimeSpan.Zero // No tolerance for expiry
    };
});

// Configure Authorization with policies
builder.Services.AddAuthorization(options =>
{
    // System-level policies
    options.AddPolicy(AuthorizationPolicies.SystemAdmin, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleNames.SystemAdmin)));

    options.AddPolicy(AuthorizationPolicies.SuperUser, policy =>
        policy.Requirements.Add(new RoleRequirement(RoleNames.SuperUser)));

    // Tenant-level policies
    options.AddPolicy(AuthorizationPolicies.TenantAdmin, policy =>
        policy.Requirements.Add(new RoleRequirement(true, RoleNames.TenantAdmin)));

    options.AddPolicy(AuthorizationPolicies.TenantManager, policy =>
        policy.Requirements.Add(new RoleRequirement(true, RoleNames.TenantManager)));

    options.AddPolicy(AuthorizationPolicies.Inspector, policy =>
        policy.Requirements.Add(new RoleRequirement(true, RoleNames.Inspector)));

    options.AddPolicy(AuthorizationPolicies.Viewer, policy =>
        policy.Requirements.Add(new RoleRequirement(true, RoleNames.Viewer)));

    // Combined policies (system OR tenant roles)
    options.AddPolicy(AuthorizationPolicies.AdminOrTenantAdmin, policy =>
        policy.Requirements.Add(new RoleRequirement(
            new[] { RoleNames.SystemAdmin, RoleNames.SuperUser },
            new[] { RoleNames.TenantAdmin })));

    options.AddPolicy(AuthorizationPolicies.ManagerOrAbove, policy =>
        policy.Requirements.Add(new RoleRequirement(
            new[] { RoleNames.SystemAdmin, RoleNames.SuperUser },
            new[] { RoleNames.TenantAdmin, RoleNames.TenantManager })));

    options.AddPolicy(AuthorizationPolicies.InspectorOrAbove, policy =>
        policy.Requirements.Add(new RoleRequirement(
            new[] { RoleNames.SystemAdmin, RoleNames.SuperUser },
            new[] { RoleNames.TenantAdmin, RoleNames.TenantManager, RoleNames.Inspector })));
});

// Register authorization handlers
builder.Services.AddSingleton<IAuthorizationHandler, RoleAuthorizationHandler>();

// Add health checks
builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")!);

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "FireProof API v1");
        options.RoutePrefix = "swagger";
    });
}

// Use custom middleware
app.UseErrorHandling();

app.UseHttpsRedirection();

app.UseCors("AllowFrontend");

// Authentication and Authorization
app.UseAuthentication();
app.UseAuthorization();

// Tenant resolution middleware
app.UseTenantResolution();

// Map controllers and health checks
app.MapControllers();
app.MapHealthChecks("/health");

// Log startup
Log.Information("FireProof API starting up...");
Log.Information("Environment: {Environment}", app.Environment.EnvironmentName);

try
{
    app.Run();
    Log.Information("FireProof API shut down gracefully");
}
catch (Exception ex)
{
    Log.Fatal(ex, "FireProof API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
