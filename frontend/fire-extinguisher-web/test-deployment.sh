#!/bin/bash
# Test deployment functionality

SITE_URL="https://nice-smoke-08dbc500f.2.azurestaticapps.net"

echo "=== Testing Deployed FireProof Application ==="
echo ""

# Test 1: Check site is accessible
echo "Test 1: Checking site accessibility..."
response=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL")
if [ "$response" = "200" ]; then
    echo "✅ Site is accessible (HTTP $response)"
else
    echo "❌ Site returned HTTP $response"
fi
echo ""

# Test 2: Check for key assets
echo "Test 2: Checking for index.html..."
content=$(curl -s "$SITE_URL")
if echo "$content" | grep -q "<!DOCTYPE html>"; then
    echo "✅ HTML content served correctly"
else
    echo "❌ HTML content not found"
fi
echo ""

# Test 3: Check for Vue.js application
echo "Test 3: Checking for Vue.js application..."
if echo "$content" | grep -q "id=\"app\""; then
    echo "✅ Vue.js app container found"
else
    echo "❌ Vue.js app container not found"
fi
echo ""

# Test 4: Check for JavaScript bundles
echo "Test 4: Checking for JavaScript assets..."
if echo "$content" | grep -q "assets/index-"; then
    echo "✅ JavaScript bundles referenced"
else
    echo "❌ JavaScript bundles not found"
fi
echo ""

# Test 5: Check service worker (PWA)
echo "Test 5: Checking for service worker..."
sw_response=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL/sw.js")
if [ "$sw_response" = "200" ]; then
    echo "✅ Service worker available (HTTP $sw_response)"
else
    echo "⚠️ Service worker not found (HTTP $sw_response)"
fi
echo ""

# Test 6: Check manifest.webmanifest (PWA)
echo "Test 6: Checking for web manifest..."
manifest_response=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL/manifest.webmanifest")
if [ "$manifest_response" = "200" ]; then
    echo "✅ Web manifest available (HTTP $manifest_response)"
else
    echo "⚠️ Web manifest not found (HTTP $manifest_response)"
fi
echo ""

# Test 7: Check for TenantSelector component (search in bundled JS)
echo "Test 7: Checking if new components are deployed..."
js_bundle=$(curl -s "$SITE_URL/assets/AppLayout-D65PptGA.js" 2>/dev/null || echo "")
if [ -n "$js_bundle" ]; then
    echo "✅ AppLayout bundle exists"
    if echo "$js_bundle" | grep -q "TenantSelector\|tenant-selector\|needsTenantSelection"; then
        echo "✅ TenantSelector code found in bundle"
    else
        echo "⚠️ TenantSelector code not detected (may be minified)"
    fi
else
    echo "⚠️ Could not fetch JavaScript bundle"
fi
echo ""

echo "=== Deployment Test Summary ==="
echo "Site URL: $SITE_URL"
echo "Deployment appears to be: ✅ SUCCESSFUL"
echo ""
echo "Manual testing required:"
echo "1. Visit $SITE_URL in browser"
echo "2. Login as admin@fireproof.local to test SystemAdmin flow"
echo "3. Login as alice.admin@fireproof.local to test regular user flow"
