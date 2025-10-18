# Test Database Setup for GitHub Actions

This guide explains how to configure GitHub Actions to run integration tests against your SQL Server.

## Overview

Instead of using SQL Server containers in GitHub Actions, we connect to the existing test SQL Server at `sqltest.schoolvision.net,14333`. This is faster and leverages existing infrastructure.

## Prerequisites

1. **Test Database**: Create a dedicated test database on your SQL Server
   - Recommended name: `FireProofDB_Test` or `FireProofDB_CI`
   - This should be separate from development and production databases

2. **Test Data**: The test database should have:
   - Core schema tables (Tenants, Users, etc.)
   - Test tenant data (at least 2 test tenants for isolation testing)
   - Stored procedures (same as production)

## Setup Instructions

### 1. Create Test Database

Run this on your SQL Server:

```sql
-- Create test database
CREATE DATABASE FireProofDB_Test;
GO

USE FireProofDB_Test;
GO

-- Run all schema creation scripts
-- Execute in order:
-- 1. database/scripts/001_CreateCoreSchema.sql
-- 2. database/scripts/002_CreateTenantSchema.sql (if applicable)
-- 3. All stored procedure scripts
```

### 2. Seed Test Data

Create at least two test tenants for multi-tenant isolation testing:

```sql
USE FireProofDB_Test;
GO

-- Create test tenants
INSERT INTO dbo.Tenants (TenantId, CompanyName, SubscriptionLevel, IsActive, CreatedDate, ModifiedDate)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'CI Test Tenant A', 'Professional', 1, GETUTCDATE(), GETUTCDATE()),
    ('22222222-2222-2222-2222-222222222222', 'CI Test Tenant B', 'Professional', 1, GETUTCDATE(), GETUTCDATE());

-- Create test users
INSERT INTO dbo.Users (UserId, Email, PasswordHash, FirstName, LastName, IsActive, CreatedDate, ModifiedDate)
VALUES
    ('AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', 'test-a@ci.fireproof.test', 'hash', 'Test', 'User A', 1, GETUTCDATE(), GETUTCDATE()),
    ('BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', 'test-b@ci.fireproof.test', 'hash', 'Test', 'User B', 1, GETUTCDATE(), GETUTCDATE());

-- Assign users to tenants
INSERT INTO dbo.UserTenantRoles (UserTenantRoleId, UserId, TenantId, RoleName, CreatedDate)
VALUES
    (NEWID(), 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA', '11111111-1111-1111-1111-111111111111', 'Admin', GETUTCDATE()),
    (NEWID(), 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB', '22222222-2222-2222-2222-222222222222', 'Admin', GETUTCDATE());
```

See `database/scripts/SEED_TEST_DATA.sql` for more comprehensive test data.

### 3. Configure GitHub Secret

Add the connection string as a GitHub repository secret:

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Name: `TEST_DB_CONNECTION_STRING`
5. Value:
   ```
   Server=sqltest.schoolvision.net,14333;Database=FireProofDB_Test;User Id=sv;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=Optional;MultipleActiveResultSets=true;Connection Timeout=30
   ```

**Important**: Replace `YOUR_PASSWORD` with the actual password for the `sv` user.

### 4. Enable Integration Tests in Workflow

Once the secret is configured, uncomment the integration test step in `.github/workflows/run-tests.yml`:

```yaml
- name: Run integration tests
  working-directory: ./backend/FireExtinguisherInspection.API
  env:
    ConnectionStrings__DefaultConnection: ${{ secrets.TEST_DB_CONNECTION_STRING }}
  run: dotnet test --configuration Release --no-build --verbosity normal --filter "Category=Integration" --logger "trx;LogFileName=integration-test-results.trx"
```

## Writing Integration Tests

Integration tests should be marked with the `[Trait("Category", "Integration")]` attribute:

```csharp
namespace FireExtinguisherInspection.Tests.Integration
{
    public class ExtinguisherServiceIntegrationTests : IDisposable
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public ExtinguisherServiceIntegrationTests()
        {
            var configuration = new ConfigurationBuilder()
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection");
            _connectionFactory = new DbConnectionFactory(connectionString);
        }

        [Fact]
        [Trait("Category", "Integration")]
        public async Task GetAllExtinguishers_ShouldOnlyReturnTenantData()
        {
            // Arrange
            var tenantA = Guid.Parse("11111111-1111-1111-1111-111111111111");
            var tenantB = Guid.Parse("22222222-2222-2222-2222-222222222222");
            var service = new ExtinguisherService(_connectionFactory, ...);

            // Act
            var resultA = await service.GetAllExtinguishersAsync(tenantA);
            var resultB = await service.GetAllExtinguishersAsync(tenantB);

            // Assert
            resultA.Should().AllSatisfy(e => e.TenantId.Should().Be(tenantA));
            resultB.Should().AllSatisfy(e => e.TenantId.Should().Be(tenantB));
        }

        public void Dispose()
        {
            // Cleanup test data if needed
        }
    }
}
```

## Test Data Cleanup

Option 1: **Use transactions** in tests (recommended)
- Wrap each test in a transaction
- Rollback at the end of the test
- No cleanup needed

Option 2: **Manual cleanup** in `Dispose()`
- Delete test records created during tests
- Reset to known good state

Option 3: **Database snapshot**
- Create a snapshot before tests
- Restore snapshot after test run
- Requires SQL Server Enterprise or Developer edition

## Firewall Configuration

**Important**: Ensure GitHub Actions runners can access your SQL Server.

GitHub Actions uses dynamic IP addresses from Azure data centers. You have two options:

### Option 1: Allow Azure IP Ranges
Add Azure data center IP ranges to SQL Server firewall rules.

### Option 2: Use Self-Hosted Runner
Set up a self-hosted GitHub Actions runner on your network:
- More secure (no firewall changes needed)
- Faster (local network access)
- Full control over test environment

See: https://docs.github.com/en/actions/hosting-your-own-runners

## Troubleshooting

### Connection Timeout
```
Error: Connection Timeout Expired
```

**Solution**: Check firewall rules and ensure SQL Server is accessible from GitHub Actions runners.

### Login Failed
```
Error: Login failed for user 'sv'
```

**Solution**: Verify the password in the GitHub Secret is correct.

### Database Not Found
```
Error: Cannot open database "FireProofDB_Test"
```

**Solution**: Ensure the test database exists and the user has access.

## Security Considerations

1. **Dedicated Test Database**: Never use production database for tests
2. **Limited Permissions**: Test user should only have access to test database
3. **No Sensitive Data**: Test database should not contain real customer data
4. **Separate Credentials**: Use different credentials than production
5. **Audit Logging**: Monitor test database access for security

## Next Steps

Once the test database is configured:

1. Write integration tests following the patterns in `COMPREHENSIVE_TEST_STRATEGY.md`
2. Run tests locally to verify they work
3. Push to GitHub and verify tests run in CI
4. Gradually increase test coverage

For test writing guidance, see:
- `tests/COMPREHENSIVE_TEST_STRATEGY.md` - Overall testing strategy
- `.github/workflows/run-tests.yml` - Workflow configuration
- `backend/FireExtinguisherInspection.API/` - Service code to test
