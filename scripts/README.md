# FireProof Utility Scripts

This directory contains utility scripts for FireProof development and testing.

## Seed Test Data

The `seed-test-data.js` script creates test data for E2E testing via the API. This ensures all data is properly created with the correct structure, including:

- Complex Inspections table with InspectionTypeId references
- Blockchain-style tamper hashing
- Proper InspectionChecklistResponses entries
- Multi-tenant data isolation

### Usage

1. **First time setup:**
   ```bash
   cd scripts
   npm install
   ```

2. **Run the seed script:**
   ```bash
   npm run seed
   ```

   Or directly:
   ```bash
   node seed-test-data.js
   ```

3. **With custom configuration:**
   ```bash
   API_URL=https://fireproof-api-test-2025.azurewebsites.net/api \
   TEST_EMAIL=your@email.com \
   TEST_PASSWORD=YourPassword \
   TENANT_ID=your-tenant-id \
   node seed-test-data.js
   ```

### What it creates

The script creates:
- **3 locations**: Main Office, West Wing, Storage Facility
- **8 fire extinguishers**: Distributed across the locations
- **24 inspections**: Spread over 60 days with ~80% pass rate
  - Mix of Monthly, Annual, 5-Year, and 12-Year inspections
  - Varied pass/fail statuses
  - Some requiring service, some requiring replacement

### Idempotence

The script is idempotent - you can run it multiple times safely. It will:
- Skip creating locations that already exist (by location code)
- Skip creating extinguishers that already exist (by asset tag)
- Always create new inspections (for continuous testing)

### Before Running

Ensure:
1. The backend API is running at `https://fireproof-api-test-2025.azurewebsites.net/api` (or your configured URL)
2. The test user exists: `chris@servicevision.net` with password `Gv51076`
3. The test tenant exists: `634f2b52-d32a-46dd-a045-d158e793adcb`

## Troubleshooting

### "Login failed"
- Verify the API is running
- Check the test user credentials
- Ensure the user has access to the specified tenant

### "No extinguisher types found"
- Run the database seed scripts first (`002_CreateTenantSchema.sql`, etc.)
- Ensure the tenant schema has been properly initialized

### "Failed to create inspections"
- Verify extinguishers were created successfully
- Check API logs for detailed error messages
- Ensure the InspectionTypes table is populated

## Integration with Tests

This script should be run before E2E tests to ensure test data exists:

```bash
# In CI/CD or local testing
cd scripts && npm install && npm run seed
cd ../frontend/fire-extinguisher-web && npm run test:e2e
```
