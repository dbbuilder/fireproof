using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Middleware;
using FireExtinguisherInspection.API.Models;
using FireExtinguisherInspection.API.Services;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

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

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5173",  // Vite dev server
                "http://localhost:3000",   // Alternative frontend port
                "https://fireproof.app",   // Production domain
                "https://www.fireproof.app"
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")!,
        name: "database",
        tags: new[] { "db", "sql" });

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

// Authentication and Authorization will be added here
// app.UseAuthentication();
// app.UseAuthorization();

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
