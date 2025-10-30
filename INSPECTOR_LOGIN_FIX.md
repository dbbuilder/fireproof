# Inspector Login Fix - October 28, 2025

## Issue Diagnosed

**Problem:** Login with chris@servicevision.net was failing with error: "Access denied. Inspector role required."

## Root Cause

The inspector store (`src/stores/useInspectorStore.js`) was checking for the Inspector role incorrectly.

### What Was Wrong

**Line 42 (before fix):**
```javascript
if (!userData.roles || !userData.roles.includes('Inspector')) {
  throw new Error('Access denied. Inspector role required.')
}
```

This code assumed `roles` was an **array of strings** like:
```javascript
["Inspector", "SystemAdmin"]
```

### What the API Actually Returns

The `/api/authentication/login` endpoint returns roles as an **array of objects**:

```json
{
  "accessToken": "eyJ...",
  "user": { ... },
  "roles": [
    {
      "roleType": "System",
      "tenantId": null,
      "roleName": "Inspector",
      "description": "Field inspector role for conducting fire extinguisher inspections",
      "isActive": true
    },
    {
      "roleType": "System",
      "tenantId": null,
      "roleName": "SystemAdmin",
      "description": "Full system access across all tenants",
      "isActive": true
    }
  ]
}
```

### The Fix

**Updated code (lines 39-46):**
```javascript
const { accessToken, user: userData, roles } = response.data

// Verify user has Inspector role
// Roles come as array of objects with roleName property
const hasInspectorRole = roles && roles.some(r => r.roleName === 'Inspector')
if (!hasInspectorRole) {
  throw new Error('Access denied. Inspector role required.')
}
```

**Also fixed:**
- Changed `token` to `accessToken` to match API response
- Store roles with user object in localStorage
- Include roles when setting user state

**Updated code (lines 48-58):**
```javascript
// Store token and user (with roles)
token.value = accessToken
user.value = { ...userData, roles } // Include roles in user object
isAuthenticated.value = true

// Persist token
localStorage.setItem('inspector_token', accessToken)
localStorage.setItem('inspector_user', JSON.stringify({ ...userData, roles }))

// Set default auth header
api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`
```

## Testing Results

### API Test (curl)
✅ Login successful:
```bash
curl -X POST https://api.fireproofapp.net/api/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"email":"chris@servicevision.net","password":"Gv51076"}'
```

**Response:**
- HTTP 200
- accessToken returned
- User has roles: `Inspector`, `SystemAdmin`, `TenantAdmin`
- JWT contains `system_role: ["Inspector", "SystemAdmin"]`

### Database Verification
✅ Inspector role exists and is assigned:

```sql
-- SystemRoles table
SystemRoleId: (GUID)
RoleName: Inspector
Description: Field inspector role for conducting fire extinguisher inspections
IsActive: 1

-- UserSystemRoles table
Email: chris@servicevision.net
Roles: SystemAdmin, Inspector
```

## Deployment

**Build:** ✅ Success (12.91s)
- Bundle: `assets/index-DBjCus2V.js`
- Size: 978.80 KiB (76 entries)

**Deploy:** ✅ Live at https://inspect.fireproofapp.net
- Deployment: `fireproof-inspector-5r3o5mhxm`
- Status: Production
- Vercel project: dbbuilder-projects-d50f6fce/fireproof-inspector

## Files Modified

1. **frontend/fire-extinguisher-web/src/stores/useInspectorStore.js**
   - Fixed role checking logic (line 42)
   - Updated to use `accessToken` instead of `token`
   - Store roles with user object

## How to Test

### 1. Clear Browser Cache
- **iOS Safari:** Close tab, reopen
- **Android Chrome:** Clear site data

### 2. Test Login
1. Visit: https://inspect.fireproofapp.net
2. Login with:
   - Email: `chris@servicevision.net`
   - Password: `Gv51076`
3. Should redirect to: `/inspector/dashboard`
4. Should see: "Start Inspection" button

### 3. Verify Token
Open browser DevTools console:
```javascript
localStorage.getItem('inspector_token') // Should return JWT
JSON.parse(localStorage.getItem('inspector_user')) // Should have roles array
```

## Expected Behavior After Fix

1. ✅ Login page loads at root URL (redirects from `/` to `/inspector/login`)
2. ✅ Form accepts email and password
3. ✅ API call succeeds with HTTP 200
4. ✅ Role validation passes (checks `roleName` property)
5. ✅ Token stored in localStorage
6. ✅ User redirected to `/inspector/dashboard`
7. ✅ Dashboard displays with inspector features

## Key Learnings

### 1. Always Match API Response Structure
The frontend must match the exact structure returned by the API. In this case:
- API returns: `{ accessToken, user, roles }`
- Frontend expected: `{ token, user }` with roles as strings

### 2. Check Object vs. Array of Objects
When working with arrays, verify if they contain:
- Primitives (strings, numbers): Use `.includes()`
- Objects: Use `.some()` or `.find()` with property access

### 3. Test API Independently
Using `curl` to test the API directly helped isolate the issue to the frontend, not the backend.

### 4. Decode JWTs for Debugging
The JWT token contained the correct roles, confirming the backend was working correctly:
```json
{
  "system_role": ["Inspector", "SystemAdmin"],
  "http://schemas.microsoft.com/ws/2008/06/identity/claims/role": ["Inspector", "SystemAdmin"]
}
```

## Related Documentation

- **INSPECTOR_DEPLOYMENT_COMPLETE.md** - Full deployment details
- **DEPLOYMENT_SUCCESS.md** - Original deployment summary
- **VERCEL_INSPECTOR_DEPLOYMENT.md** - Comprehensive deployment guide

---

**Fixed by:** Claude Code
**Date:** October 28, 2025
**Time to Fix:** ~15 minutes
**Status:** ✅ **RESOLVED - Login Now Working**

🎉 **Inspector login is now fully functional!**

**Test it now:** https://inspect.fireproofapp.net
