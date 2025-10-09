# FireExtinguisher Integration Tests

This project contains integration tests that verify the complete functionality of the FireProof system against a real database.

## Prerequisites

1. **SQL Server** - A test SQL Server instance must be available
2. **Test Database** - Create a test database named `FireProofTest`
3. **Configuration** - Update `appsettings.test.json` with your test database connection string

## Configuration

Edit `appsettings.test.json` and update the connection string:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=FireProofTest;User Id=sa;Password=YourPassword;..."
  }
}
```

## Running Tests

### Run all integration tests
```bash
dotnet test
```

### Run with detailed output
```bash
dotnet test --logger "console;verbosity=detailed"
```

### Run specific test class
```bash
dotnet test --filter "FullyQualifiedName~ExtinguisherTypeServiceIntegrationTests"
```

## Test Structure

### ExtinguisherTypeServiceIntegrationTests

Tests the complete CRUD operations for extinguisher types including:
- **Create** - Creating new extinguisher types, handling duplicates
- **Read** - Fetching all types, filtering by active status, fetching by ID
- **Update** - Updating type details, handling non-existent types
- **Delete** - Soft deleting types, handling non-existent types

Each test:
1. Creates an isolated tenant schema with test data
2. Executes the operation being tested
3. Verifies results against the database
4. Cleans up the tenant schema after completion

## Test Isolation

Tests use `IAsyncLifetime` to:
- **InitializeAsync** - Create unique tenant schema and stored procedures per test run
- **DisposeAsync** - Drop tenant schema and clean up test data

This ensures:
- Tests don't interfere with each other
- Tests can run in parallel
- No persistent test data in the database

## Database Setup

Each test automatically:
1. Creates a new tenant schema: `tenant_<guid>`
2. Creates the `ExtinguisherTypes` table
3. Creates all required stored procedures
4. Registers the tenant in `common.TenantRegistry`
5. Runs tests
6. Drops the schema and cleans up registry

## Troubleshooting

### Connection Failures
- Verify SQL Server is running
- Check connection string in `appsettings.test.json`
- Ensure test database exists
- Verify user has appropriate permissions

### Schema Errors
- Ensure `common` schema exists
- Ensure `common.TenantRegistry` table exists
- Run main database setup scripts first

### Test Failures
- Check test output for specific error messages
- Verify stored procedures are created correctly
- Check SQL Server error logs

## CI/CD Integration

These tests are designed to run in CI/CD pipelines. The GitHub Actions workflow can be configured to:
1. Spin up a SQL Server container
2. Run database migrations
3. Execute integration tests
4. Report results

Example workflow step:
```yaml
- name: Run integration tests
  run: dotnet test ./tests/integration/FireExtinguisherInspection.IntegrationTests
  env:
    ConnectionStrings__DefaultConnection: "Server=localhost;Database=FireProofTest;..."
```
