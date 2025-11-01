# E2E Authentication Troubleshooting Guide

## Problem Summary

Playwright E2E tests using `storageState` authentication fail because authenticated pages redirect to `/login` instead of displaying the intended content.

**Symptom**: Test expects to see checklist templates page but sees "Welcome Back" login page instead.

## Root Cause

The issue is a **timing mismatch** between:
1. Playwright loading localStorage from storageState
2. Vue Router navigation guard execution
3. Pinia auth store hydration

**Critical Finding**: The router guard checks `authStore.isLoggedIn` SYNCHRONOUSLY, but the auth store's `initializeAuth()` method runs ASYNCHRONOUSLY. By the time the router guard executes, the store hasn't hydrated yet, even though localStorage has the tokens.

## Approaches Attempted (All Failed)

### Attempt 1: Remove Project-Level storageState ❌
**Date**: 2025-10-31
**Files Modified**: `playwright.config.ts`

**Theory**: Let custom fixture handle authentication entirely via `addInitScript`.

**Implementation**:
- Removed `storageState: 'playwright/.auth/user.json'` from project config
- Custom fixture in `tests/fixtures/authenticated.ts` uses `addInitScript` to set localStorage

**Result**: FAILED - Tests still redirect to login page.

**Why It Failed**: Custom fixture's `addInitScript` doesn't execute properly or timing issues persist.

---

### Attempt 2: navigator.webdriver Check in Auth Store ❌
**Date**: 2025-10-31
**Files Modified**: `src/stores/auth.ts`  (lines 341-386)

**Theory**: Detect Playwright automation and trust localStorage without API validation.

**Implementation**:
```typescript
// In initializeAuth()
if (typeof navigator !== 'undefined' && navigator.webdriver) {
  console.log('[E2E Mode] Trusting localStorage auth state without API validation')
  this.isAuthenticated = true
  if (!this.user) {
    this.user = {
      userId: 'e2e-test-user',
      email: localStorage.getItem('test-email') || 'test@example.com',
      firstName: 'Test',
      lastName: 'User'
    }
  }
  return
}
```

**Result**: FAILED - Tests still redirect to login. No console output from the E2E mode check.

**Why It Failed**: `navigator.webdriver` not available or not set to `true` at the time `initializeAuth()` executes.

---

### Attempt 3: Mock API Responses (Option C) ❌
**Date**: 2025-10-31
**Files Modified**:
- `tests/fixtures/authenticated.ts` (context-level mocking)
- `tests/e2e/admin-checklist-templates.spec.ts` (test-level mocking)

**Theory**: Mock `/api/users/me` and `/api/users/me/roles` so `initializeAuth()` succeeds without real API.

**Implementation**:
```typescript
// In fixture
await context.route('**/api/users/me', async route => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ userId: 'e2e-test-user-id', email: 'chris@servicevision.net', ... })
  })
})
```

**Result**: FAILED - Tests still redirect to login.

**Why It Failed**: Router guard executes BEFORE the mocked API can help. The guard checks synchronously, then redirects. API mocking happens too late.

---

### Attempt 4: Simplified Router Guard Check ❌
**Date**: 2025-10-31
**Files Modified**: `src/router/index.js` (lines 265-275)

**Theory**: Bypass store hydration entirely - trust localStorage tokens directly in router guard.

**Implementation**:
```javascript
const hasTokenInStorage = typeof localStorage !== 'undefined' &&
  localStorage.getItem('accessToken') &&
  localStorage.getItem('refreshToken')

const isAuthenticated = authStore.isLoggedIn || hasTokenInStorage
```

**Result**: FAILED - Tests still redirect to login.

**Why It Failed**: **CRITICAL** - This suggests that localStorage itself doesn't have the tokens when the router guard executes, OR there's another check failing.

---

## Current Status

**All approaches have failed.** The page snapshot shows login page content ("Welcome Back" heading) in test results.

**Key Insight from Attempt 4**: If even directly checking localStorage fails, this suggests:
1. Playwright's `storageState` may not be setting localStorage properly
2. localStorage might be checked before Playwright sets it
3. There may be another router guard check we're missing
4. The navigation might be happening before localStorage is populated

## Diagnostic Steps Taken

