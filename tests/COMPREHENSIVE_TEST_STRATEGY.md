# Comprehensive Test Strategy for FireProof Data Flows

**Date**: 2025-10-17
**Status**: Test Infrastructure Planning
**Purpose**: Ensure RLS migration data flows are working correctly

## Executive Summary

This document outlines the testing strategy to verify that data flows correctly through the backend services after the RLS (Row Level Security) migration. The migration changed from tenant-specific schemas to a single `dbo` schema with `@TenantId` parameters.

## Critical Data Flow Requirements

### 1. RLS Pattern Verification

All services must:
- Use `CreateConnectionAsync()` NOT `CreateTenantConnectionAsync()`
- Call stored procedures in `dbo` schema (e.g., `dbo.usp_Extinguisher_GetAll`)
- Pass `@TenantId` parameter to ALL stored procedures
- Never access tenant-specific schemas

### 2. Services Requiring Test Coverage

#### High Priority (Recently Updated)
1. **ChecklistTemplateService** - Custom and system templates
2. **DeficiencyService** - Inspection deficiencies
3. **AzureBlobPhotoService** - Photo storage and retrieval

#### Medium Priority (Already RLS-compliant)
4. **ExtinguisherService** - Fire extinguisher CRUD
5. **LocationService** - Location management
6. **InspectionService** - Inspection operations

#### Low Priority
7. **TenantService** - Tenant management (single-row operations)
8. **AuthenticationService** - User authentication (no multi-tenant data)

## Test Pyramid Structure

```
        /\
       /  \  E2E Tests (Playwright)
      /____\  - Full user workflows
     /      \  - Multi-tenant isolation
    /________\ Integration Tests
   /          \ - Database tests
  /____________\ - SP execution tests
 /              \ Unit Tests
/________________\ - Parameter validation
                   - Connection management
                   - Logging verification
```

## Unit Test Requirements

### Test Categories

#### 1. Connection Management Tests
**Purpose**: Verify correct connection factory usage

**Test Pattern**:
```csharp
[Fact]
public async Task ServiceMethod_ShouldUseStandardConnection_NotTenantConnection()
{
    // Arrange
    var mockConnectionFactory = new Mock<IDbConnectionFactory>();
    var mockConnection = new Mock<IDbConnection>();

    mockConnectionFactory
        .Setup(x => x.CreateConnectionAsync())
        .ReturnsAsync(mockConnection.Object);

    var service = new Service(mockConnectionFactory.Object, ...);

    // Act
    try { await service.MethodAsync(tenantId, ...); } catch {}

    // Assert
    mockConnectionFactory.Verify(x => x.CreateConnectionAsync(), Times.Once);
    mockConnectionFactory.Verify(
        x => x.CreateTenantConnectionAsync(It.IsAny<Guid>()),
        Times.Never,
        "RLS pattern uses standard connection with @TenantId");
}
```

**Coverage**:
- ✅ All CRUD operations use `CreateConnectionAsync()`
- ✅ No calls to `CreateTenantConnectionAsync()`
- ✅ Connection is properly disposed

#### 2. Parameter Passing Tests
**Purpose**: Verify @TenantId is always passed

**Test Pattern**:
```csharp
[Fact]
public async Task ServiceMethod_ShouldPassTenantIdParameter()
{
    // This test requires SqlCommand mocking which is complex
    // Instead, use integration tests with actual database

    // Verify in integration test:
    // 1. Call service method with specific tenantId
    // 2. Verify only that tenant's data is returned
    // 3. Verify other tenants' data is NOT returned
}
```

**Coverage**:
- ✅ @TenantId parameter is included in all SP calls
- ✅ Correct tenantId value is passed
- ✅ Data isolation is enforced

#### 3. Logging Tests
**Purpose**: Verify audit trail and debugging info

