using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using FluentAssertions;
using System.Data;

namespace FireExtinguisherInspection.IntegrationTests;

/// <summary>
/// Comprehensive RLS (Row Level Security) integration tests
/// Validates that @TenantId parameter filtering works correctly across all stored procedures
/// </summary>
[Trait("Category", "Integration")]
public class RlsDataIsolationTests : IDisposable
{
    private readonly string _connectionString;
    private readonly Guid _tenantAId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly Guid _tenantBId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    private readonly Guid _locationAId = Guid.Parse("AAA00000-0000-0000-0000-000000000001");
    private readonly Guid _locationBId = Guid.Parse("BBB00000-0000-0000-0000-000000000001");

    public RlsDataIsolationTests()
    {
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("ConnectionStrings__DefaultConnection not set");
    }

    #region Location Tests

    [Fact]
    public async Task LocationGetAll_WithTenantA_ShouldOnlyReturnTenantALocations()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Location_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantAId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var tenantIds = new List<Guid>();
        while (await reader.ReadAsync())
        {
            var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
            tenantIds.Add(tenantId);
        }

        // Assert
        tenantIds.Should().NotBeEmpty("Tenant A should have at least one location");
        tenantIds.Should().AllSatisfy(id =>
            id.Should().Be(_tenantAId, "all locations should belong to Tenant A"));
        tenantIds.Should().NotContain(_tenantBId, "should never return Tenant B's data");
    }

    [Fact]
    public async Task LocationGetAll_WithTenantB_ShouldOnlyReturnTenantBLocations()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Location_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantBId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var tenantIds = new List<Guid>();
        while (await reader.ReadAsync())
        {
            var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
            tenantIds.Add(tenantId);
        }

        // Assert
        tenantIds.Should().NotBeEmpty("Tenant B should have at least one location");
        tenantIds.Should().AllSatisfy(id =>
            id.Should().Be(_tenantBId, "all locations should belong to Tenant B"));
        tenantIds.Should().NotContain(_tenantAId, "should never return Tenant A's data");
    }

    [Fact]
    public async Task LocationGetById_WithWrongTenantId_ShouldReturnNoResults()
    {
        // Arrange - Try to get Tenant A's location using Tenant B's credentials
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Location_GetById", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@LocationId", _locationAId);
        command.Parameters.AddWithValue("@TenantId", _tenantBId); // Wrong tenant!

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var hasRows = await reader.ReadAsync();

        // Assert
        hasRows.Should().BeFalse("Tenant B should not be able to access Tenant A's location");
    }

    [Fact]
    public async Task LocationGetById_WithCorrectTenantId_ShouldReturnLocation()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Location_GetById", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@LocationId", _locationAId);
        command.Parameters.AddWithValue("@TenantId", _tenantAId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var hasRows = await reader.ReadAsync();

        // Assert
        hasRows.Should().BeTrue("Tenant A should be able to access its own location");
        if (hasRows)
        {
            var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
            tenantId.Should().Be(_tenantAId);
        }
    }

    #endregion

    #region Extinguisher Tests

    [Fact]
    public async Task ExtinguisherGetAll_WithTenantA_ShouldOnlyReturnTenantAExtinguishers()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantAId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var tenantIds = new List<Guid>();
        var assetTags = new List<string>();
        while (await reader.ReadAsync())
        {
            var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
            var assetTag = reader.GetString(reader.GetOrdinal("AssetTag"));
            tenantIds.Add(tenantId);
            assetTags.Add(assetTag);
        }

        // Assert
        tenantIds.Should().NotBeEmpty("Tenant A should have extinguishers");
        tenantIds.Should().AllSatisfy(id =>
            id.Should().Be(_tenantAId, "all extinguishers should belong to Tenant A"));
        assetTags.Should().AllSatisfy(tag =>
            tag.Should().StartWith("CI-EXT-A-", "Tenant A asset tags should have A prefix"));
    }

    [Fact]
    public async Task ExtinguisherGetAll_WithTenantB_ShouldOnlyReturnTenantBExtinguishers()
    {
        // Arrange
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", _tenantBId);

        // Act
        using var reader = await command.ExecuteReaderAsync();
        var tenantIds = new List<Guid>();
        var assetTags = new List<string>();
        while (await reader.ReadAsync())
        {
            var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
            var assetTag = reader.GetString(reader.GetOrdinal("AssetTag"));
            tenantIds.Add(tenantId);
            assetTags.Add(assetTag);
        }

        // Assert
        tenantIds.Should().NotBeEmpty("Tenant B should have extinguishers");
        tenantIds.Should().AllSatisfy(id =>
            id.Should().Be(_tenantBId, "all extinguishers should belong to Tenant B"));
        assetTags.Should().AllSatisfy(tag =>
            tag.Should().StartWith("CI-EXT-B-", "Tenant B asset tags should have B prefix"));
    }

    [Fact]
    public async Task ExtinguisherGetById_WithWrongTenantId_ShouldReturnNoResults()
    {
        // Arrange - First get a Tenant A extinguisher ID
        Guid? extinguisherAId = null;
        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            using var getCommand = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            getCommand.Parameters.AddWithValue("@TenantId", _tenantAId);
            using var reader = await getCommand.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                extinguisherAId = reader.GetGuid(reader.GetOrdinal("ExtinguisherId"));
            }
        }

        extinguisherAId.Should().NotBeNull("Tenant A should have at least one extinguisher");

        // Act - Try to get Tenant A's extinguisher using Tenant B credentials
        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            using var command = new SqlCommand("dbo.usp_Extinguisher_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@ExtinguisherId", extinguisherAId!.Value);
            command.Parameters.AddWithValue("@TenantId", _tenantBId); // Wrong tenant!

            using var reader = await command.ExecuteReaderAsync();
            var hasRows = await reader.ReadAsync();

            // Assert
            hasRows.Should().BeFalse("Tenant B should not access Tenant A's extinguisher");
        }
    }

    [Fact]
    public async Task ExtinguisherGetById_WithCorrectTenantId_ShouldReturnExtinguisher()
    {
        // Arrange - Get a Tenant B extinguisher ID
        Guid? extinguisherBId = null;
        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            using var getCommand = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            getCommand.Parameters.AddWithValue("@TenantId", _tenantBId);
            using var reader = await getCommand.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                extinguisherBId = reader.GetGuid(reader.GetOrdinal("ExtinguisherId"));
            }
        }

        extinguisherBId.Should().NotBeNull("Tenant B should have at least one extinguisher");

        // Act - Get Tenant B's extinguisher with correct credentials
        using (var connection = new SqlConnection(_connectionString))
        {
            await connection.OpenAsync();
            using var command = new SqlCommand("dbo.usp_Extinguisher_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@ExtinguisherId", extinguisherBId!.Value);
            command.Parameters.AddWithValue("@TenantId", _tenantBId);

            using var reader = await command.ExecuteReaderAsync();
            var hasRows = await reader.ReadAsync();

            // Assert
            hasRows.Should().BeTrue("Tenant B should access its own extinguisher");
            if (hasRows)
            {
                var tenantId = reader.GetGuid(reader.GetOrdinal("TenantId"));
                tenantId.Should().Be(_tenantBId);
            }
        }
    }

    #endregion

    #region Cross-Tenant Data Verification

    [Fact]
    public async Task VerifyCompleteDataIsolation_BetweenTenants()
    {
        // This test verifies that there is ZERO overlap in data between tenants

        // Get all Tenant A data
        var tenantALocationIds = await GetLocationIdsForTenant(_tenantAId);
        var tenantAExtinguisherIds = await GetExtinguisherIdsForTenant(_tenantAId);

        // Get all Tenant B data
        var tenantBLocationIds = await GetLocationIdsForTenant(_tenantBId);
        var tenantBExtinguisherIds = await GetExtinguisherIdsForTenant(_tenantBId);

        // Assert - No overlapping data
        tenantALocationIds.Should().NotIntersectWith(tenantBLocationIds,
            "Tenant A and B should have completely separate locations");
        tenantAExtinguisherIds.Should().NotIntersectWith(tenantBExtinguisherIds,
            "Tenant A and B should have completely separate extinguishers");

        // Assert - Each tenant has data
        tenantALocationIds.Should().NotBeEmpty("Tenant A should have locations");
        tenantAExtinguisherIds.Should().NotBeEmpty("Tenant A should have extinguishers");
        tenantBLocationIds.Should().NotBeEmpty("Tenant B should have locations");
        tenantBExtinguisherIds.Should().NotBeEmpty("Tenant B should have extinguishers");
    }

    [Fact]
    public async Task VerifyTestDataIntegrity()
    {
        // Verify the test data setup is correct
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        // Check Tenant A has expected asset tags
        using (var command = new SqlCommand(
            "SELECT AssetTag FROM dbo.Extinguishers WHERE TenantId = @TenantId ORDER BY AssetTag",
            connection))
        {
            command.Parameters.AddWithValue("@TenantId", _tenantAId);
            using var reader = await command.ExecuteReaderAsync();
            var assetTags = new List<string>();
            while (await reader.ReadAsync())
            {
                assetTags.Add(reader.GetString(0));
            }

            assetTags.Should().Contain("CI-EXT-A-001", "test data should include this asset");
            assetTags.Should().Contain("CI-EXT-A-002", "test data should include this asset");
        }

        // Check Tenant B has expected asset tags
        using (var command = new SqlCommand(
            "SELECT AssetTag FROM dbo.Extinguishers WHERE TenantId = @TenantId ORDER BY AssetTag",
            connection))
        {
            command.Parameters.AddWithValue("@TenantId", _tenantBId);
            using var reader = await command.ExecuteReaderAsync();
            var assetTags = new List<string>();
            while (await reader.ReadAsync())
            {
                assetTags.Add(reader.GetString(0));
            }

            assetTags.Should().Contain("CI-EXT-B-001", "test data should include this asset");
            assetTags.Should().Contain("CI-EXT-B-002", "test data should include this asset");
        }
    }

    #endregion

    #region Helper Methods

    private async Task<List<Guid>> GetLocationIdsForTenant(Guid tenantId)
    {
        var locationIds = new List<Guid>();
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Location_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            locationIds.Add(reader.GetGuid(reader.GetOrdinal("LocationId")));
        }

        return locationIds;
    }

    private async Task<List<Guid>> GetExtinguisherIdsForTenant(Guid tenantId)
    {
        var extinguisherIds = new List<Guid>();
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();

        using var command = new SqlCommand("dbo.usp_Extinguisher_GetAll", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@TenantId", tenantId);

        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            extinguisherIds.Add(reader.GetGuid(reader.GetOrdinal("ExtinguisherId")));
        }

        return extinguisherIds;
    }

    #endregion

    public void Dispose()
    {
        GC.SuppressFinalize(this);
    }
}