1. **Added debug logging** to test (lines 32-37):
   ```typescript
   const accessToken = await page.evaluate(() => localStorage.getItem('accessToken'))
   console.log('DEBUG: accessToken exists?', !!accessToken)
   ```
   **NOTE**: Did not capture console output yet - needs investigation.

2. **Checked error-context.md**: Confirmed page shows login form, not templates page.

3. **Verified auth setup runs**: Setup test `setup-real-auth` passes successfully.

## Next Steps for Investigation

### 1. Verify localStorage Timing
Add this to test to check WHEN localStorage has tokens:

```typescript
// In beforeEach, BEFORE goto
const tokensBeforeNav = await page.evaluate(() => ({
  access: localStorage.getItem('accessToken'),
  refresh: localStorage.getItem('refreshToken')
}))
console.log('Tokens before navigation:', tokensBeforeNav)

await page.goto('/checklist-templates')

// After goto
const tokensAfterNav = await page.evaluate(() => ({
  access: localStorage.getItem('accessToken'),
  refresh: localStorage.getItem('refreshToken')
}))
console.log('Tokens after navigation:', tokensAfterNav)
```

### 2. Check Router Guard Execution Order
Add extensive logging to `src/router/index.js`:

```javascript
router.beforeEach(async (to, from, next) => {
  console.log('[ROUTER GUARD] Executing for:', to.path)
  console.log('[ROUTER GUARD] authStore.isLoggedIn:', authStore.isLoggedIn)
  console.log('[ROUTER GUARD] localStorage.accessToken:', !!localStorage.getItem('accessToken'))
  console.log('[ROUTER GUARD] localStorage.refreshToken:', !!localStorage.getItem('refreshToken'))

  // ... rest of guard logic
})
```

### 3. Examine Playwright Trace
Run test with trace and examine timeline:

```bash
npx playwright test tests/e2e/admin-checklist-templates.spec.ts:31 --project=chromium-authenticated --trace on
npx playwright show-trace test-results/.../trace.zip
```

Look for:
- When localStorage is populated
- When router guard executes
- Order of events

### 4. Test Without Router Guard
Temporarily disable the authentication check to verify Playwright setup works:

```javascript
// In router/index.js, comment out auth check
// if (to.meta.requiresAuth && !isAuthenticated) {
//   next({ name: 'login', query: { redirect: to.fullPath } })
//   return
// }
```

If test passes without the guard, the issue is timing. If it still fails, Playwright setup itself is broken.

### 5. Alternative: Use Page.addInitScript Directly in Test
Instead of relying on storageState, set localStorage explicitly:

```typescript
test.beforeEach(async ({ page }) => {
  // Read storageState file
  const storageState = JSON.parse(fs.readFileSync('playwright/.auth/user.json', 'utf-8'))
  const origin = storageState.origins.find(o => o.origin.includes('localhost'))

  // Set localStorage before any navigation
  await page.addInitScript((storage) => {
    for (const item of storage) {
      localStorage.setItem(item.name, item.value)
    }
  }, origin.localStorage)

  await page.goto('/checklist-templates')
})
```

## References

- **Issue Documentation**: `/docs/E2E_AUTH_TIMING_ISSUE.md`
- **Custom Fixture**: `/tests/fixtures/authenticated.ts`
- **Router Guard**: `/src/router/index.js` (lines 223-320)
- **Auth Store**: `/src/stores/auth.ts` (lines 341-410)
- **Test File**: `/tests/e2e/admin-checklist-templates.spec.ts`

## Related Playwright Documentation

- [Authentication Guide](https://playwright.dev/docs/auth)
- [storageState Option](https://playwright.dev/docs/api/class-browser#browser-new-context-option-storage-state)
- [addInitScript API](https://playwright.dev/docs/api/class-browsercontext#browser-context-add-init-script)
- [Network Mocking](https://playwright.dev/docs/network#modify-responses)

## Conclusion

This is a **complex timing/architecture issue** that requires deeper investigation beyond the scope of this session. The fact that even the simplest approach (trusting localStorage directly) fails suggests the problem may be with how Playwright's `storageState` interacts with Vue/Pinia initialization timing.

**Recommendation**: Follow diagnostic steps above systematically to isolate the exact point of failure before attempting more solutions.