**Test Pattern**:
```csharp
[Fact]
public async Task CreateMethod_ShouldLogInformationWithTenantContext()
{
    // Arrange
    var mockLogger = new Mock<ILogger<Service>>();
    var service = new Service(..., mockLogger.Object);

    // Act
    try { await service.CreateAsync(tenantId, request); } catch {}

    // Assert
    mockLogger.Verify(
        x => x.Log(
            LogLevel.Information,
            It.IsAny<EventId>(),
            It.Is<It.IsAnyType>((v, t) =>
                v.ToString()!.Contains("Creating") &&
                v.ToString()!.Contains(tenantId.ToString())),
            It.IsAny<Exception>(),
            It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
        Times.AtLeastOnce);
}
```

**Coverage**:
- ✅ Information logged for creates/updates/deletes
- ✅ TenantId included in log messages
- ✅ Debug logging for reads
- ✅ Error logging for exceptions

#### 4. DTO Validation Tests
**Purpose**: Verify data structures match database schema

**Test Pattern**:
```csharp
[Fact]
public void ExtinguisherDto_ShouldIncludeTenantIdForRLS()
{
    // Arrange & Act
    var dto = new ExtinguisherDto
    {
        ExtinguisherId = Guid.NewGuid(),
        TenantId = testTenantId,  // Required for RLS
        LocationId = Guid.NewGuid(),
        AssetTag = "EXT-001",
        SerialNumber = "SN123456",
        IsActive = true,
        CreatedDate = DateTime.UtcNow,
        ModifiedDate = DateTime.UtcNow
    };

    // Assert
    dto.ExtinguisherId.Should().NotBe(Guid.Empty);
    dto.TenantId.Should().NotBe(Guid.Empty, "TenantId required for RLS");
    dto.AssetTag.Should().NotBeNullOrEmpty();
}
```

**Coverage**:
- ✅ All DTOs have TenantId property
- ✅ Required fields are enforced
- ✅ Optional fields allow null
- ✅ Types match database columns

## Integration Test Requirements

### Database Integration Tests

#### Test Setup
```sql
-- Create test tenants
INSERT INTO dbo.Tenants (TenantId, CompanyName, IsActive)
VALUES
    ('TENANT-A-GUID', 'Test Tenant A', 1),
    ('TENANT-B-GUID', 'Test Tenant B', 1);

-- Create test data for Tenant A
EXEC dbo.usp_Extinguisher_Create
    @TenantId = 'TENANT-A-GUID',
    @LocationId = @LocationId,
    @AssetTag = 'A-EXT-001',
    ...;

-- Create test data for Tenant B
EXEC dbo.usp_Extinguisher_Create
    @TenantId = 'TENANT-B-GUID',
    @LocationId = @LocationId,
    @AssetTag = 'B-EXT-001',
    ...;
```

#### Critical Tests

**1. Data Isolation Test**
```csharp
[Fact]
public async Task GetAllExtinguishers_ShouldOnlyReturnTenantAData()
{
    // Arrange
    var tenantA = Guid.Parse("TENANT-A-GUID");
    var tenantB = Guid.Parse("TENANT-B-GUID");

    // Act
    var resultA = await _extinguisherService.GetAllExtinguishersAsync(tenantA);
    var resultB = await _extinguisherService.GetAllExtinguishersAsync(tenantB);

    // Assert
    resultA.Should().NotBeEmpty();
    resultA.Should().AllSatisfy(e => e.TenantId.Should().Be(tenantA));
    resultA.Should().NotContain(e => e.AssetTag.StartsWith("B-"));

    resultB.Should().NotBeEmpty();
    resultB.Should().AllSatisfy(e => e.TenantId.Should().Be(tenantB));
    resultB.Should().NotContain(e => e.AssetTag.StartsWith("A-"));
}
```

