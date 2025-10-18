using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using FluentAssertions;

namespace FireExtinguisherInspection.IntegrationTests;

[Trait("Category", "Integration")]
public class DatabaseConnectivityTests : IDisposable
{
    private readonly string _connectionString;
    private readonly Guid _tenantAId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly Guid _tenantBId = Guid.Parse("22222222-2222-2222-2222-222222222222");

    public DatabaseConnectivityTests()
    {
        // Configuration is provided via environment variables in GitHub Actions
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("ConnectionStrings__DefaultConnection not set");
    }

    [Fact]
    public async Task DatabaseConnection_ShouldConnect_Successfully()
    {
        // Arrange & Act
        using var connection = new SqlConnection(_connectionString);
        var exception = await Record.ExceptionAsync(async () => await connection.OpenAsync());

        // Assert
        exception.Should().BeNull("connection string should be valid and database accessible");
        connection.State.Should().Be(System.Data.ConnectionState.Open);
    }

    [Fact]
    public async Task TestTenants_ShouldExist_InDatabase()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand(
            "SELECT COUNT(*) FROM dbo.Tenants WHERE TenantId IN (@TenantA, @TenantB)",
            connection);

        command.Parameters.AddWithValue("@TenantA", _tenantAId);
        command.Parameters.AddWithValue("@TenantB", _tenantBId);

        // Act
        var count = (int)(await command.ExecuteScalarAsync() ?? 0);

        // Assert
        count.Should().Be(2, "both test tenants should exist in database");
    }

    [Fact]
    public async Task GetExtinguishers_ShouldOnlyReturnTenantAData()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
        {
            CommandType = System.Data.CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantAId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var extinguisherTenantIds = new List<Guid>();
        while (await reader.ReadAsync())
        {
            var tenantIdOrdinal = reader.GetOrdinal("TenantId");
            extinguisherTenantIds.Add(reader.GetGuid(tenantIdOrdinal));
        }

        // Assert
        if (extinguisherTenantIds.Any())
        {
            extinguisherTenantIds.Should().AllSatisfy(tenantId =>
                tenantId.Should().Be(_tenantAId, "all extinguishers should belong to Tenant A"));
        }
        // If no extinguishers exist yet, test still passes - we're just verifying no cross-tenant data leaks
    }

    [Fact]
    public async Task GetExtinguishers_ShouldNotReturnTenantBData_WhenQueryingTenantA()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
        {
            CommandType = System.Data.CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantAId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var extinguisherTenantIds = new List<Guid>();
        while (await reader.ReadAsync())
        {
            var tenantIdOrdinal = reader.GetOrdinal("TenantId");
            extinguisherTenantIds.Add(reader.GetGuid(tenantIdOrdinal));
        }

        // Assert
        extinguisherTenantIds.Should().NotContain(_tenantBId,
            "Tenant A query should never return Tenant B's data");
    }

    public void Dispose()
    {
        // Cleanup if needed
        GC.SuppressFinalize(this);
    }
}
