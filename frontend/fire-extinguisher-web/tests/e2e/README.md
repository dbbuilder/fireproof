# E2E Testing Guide

## Quick Start

### Prerequisites
1. Backend API running at `http://localhost:7001`
2. Frontend dev server running at `http://localhost:5173`
3. Test user credentials configured (see Configuration below)

### Running Tests

```powershell
# Terminal 1: Start frontend dev server
npx vite

# Terminal 2: Run all E2E tests
npm run test:e2e

# Or run specific test suites
npx playwright test --project=chromium-unauthenticated  # Login & smoke tests
npx playwright test --project=chromium-auth-flow        # Tenant & navigation tests
npx playwright test --project=chromium-authenticated    # Other authenticated tests
```

## Test Structure

### Projects

1. **setup-real-auth** - Runs once to authenticate and save session
   - Logs in with real credentials
   - Saves authentication state to `playwright/.auth/user.json`
   - Other tests reuse this session

2. **chromium-unauthenticated** - No authentication needed
   - Login page tests
   - Smoke tests (page load verification)

3. **chromium-auth-flow** - Tests that handle their own login
   - Tenant selector tests
   - Navigation tests
   - Each test logs in within the test itself

4. **chromium-authenticated** - Reuses saved authentication
   - Legacy tests
   - Any tests that need authentication but don't test login flow

### Test Files

```
tests/e2e/
├── auth-setup-real.ts              # Authentication setup
├── auth/
│   └── login.spec.ts               # Login flow tests (9 tests)
├── tenant/
│   └── tenant-selector.spec.ts     # Tenant selection tests (7 tests)
├── dashboard/
│   └── navigation.spec.ts          # Navigation tests (10 tests)
└── smoke.spec.ts                   # Basic page load tests
```

## Configuration

### Test Credentials

Edit `tests/e2e/auth-setup-real.ts` to configure test user:

```typescript
const testUser = {
  email: 'chris@servicevision.net',
  password: 'Gv51076!',
}
```

### API URL

Configured in `.env.local`:
```
VITE_API_BASE_URL=http://localhost:7001/api
```

## Debugging

### View Test Report
```powershell
npx playwright show-report
```

### Run Tests with UI (Interactive Mode)
```powershell
npm run test:e2e:ui
```

### Run Tests in Headed Mode (See Browser)
```powershell
npm run test:e2e:headed
```

### Run Specific Test File
```powershell
npx playwright test tests/e2e/auth/login.spec.ts
```

### Debug Single Test
```powershell
npx playwright test tests/e2e/auth/login.spec.ts --debug
```

## Test IDs

All tests use `data-testid` attributes for reliable element selection. See `TEST_ID_GUIDE.md` in the root directory for:
- Naming conventions
- Component-specific test IDs
- Best practices
- How to add test IDs to new components

## Troubleshooting

### Authentication Fails
- Verify backend is running at `http://localhost:7001`
- Check credentials in `auth-setup-real.ts`
- Check `.env.local` has correct `VITE_API_BASE_URL`
- Restart dev server to pick up environment changes

### Tests Can't Find Elements
- Check that component has `data-testid` attributes
- Verify test ID naming matches the pattern in `TEST_ID_GUIDE.md`
- Use Playwright UI mode to inspect elements: `npm run test:e2e:ui`

### Dev Server Issues on Windows
- Use `npx vite` instead of `npm run dev`
- Or run in WSL: `cd /mnt/d/dev2/fireproof/frontend/fire-extinguisher-web && npm run dev`

## CI/CD

For CI/CD environments, uncomment the `webServer` configuration in `playwright.config.ts`:

```typescript
webServer: {
  command: 'npx vite',
  url: 'http://localhost:5173',
  reuseExistingServer: !process.env.CI,
  timeout: 120 * 1000,
},
```

This will automatically start the dev server before tests run.