**2. Cross-Tenant Access Prevention**
```csharp
[Fact]
public async Task GetExtinguisherById_ShouldReturnNull_ForOtherTenant()
{
    // Arrange
    var tenantA = Guid.Parse("TENANT-A-GUID");
    var tenantB = Guid.Parse("TENANT-B-GUID");
    var extinguisherA = await CreateTestExtinguisher(tenantA);

    // Act - Try to access Tenant A's data using Tenant B's context
    var result = await _extinguisherService.GetExtinguisherByIdAsync(
        tenantB,
        extinguisherA.ExtinguisherId);

    // Assert
    result.Should().BeNull("Tenant B should not access Tenant A's data");
}
```

**3. Stored Procedure Execution Test**
```csharp
[Fact]
public async Task CreateExtinguisher_ShouldCallCorrectStoredProcedure()
{
    // Arrange
    var request = new CreateExtinguisherRequest { ... };

    // Act
    var result = await _extinguisherService.CreateExtinguisherAsync(tenantId, request);

    // Assert
    result.Should().NotBeNull();
    result.ExtinguisherId.Should().NotBe(Guid.Empty);
    result.TenantId.Should().Be(tenantId);

    // Verify it was inserted correctly
    var fetched = await _extinguisherService.GetExtinguisherByIdAsync(
        tenantId,
        result.ExtinguisherId);

    fetched.Should().NotBeNull();
    fetched!.AssetTag.Should().Be(request.AssetTag);
}
```

## E2E Test Requirements

### Playwright Tests

#### Multi-Tenant Workflow Test
```javascript
test('inspections should be isolated per tenant', async ({ page }) => {
  // Login as Tenant A user
  await loginAs(page, 'tenanta@test.com', 'password');
  await selectTenant(page, 'Tenant A');

  // Create inspection for Tenant A
  await page.goto('/inspections/create');
  const inspectionA = await createInspection(page, {
    extinguisher: 'EXT-A-001',
    type: 'Monthly'
  });

  // Logout and login as Tenant B user
  await logout(page);
  await loginAs(page, 'tenantb@test.com', 'password');
  await selectTenant(page, 'Tenant B');

  // Verify Tenant A's inspection is NOT visible
  await page.goto('/inspections');
  const inspectionList = await page.locator('[data-testid="inspections-table"]');
  await expect(inspectionList).not.toContainText(inspectionA.id);
  await expect(inspectionList).not.toContainText('EXT-A-001');
});
```

## Test Data Management

### Test Data Strategy

**1. Seed Data**
```sql
-- scripts/seed-test-data.sql
-- Create consistent test data for automated tests

-- Test Tenants
INSERT INTO dbo.Tenants (TenantId, CompanyName, SubscriptionLevel, IsActive)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Automated Test Tenant A', 'Professional', 1),
    ('22222222-2222-2222-2222-222222222222', 'Automated Test Tenant B', 'Professional', 1);

-- Test Users
INSERT INTO dbo.Users (UserId, Email, PasswordHash, FirstName, LastName, IsActive)
VALUES
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'test-a@fireproof.test', 'hash', 'Test', 'User A', 1),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', 'test-b@fireproof.test', 'hash', 'Test', 'User B', 1);

-- Test Locations
EXEC dbo.usp_Location_Create
    @TenantId = '11111111-1111-1111-1111-111111111111',
    @LocationCode = 'TEST-LOC-A',
    @LocationName = 'Test Location A',
    ...;
```

**2. Test Cleanup**
```sql
-- After tests, clean up test data
DELETE FROM dbo.InspectionDeficiencies WHERE TenantId IN ('111...', '222...');
DELETE FROM dbo.Inspections WHERE TenantId IN ('111...', '222...');
DELETE FROM dbo.Extinguishers WHERE TenantId IN ('111...', '222...');
DELETE FROM dbo.Locations WHERE TenantId IN ('111...', '222...');
DELETE FROM dbo.UserTenantRoles WHERE TenantId IN ('111...', '222...');
DELETE FROM dbo.Users WHERE UserId IN ('AAA...', 'BBB...');
DELETE FROM dbo.Tenants WHERE TenantId IN ('111...', '222...');
```

## Test Execution Strategy

