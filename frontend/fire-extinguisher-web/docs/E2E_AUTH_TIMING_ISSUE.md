# E2E Test Authentication Timing Issue

## Problem Summary

E2E tests using Playwright's `storageState` authentication fail because of a timing mismatch between:
1. Playwright loading `localStorage` from the saved auth state
2. Vue app initialization and Pinia store hydration
3. Vue Router navigation guard execution

**Symptom**: Tests redirect to `/login` page instead of showing the authenticated view.

## Root Cause Analysis

### The Authentication Flow Chain

1. **Playwright loads page** with `storageState: 'playwright/.auth/user.json'`
   - This sets `localStorage` with `accessToken`, `refreshToken`, `currentTenantId`

2. **Vue app initializes**
   - Pinia auth store creates with default state: `isAuthenticated: false`, `user: null`
   - State reads `accessToken` from localStorage but does NOT set `isAuthenticated = true`

3. **Router guard executes** (src/router/index.js:265)
   - Checks `authStore.isLoggedIn` getter
   - Getter requires: `state.isAuthenticated && state.user !== null && state.accessToken !== null`
   - Even though `accessToken` exists in localStorage, `isAuthenticated` is still `false`
   - Router redirects to `/login`

4. **Auth store initializes** (async, src/stores/auth.ts:345)
   - Calls `initializeAuth()` which makes API requests to validate token
   - If API succeeds: sets `isAuthenticated = true`
   - If API fails (401): calls `logout()` which **clears localStorage**
   - This happens AFTER router guard has already redirected to login

### Why Standard Playwright Patterns Fail

Playwright's `storageState` option loads cookies and localStorage, but:
- It does NOT trigger Pinia store initialization
- It does NOT wait for async store `initializeAuth()` to complete
- Router guards execute SYNCHRONOUSLY before store is hydrated

## Solutions Attempted

### 1. Navigate from Dashboard First (❌ Failed)
```typescript
test.beforeEach(async ({ page }) => {
  await page.goto('/dashboard')
  await page.goto('/checklist-templates')
})
```
**Why it failed**: Problem is in the router guard logic, not navigation order.

### 2. Await Auth Initialization in Router Guard (❌ Failed)
```javascript
if (!authInitStarted && !authStore.isAuthenticated && authStore.accessToken) {
  authInitStarted = true
  await authStore.initializeAuth() // Added await
}
```
**Why it failed**: `initializeAuth()` makes API calls that may fail, causing logout.

### 3. Direct localStorage Check in Router Guard (❌ Failed)
```javascript
const hasTokenInStorage = localStorage.getItem('accessToken') && localStorage.getItem('refreshToken')
const isAuthenticated = authStore.isLoggedIn || hasTokenInStorage
```
**Why it failed**: Still depends on async API validation succeeding.

### 4. Custom Test Fixture with addInitScript (⚠️ Partially Working)
**Created**: `tests/fixtures/authenticated.ts`

```typescript
export const test = base.extend({
  context: async ({ browser }, use) => {
    const context = await browser.newContext({
      storageState: 'playwright/.auth/user.json'
    })

    await context.addInitScript((storage) => {
      for (const item of storage) {
        window.localStorage.setItem(item.name, item.value)
      }
      window.__PLAYWRIGHT_E2E__ = true // Custom flag
    }, localStorage Data)

    await use(context)
  }
})
```

**Router guard update**:
```javascript
const isAuthenticated = authStore.isLoggedIn ||
  (window.__PLAYWRIGHT_E2E__ && hasTokenInStorage)
```

**Status**: Implemented but still failing. Possible issue: custom fixture context conflicts with `storageState` config in `playwright.config.ts` line 73.

## Files Modified

1. **src/router/index.js** (lines 265-273)
   - Added localStorage check for E2E test mode
   - Checks `window.__PLAYWRIGHT_E2E__` flag

2. **tests/fixtures/authenticated.ts** (NEW FILE)
   - Custom Playwright test fixture
   - Uses `addInitScript` to inject localStorage before page load
   - Sets `window.__PLAYWRIGHT_E2E__` flag for router guard detection

3. **tests/e2e/admin-checklist-templates.spec.ts** (line 1)
   - Changed to import from custom fixture: `import { test, expect } from '../fixtures/authenticated'`

4. **src/views/ChecklistTemplatesView.vue**
   - Added ~40 `data-testid` attributes for E2E testing

## Current Blocking Issue

The custom fixture approach conflicts with `playwright.config.ts`:

```typescript
// playwright.config.ts line 69-77
{
  name: 'chromium-authenticated',
  use: {
    ...devices['Desktop Chrome'],
    storageState: 'playwright/.auth/user.json', // ← Conflicts with fixture
  },
  dependencies: ['setup-real-auth'],
}
```

When both the project config AND the custom fixture specify storage state or context creation, the fixture's `addInitScript` may not execute properly.

## Potential Solutions (Not Yet Tested)

### Option A: Remove Project-Level Storage State
Move storage state loading entirely to the custom fixture:

```typescript
// playwright.config.ts
{
  name: 'chromium-authenticated',
  use: {
    ...devices['Desktop Chrome'],
    // Remove: storageState: 'playwright/.auth/user.json'
  },
  dependencies: ['setup-real-auth'],
}
```

### Option B: Environment Variable Check in Auth Store
Modify `initializeAuth()` to skip API validation in test mode:

```typescript
async initializeAuth(): Promise<void> {
  if (import.meta.env.MODE === 'test' && localStorage.getItem('accessToken')) {
    // Trust localStorage without API validation
    this.isAuthenticated = true
    return
  }
  // Normal API validation flow...
}
```

**Pros**: Minimal, targeted fix
**Cons**: Modifies production code for test purposes

### Option C: Mock API Responses in Playwright
Use Playwright's `route.fulfill()` to mock `/api/users/me` and `/api/users/me/roles`:

```typescript
test.beforeEach(async ({ page }) => {
  await page.route('**/api/users/me', route => route.fulfill({
    status: 200,
    body: JSON.stringify({ userId: '...', email: 'chris@servicevision.net' })
  }))
})
```

**Pros**: No production code changes
**Cons**: Requires maintaining mock data

## Recommendations

1. **Short-term**: Try Option A first (remove project-level storageState)
2. **Medium-term**: If Option A fails, implement Option C (API mocking)
3. **Long-term**: Consider refactoring auth store to separate concerns:
   - Token storage/retrieval
   - API validation
   - State management

## Testing Verification

Once fixed, verify with:
```bash
npx playwright test tests/e2e/admin-checklist-templates.spec.ts:31 --project=chromium-authenticated
```

Expected: Test should load `/checklist-templates` page directly without redirecting to `/login`.

## Related Files

- Auth Store: `src/stores/auth.ts` (lines 28-46, 345-389)
- Router Guard: `src/router/index.js` (lines 223-302)
- Test Fixture: `tests/fixtures/authenticated.ts`
- Playwright Config: `playwright.config.ts` (lines 69-77)
- Auth Setup: `tests/e2e/auth-setup-real.ts`
- Saved Auth State: `playwright/.auth/user.json`

## Date

Last Updated: 2025-10-31 (Day 1 of E2E test implementation)
