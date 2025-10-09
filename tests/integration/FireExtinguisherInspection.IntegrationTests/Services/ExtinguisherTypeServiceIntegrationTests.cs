using FireExtinguisherInspection.API.Data;
using FireExtinguisherInspection.API.Models.DTOs;
using FireExtinguisherInspection.API.Services;
using FluentAssertions;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace FireExtinguisherInspection.IntegrationTests.Services;

/// <summary>
/// Integration tests for ExtinguisherTypeService that test against real database
/// </summary>
[Collection("Database")]
public class ExtinguisherTypeServiceIntegrationTests : IAsyncLifetime
{
    private readonly IConfiguration _configuration;
    private readonly IDbConnectionFactory _connectionFactory;
    private readonly IExtinguisherTypeService _service;
    private readonly Guid _testTenantId;
    private readonly string _testSchemaName;

    public ExtinguisherTypeServiceIntegrationTests()
    {
        _configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.test.json")
            .AddEnvironmentVariables()
            .Build();

        _connectionFactory = new DbConnectionFactory(_configuration);
        _service = new ExtinguisherTypeService(_connectionFactory);

        _testTenantId = Guid.NewGuid();
        _testSchemaName = $"tenant_{_testTenantId:N}";
    }

    public async Task InitializeAsync()
    {
        // Create test tenant schema
        await CreateTestTenantSchemaAsync();
    }

    public async Task DisposeAsync()
    {
        // Clean up test tenant schema
        await DropTestTenantSchemaAsync();
    }

    #region Create Tests

    [Fact]
    public async Task CreateExtinguisherTypeAsync_WithValidData_CreatesTypeSuccessfully()
    {
        // Arrange
        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = "ABC-10-TEST",
            TypeName = "10lb ABC Test Type",
            Description = "Test extinguisher type",
            AgentType = "Dry Chemical",
            Capacity = 10,
            CapacityUnit = "lbs",
            FireClassRating = "A:B:C",
            ServiceLifeYears = 12,
            HydroTestIntervalYears = 12
        };

        // Act
        var result = await _service.CreateExtinguisherTypeAsync(_testTenantId, request);

        // Assert
        result.Should().NotBeNull();
        result.ExtinguisherTypeId.Should().NotBeEmpty();
        result.TenantId.Should().Be(_testTenantId);
        result.TypeCode.Should().Be(request.TypeCode);
        result.TypeName.Should().Be(request.TypeName);
        result.Description.Should().Be(request.Description);
        result.AgentType.Should().Be(request.AgentType);
        result.Capacity.Should().Be(request.Capacity);
        result.CapacityUnit.Should().Be(request.CapacityUnit);
        result.FireClassRating.Should().Be(request.FireClassRating);
        result.ServiceLifeYears.Should().Be(request.ServiceLifeYears);
        result.HydroTestIntervalYears.Should().Be(request.HydroTestIntervalYears);
        result.IsActive.Should().BeTrue();
        result.CreatedDate.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public async Task CreateExtinguisherTypeAsync_WithDuplicateTypeCode_ThrowsException()
    {
        // Arrange
        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = "DUPLICATE-TEST",
            TypeName = "Duplicate Test Type"
        };

        // Create first type
        await _service.CreateExtinguisherTypeAsync(_testTenantId, request);

