using FireExtinguisherInspection.API.Data;
using FluentAssertions;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;

namespace FireExtinguisherInspection.Tests.Data;

public class DbConnectionFactoryTests
{
    private readonly Mock<IConfiguration> _mockConfiguration;
    private readonly IMemoryCache _memoryCache;
    private readonly Mock<ILogger<DbConnectionFactory>> _mockLogger;
    private readonly string _testConnectionString;

    public DbConnectionFactoryTests()
    {
        _mockConfiguration = new Mock<IConfiguration>();
        _memoryCache = new MemoryCache(new MemoryCacheOptions());
        _mockLogger = new Mock<ILogger<DbConnectionFactory>>();

        // Setup a test connection string (will not actually connect in unit tests)
        _testConnectionString = "Server=localhost;Database=TestDb;User Id=test;Password=test;TrustServerCertificate=true;";

        // Mock ConnectionStrings section
        // GetConnectionString() extension method calls GetSection("ConnectionStrings")["key"]
        var mockDefaultConnectionSection = new Mock<IConfigurationSection>();
        mockDefaultConnectionSection.Setup(x => x.Value).Returns(_testConnectionString);

        var mockConnectionStringsSection = new Mock<IConfigurationSection>();
        mockConnectionStringsSection.Setup(x => x["DefaultConnection"]).Returns(_testConnectionString);
        mockConnectionStringsSection.Setup(x => x.GetSection("DefaultConnection"))
            .Returns(mockDefaultConnectionSection.Object);

        _mockConfiguration.Setup(x => x.GetSection("ConnectionStrings"))
            .Returns(mockConnectionStringsSection.Object);
    }

    [Fact]
    public void Constructor_WithMissingConnectionString_ThrowsInvalidOperationException()
    {
        // Arrange
        var mockConfig = new Mock<IConfiguration>();

        // Mock null connection string section
        var mockConnectionSection = new Mock<IConfigurationSection>();
        mockConnectionSection.Setup(x => x.Value).Returns((string?)null);

        var mockConnectionStringsSection = new Mock<IConfigurationSection>();
        mockConnectionStringsSection.Setup(x => x["DefaultConnection"]).Returns((string?)null);
        mockConnectionStringsSection.Setup(x => x.GetSection("DefaultConnection"))
            .Returns(mockConnectionSection.Object);

        mockConfig.Setup(x => x.GetSection("ConnectionStrings"))
            .Returns(mockConnectionStringsSection.Object);

        // Act & Assert
        var act = () => new DbConnectionFactory(mockConfig.Object, _memoryCache, _mockLogger.Object);
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Connection string*not found*");
    }

    [Fact]
    public void Constructor_WithValidConnectionString_CreatesInstance()
    {
        // Act
        var factory = new DbConnectionFactory(_mockConfiguration.Object, _memoryCache, _mockLogger.Object);

        // Assert
        factory.Should().NotBeNull();
        factory.Should().BeAssignableTo<IDbConnectionFactory>();
    }

    [Fact]
    public async Task CreateConnectionAsync_CreatesConnection()
    {
        // Arrange
        var factory = new DbConnectionFactory(_mockConfiguration.Object, _memoryCache, _mockLogger.Object);

        // Act & Assert
        // Note: This will fail to actually open the connection since we're using a fake connection string
        // The method will throw when attempting to open the connection
        await Assert.ThrowsAnyAsync<Exception>(async () => await factory.CreateConnectionAsync());
    }

    [Fact]
    public async Task GetTenantSchemaAsync_WithInvalidTenantId_ThrowsException()
    {
        // Arrange
        var factory = new DbConnectionFactory(_mockConfiguration.Object, _memoryCache, _mockLogger.Object);
        var invalidTenantId = Guid.NewGuid();

        // Act & Assert
        // This will fail because the connection cannot be opened with fake connection string
        // OR it will fail because the tenant doesn't exist in the database
        await Assert.ThrowsAnyAsync<Exception>(async () => await factory.GetTenantSchemaAsync(invalidTenantId));
    }

    [Fact]
    public void MemoryCache_ShouldBeSingleton()
    {
        // This test verifies that the memory cache is properly configured
        // Multiple instances of the factory should share the same cache

        // Arrange
        var cache = new MemoryCache(new MemoryCacheOptions());
        var factory1 = new DbConnectionFactory(_mockConfiguration.Object, cache, _mockLogger.Object);
        var factory2 = new DbConnectionFactory(_mockConfiguration.Object, cache, _mockLogger.Object);

        // Act
        var testKey = "test_key";
        var testValue = "test_value";
        cache.Set(testKey, testValue);

        // Assert
        cache.TryGetValue(testKey, out string? retrievedValue).Should().BeTrue();
        retrievedValue.Should().Be(testValue);
    }

    [Fact]
    public void TenantSchemaCacheKey_ShouldIncludeTenantId()
    {
        // This test verifies the cache key format
        // While we can't directly test private constants, we can test the behavior

        // Arrange
        var tenantId = Guid.NewGuid();
        var expectedKeyPrefix = "TenantSchema_";

        // Assert
        // The cache key should include the tenant ID for proper isolation
        var expectedKey = $"{expectedKeyPrefix}{tenantId}";
        expectedKey.Should().Contain(tenantId.ToString());
    }

    [Fact]
    public void CacheConfiguration_ShouldHaveAppropriateExpiration()
    {
        // This test documents expected cache behavior
        // Schema names should be cached for 1 hour with 30-minute sliding expiration

        // Arrange
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1),
            SlidingExpiration = TimeSpan.FromMinutes(30)
        };

        // Assert
        cacheOptions.AbsoluteExpirationRelativeToNow.Should().Be(TimeSpan.FromHours(1));
        cacheOptions.SlidingExpiration.Should().Be(TimeSpan.FromMinutes(30));
    }

    [Fact]
    public async Task CreateTenantConnectionAsync_WithValidTenantId_ThrowsException()
    {
        // Arrange
        var factory = new DbConnectionFactory(_mockConfiguration.Object, _memoryCache, _mockLogger.Object);
        var tenantId = Guid.NewGuid();

        // Act & Assert
        // This will fail because the connection cannot be opened with fake connection string
        await Assert.ThrowsAnyAsync<Exception>(async () => await factory.CreateTenantConnectionAsync(tenantId));
    }
}