### Local Development
```bash
# Run unit tests
cd tests/unit/FireExtinguisherInspection.Tests
dotnet test

# Run integration tests (requires test database)
cd tests/integration/FireExtinguisherInspection.IntegrationTests
dotnet test

# Run E2E tests
cd frontend/fire-extinguisher-web
npm run test:e2e
```

### CI/CD Pipeline
```yaml
# .github/workflows/run-tests.yml
- name: Run Unit Tests
  run: dotnet test tests/unit/FireExtinguisherInspection.Tests

- name: Setup Test Database
  run: |
    sqlcmd -S localhost -U sa -P ${{ secrets.SA_PASSWORD }} \
      -i database/scripts/001_CreateCoreSchema.sql
    sqlcmd -i database/scripts/seed-test-data.sql

- name: Run Integration Tests
  run: dotnet test tests/integration/FireExtinguisherInspection.IntegrationTests
  env:
    ConnectionStrings__DefaultConnection: ${{ secrets.TEST_DB_CONNECTION }}

- name: Run E2E Tests
  run: |
    npm run build
    npm run preview &
    npm run test:e2e
```

## Success Criteria

### Must Pass
- ✅ All unit tests pass (100%)
- ✅ All integration tests pass (100%)
- ✅ Data isolation tests pass (critical for multi-tenancy)
- ✅ E2E smoke tests pass

### Performance Benchmarks
- ✅ Single-tenant query performance: < 100ms (p95)
- ✅ Cross-tenant isolation has no performance penalty
- ✅ RLS adds < 10ms overhead vs tenant-schema approach

### Code Coverage
- **Target**: 80% overall coverage
- **Services**: 85% coverage (critical business logic)
- **Controllers**: 75% coverage (integration tested)
- **DTOs**: 100% coverage (simple validation)

## RLS Migration Verification Checklist

### Service-Level Checks
- [ ] ChecklistTemplateService uses `CreateConnectionAsync()`
- [ ] DeficiencyService uses `CreateConnectionAsync()`
- [ ] AzureBlobPhotoService uses `CreateConnectionAsync()`
- [ ] All services pass `@TenantId` to stored procedures
- [ ] No calls to `GetTenantSchemaAsync()`
- [ ] No calls to `CreateTenantConnectionAsync()`

### Stored Procedure Checks
- [ ] All SPs use `dbo` schema
- [ ] All SPs have `@TenantId UNIQUEIDENTIFIER` parameter
- [ ] All SPs filter by `WHERE TenantId = @TenantId`
- [ ] No SPs use dynamic schema names
- [ ] All SPs return TenantId in result set

### Data Integrity Checks
- [ ] Tenant A cannot access Tenant B's data
- [ ] Tenant B cannot access Tenant A's data
- [ ] System templates are accessible to all tenants
- [ ] Custom templates are only accessible to owning tenant
- [ ] Audit logs include correct TenantId

## Recommended Testing Tools

### Unit Testing
- **xUnit** - Test framework (already in place)
- **Moq** - Mocking framework (already in place)
- **FluentAssertions** - Readable assertions (already in place)

### Integration Testing
- **Respawn** - Database cleanup between tests
- **TestContainers** - SQL Server in Docker for tests
- **Bogus** - Test data generation

### E2E Testing
- **Playwright** - Browser automation (already in place)
- **Faker.js** - Test data generation

## Next Steps

1. **Fix Existing Tests** - Update service constructor mocks to match actual signatures
2. **Add Integration Tests** - Create database integration test project
3. **Expand E2E Tests** - Add multi-tenant isolation tests
4. **Set Up Test Data** - Create seed data scripts for automated tests
5. **CI/CD Integration** - Add test execution to deployment pipeline

## Conclusion

This comprehensive test strategy ensures that the RLS migration maintains data integrity and multi-tenant isolation. By following this strategy, we can confidently deploy the updated services knowing that tenant data remains secure and properly isolated.

**Priority**: HIGH - Testing is critical before production deployment
**Timeline**: Complete within 1-2 weeks for production readiness