        // Act & Assert
        await Assert.ThrowsAsync<SqlException>(async () =>
            await _service.CreateExtinguisherTypeAsync(_testTenantId, request));
    }

    #endregion

    #region Read Tests

    [Fact]
    public async Task GetAllExtinguisherTypesAsync_WithNoFilter_ReturnsAllTypes()
    {
        // Arrange
        await CreateTestTypesAsync();

        // Act
        var results = await _service.GetAllExtinguisherTypesAsync(_testTenantId, null);

        // Assert
        var typesList = results.ToList();
        typesList.Should().HaveCount(3);
        typesList.Should().Contain(t => t.TypeCode == "TEST-ABC-10");
        typesList.Should().Contain(t => t.TypeCode == "TEST-CO2-15");
        typesList.Should().Contain(t => t.TypeCode == "TEST-WATER-5");
    }

    [Fact]
    public async Task GetAllExtinguisherTypesAsync_WithActiveFilter_ReturnsOnlyActiveTypes()
    {
        // Arrange
        await CreateTestTypesAsync();

        // Deactivate one type
        var types = await _service.GetAllExtinguisherTypesAsync(_testTenantId, null);
        var typeToDeactivate = types.First(t => t.TypeCode == "TEST-WATER-5");
        await _service.UpdateExtinguisherTypeAsync(_testTenantId, typeToDeactivate.ExtinguisherTypeId,
            new UpdateExtinguisherTypeRequest
            {
                TypeName = typeToDeactivate.TypeName,
                IsActive = false
            });

        // Act
        var results = await _service.GetAllExtinguisherTypesAsync(_testTenantId, isActive: true);

        // Assert
        var typesList = results.ToList();
        typesList.Should().HaveCount(2);
        typesList.Should().NotContain(t => t.TypeCode == "TEST-WATER-5");
    }

    [Fact]
    public async Task GetExtinguisherTypeByIdAsync_WithExistingId_ReturnsType()
    {
        // Arrange
        var created = await CreateSingleTestTypeAsync();

        // Act
        var result = await _service.GetExtinguisherTypeByIdAsync(_testTenantId, created.ExtinguisherTypeId);

        // Assert
        result.Should().NotBeNull();
        result!.ExtinguisherTypeId.Should().Be(created.ExtinguisherTypeId);
        result.TypeCode.Should().Be(created.TypeCode);
    }

    [Fact]
    public async Task GetExtinguisherTypeByIdAsync_WithNonExistentId_ReturnsNull()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var result = await _service.GetExtinguisherTypeByIdAsync(_testTenantId, nonExistentId);

        // Assert
        result.Should().BeNull();
    }

    #endregion

    #region Update Tests

    [Fact]
    public async Task UpdateExtinguisherTypeAsync_WithValidData_UpdatesSuccessfully()
    {
        // Arrange
        var created = await CreateSingleTestTypeAsync();
        var updateRequest = new UpdateExtinguisherTypeRequest
        {
            TypeName = "Updated Type Name",
            Description = "Updated description",
            AgentType = "CO2",
            Capacity = 15,
            CapacityUnit = "lbs",
            FireClassRating = "B:C",
            ServiceLifeYears = 15,
            HydroTestIntervalYears = 10,
            IsActive = true
        };

        // Act
        var result = await _service.UpdateExtinguisherTypeAsync(_testTenantId, created.ExtinguisherTypeId, updateRequest);

        // Assert
        result.Should().NotBeNull();
        result.ExtinguisherTypeId.Should().Be(created.ExtinguisherTypeId);
        result.TypeCode.Should().Be(created.TypeCode); // TypeCode should not change
        result.TypeName.Should().Be(updateRequest.TypeName);
        result.Description.Should().Be(updateRequest.Description);
        result.AgentType.Should().Be(updateRequest.AgentType);
        result.Capacity.Should().Be(updateRequest.Capacity);
        result.ModifiedDate.Should().BeAfter(created.CreatedDate);
    }

    [Fact]
    public async Task UpdateExtinguisherTypeAsync_WithNonExistentId_ThrowsKeyNotFoundException()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();
        var updateRequest = new UpdateExtinguisherTypeRequest
        {
            TypeName = "Test",
            IsActive = true
        };

        // Act & Assert
        await Assert.ThrowsAsync<KeyNotFoundException>(async () =>
            await _service.UpdateExtinguisherTypeAsync(_testTenantId, nonExistentId, updateRequest));
    }

    #endregion

    #region Delete Tests

    [Fact]
    public async Task DeleteExtinguisherTypeAsync_WithExistingId_DeletesSuccessfully()
    {
        // Arrange
        var created = await CreateSingleTestTypeAsync();

        // Act
        var result = await _service.DeleteExtinguisherTypeAsync(_testTenantId, created.ExtinguisherTypeId);

        // Assert
        result.Should().BeTrue();

        // Verify type no longer exists
        var deleted = await _service.GetExtinguisherTypeByIdAsync(_testTenantId, created.ExtinguisherTypeId);
        deleted.Should().BeNull();
    }

    [Fact]
    public async Task DeleteExtinguisherTypeAsync_WithNonExistentId_ReturnsFalse()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var result = await _service.DeleteExtinguisherTypeAsync(_testTenantId, nonExistentId);

        // Assert
        result.Should().BeFalse();
    }

    #endregion

    #region Helper Methods

    private async Task CreateTestTenantSchemaAsync()
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        // Create schema
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $"CREATE SCHEMA [{_testSchemaName}]";
            await command.ExecuteNonQueryAsync();
        }

        // Create ExtinguisherTypes table
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE TABLE [{_testSchemaName}].[ExtinguisherTypes] (
                    ExtinguisherTypeId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
                    TenantId UNIQUEIDENTIFIER NOT NULL,
                    TypeCode NVARCHAR(50) NOT NULL,
                    TypeName NVARCHAR(200) NOT NULL,
                    Description NVARCHAR(MAX),
                    AgentType NVARCHAR(100),
                    Capacity DECIMAL(10,2),
                    CapacityUnit NVARCHAR(20),
                    FireClassRating NVARCHAR(50),
                    ServiceLifeYears INT,
                    HydroTestIntervalYears INT,
                    IsActive BIT NOT NULL DEFAULT 1,
                    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
                    CONSTRAINT UQ_ExtinguisherType_TypeCode UNIQUE (TenantId, TypeCode)
                )";
            await command.ExecuteNonQueryAsync();
        }

        // Create stored procedures
        await CreateStoredProceduresAsync(connection);

        // Register tenant in TenantRegistry
        using (var command = connection.CreateCommand())
        {
            command.CommandText = @"
                INSERT INTO common.TenantRegistry (TenantId, TenantCode, DatabaseSchema, IsActive)
                VALUES (@TenantId, @TenantCode, @DatabaseSchema, 1)";
            command.Parameters.AddWithValue("@TenantId", _testTenantId);
            command.Parameters.AddWithValue("@TenantCode", $"TEST_{_testTenantId:N}");
            command.Parameters.AddWithValue("@DatabaseSchema", _testSchemaName);
            await command.ExecuteNonQueryAsync();
        }
    }

    private async Task CreateStoredProceduresAsync(SqlConnection connection)
    {
        // Create procedure
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE PROCEDURE [{_testSchemaName}].[usp_ExtinguisherType_Create]
                    @TypeCode NVARCHAR(50),
                    @TypeName NVARCHAR(200),
                    @Description NVARCHAR(MAX) = NULL,
                    @AgentType NVARCHAR(100) = NULL,
                    @Capacity DECIMAL(10,2) = NULL,
                    @CapacityUnit NVARCHAR(20) = NULL,
                    @FireClassRating NVARCHAR(50) = NULL,
                    @ServiceLifeYears INT = NULL,
                    @HydroTestIntervalYears INT = NULL,
                    @TenantId UNIQUEIDENTIFIER
                AS
                BEGIN
                    INSERT INTO [{_testSchemaName}].[ExtinguisherTypes] (
                        TenantId, TypeCode, TypeName, Description, AgentType, Capacity,
                        CapacityUnit, FireClassRating, ServiceLifeYears, HydroTestIntervalYears
                    )
                    OUTPUT INSERTED.*
                    VALUES (
                        @TenantId, @TypeCode, @TypeName, @Description, @AgentType, @Capacity,
                        @CapacityUnit, @FireClassRating, @ServiceLifeYears, @HydroTestIntervalYears
                    )
                END";
            await command.ExecuteNonQueryAsync();
        }

        // GetAll procedure
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE PROCEDURE [{_testSchemaName}].[usp_ExtinguisherType_GetAll]
                    @TenantId UNIQUEIDENTIFIER,
                    @IsActive BIT = NULL
                AS
                BEGIN
                    SELECT * FROM [{_testSchemaName}].[ExtinguisherTypes]
                    WHERE TenantId = @TenantId
                        AND (@IsActive IS NULL OR IsActive = @IsActive)
                    ORDER BY TypeCode
                END";
            await command.ExecuteNonQueryAsync();
        }

        // GetById procedure
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE PROCEDURE [{_testSchemaName}].[usp_ExtinguisherType_GetById]
                    @TenantId UNIQUEIDENTIFIER,
                    @ExtinguisherTypeId UNIQUEIDENTIFIER
                AS
                BEGIN
                    SELECT * FROM [{_testSchemaName}].[ExtinguisherTypes]
                    WHERE TenantId = @TenantId AND ExtinguisherTypeId = @ExtinguisherTypeId
                END";
            await command.ExecuteNonQueryAsync();
        }

        // Update procedure
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE PROCEDURE [{_testSchemaName}].[usp_ExtinguisherType_Update]
                    @ExtinguisherTypeId UNIQUEIDENTIFIER,
                    @TenantId UNIQUEIDENTIFIER,
                    @TypeName NVARCHAR(200),
                    @Description NVARCHAR(MAX) = NULL,
                    @AgentType NVARCHAR(100) = NULL,
                    @Capacity DECIMAL(10,2) = NULL,
                    @CapacityUnit NVARCHAR(20) = NULL,
                    @FireClassRating NVARCHAR(50) = NULL,
                    @ServiceLifeYears INT = NULL,
                    @HydroTestIntervalYears INT = NULL,
                    @IsActive BIT
                AS
                BEGIN
                    UPDATE [{_testSchemaName}].[ExtinguisherTypes]
                    SET TypeName = @TypeName,
                        Description = @Description,
                        AgentType = @AgentType,
                        Capacity = @Capacity,
                        CapacityUnit = @CapacityUnit,
                        FireClassRating = @FireClassRating,
                        ServiceLifeYears = @ServiceLifeYears,
                        HydroTestIntervalYears = @HydroTestIntervalYears,
                        IsActive = @IsActive,
                        ModifiedDate = GETUTCDATE()
                    OUTPUT INSERTED.*
                    WHERE ExtinguisherTypeId = @ExtinguisherTypeId AND TenantId = @TenantId
                END";
            await command.ExecuteNonQueryAsync();
        }

        // Delete procedure
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                CREATE PROCEDURE [{_testSchemaName}].[usp_ExtinguisherType_Delete]
                    @ExtinguisherTypeId UNIQUEIDENTIFIER,
                    @TenantId UNIQUEIDENTIFIER
                AS
                BEGIN
                    DELETE FROM [{_testSchemaName}].[ExtinguisherTypes]
                    WHERE ExtinguisherTypeId = @ExtinguisherTypeId AND TenantId = @TenantId
                END";
            await command.ExecuteNonQueryAsync();
        }
    }

    private async Task DropTestTenantSchemaAsync()
    {
        var connectionString = _configuration.GetConnectionString("DefaultConnection");
        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        // Delete from TenantRegistry
        using (var command = connection.CreateCommand())
        {
            command.CommandText = "DELETE FROM common.TenantRegistry WHERE TenantId = @TenantId";
            command.Parameters.AddWithValue("@TenantId", _testTenantId);
            await command.ExecuteNonQueryAsync();
        }

        // Drop schema and all objects
        using (var command = connection.CreateCommand())
        {
            command.CommandText = $@"
                DROP TABLE IF EXISTS [{_testSchemaName}].[ExtinguisherTypes];
                DROP PROCEDURE IF EXISTS [{_testSchemaName}].[usp_ExtinguisherType_Create];
                DROP PROCEDURE IF EXISTS [{_testSchemaName}].[usp_ExtinguisherType_GetAll];
                DROP PROCEDURE IF EXISTS [{_testSchemaName}].[usp_ExtinguisherType_GetById];
                DROP PROCEDURE IF EXISTS [{_testSchemaName}].[usp_ExtinguisherType_Update];
                DROP PROCEDURE IF EXISTS [{_testSchemaName}].[usp_ExtinguisherType_Delete];
                DROP SCHEMA IF EXISTS [{_testSchemaName}];";
            await command.ExecuteNonQueryAsync();
        }
    }

    private async Task<ExtinguisherTypeDto> CreateSingleTestTypeAsync()
    {
        var request = new CreateExtinguisherTypeRequest
        {
            TypeCode = $"TEST-SINGLE-{Guid.NewGuid():N}",
            TypeName = "Single Test Type",
            Description = "Test type for single operations",
            AgentType = "Dry Chemical",
            Capacity = 10,
            CapacityUnit = "lbs",
            FireClassRating = "A:B:C"
        };

        return await _service.CreateExtinguisherTypeAsync(_testTenantId, request);
    }

    private async Task CreateTestTypesAsync()
    {
        var types = new[]
        {
            new CreateExtinguisherTypeRequest
            {
                TypeCode = "TEST-ABC-10",
                TypeName = "10lb ABC Dry Chemical",
                AgentType = "Dry Chemical",
                Capacity = 10,
                CapacityUnit = "lbs",
                FireClassRating = "A:B:C"
            },
            new CreateExtinguisherTypeRequest
            {
                TypeCode = "TEST-CO2-15",
                TypeName = "15lb CO2",
                AgentType = "CO2",
                Capacity = 15,
                CapacityUnit = "lbs",
                FireClassRating = "B:C"
            },
            new CreateExtinguisherTypeRequest
            {
                TypeCode = "TEST-WATER-5",
                TypeName = "5 Gallon Water",
                AgentType = "Water",
                Capacity = 5,
                CapacityUnit = "gal",
                FireClassRating = "A"
            }
        };

        foreach (var type in types)
        {
            await _service.CreateExtinguisherTypeAsync(_testTenantId, type);
        }
    }

    #endregion
}
