#!/bin/bash
#============================================================================
# File:     test-api.sh
# Purpose:  Test FireProof API endpoints after database setup
# Date:     October 14, 2025
#============================================================================

API_BASE="https://api-firefactory.gentledune-ea24a71b.eastus2.azurecontainerapps.io/api"

echo "============================================================================"
echo "FIREPROOF API ENDPOINT TESTS"
echo "============================================================================"
echo ""

# First get access token by logging in
echo "[ TEST 1 ] Getting authentication token..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/authentication/dev-login" \
  -H "Content-Type: application/json" \
  -d '{"email":"chris@servicevision.net"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "  ✗ FAILED: Could not get authentication token"
    echo "  Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "  ✓ PASSED: Authentication successful"
echo ""

# Get available tenants
echo "[ TEST 2 ] Getting available tenants..."
TENANTS_RESPONSE=$(curl -s -X GET "$API_BASE/tenants/available" \
  -H "Authorization: Bearer $TOKEN")

echo "  Response: $TENANTS_RESPONSE"
echo ""

# Extract DEMO001 tenant ID
DEMO001_ID=$(echo $TENANTS_RESPONSE | grep -o '"tenantId":"634F2B52-D32A-46DD-A045-D158E793ADCB"' | cut -d'"' -f4)

if [ -z "$DEMO001_ID" ]; then
    # Try alternate extraction
    DEMO001_ID="634F2B52-D32A-46DD-A045-D158E793ADCB"
fi

echo "Using DEMO001 Tenant ID: $DEMO001_ID"
echo ""

# Test Locations endpoint
echo "[ TEST 3 ] Testing GET /api/locations..."
LOCATIONS_RESPONSE=$(curl -s -X GET "$API_BASE/locations" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $DEMO001_ID")

if echo "$LOCATIONS_RESPONSE" | grep -q '"locationId"'; then
    LOCATION_COUNT=$(echo "$LOCATIONS_RESPONSE" | grep -o '"locationId"' | wc -l)
    echo "  ✓ PASSED: Retrieved $LOCATION_COUNT location(s)"
    echo "  Sample: $(echo $LOCATIONS_RESPONSE | head -c 200)..."
else
    echo "  ✗ FAILED: No locations returned"
    echo "  Response: $LOCATIONS_RESPONSE"
fi
echo ""

# Test Extinguisher Types endpoint
echo "[ TEST 4 ] Testing GET /api/extinguisher-types..."
TYPES_RESPONSE=$(curl -s -X GET "$API_BASE/extinguisher-types" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $DEMO001_ID")

if echo "$TYPES_RESPONSE" | grep -q '"extinguisherTypeId"'; then
    TYPE_COUNT=$(echo "$TYPES_RESPONSE" | grep -o '"extinguisherTypeId"' | wc -l)
    echo "  ✓ PASSED: Retrieved $TYPE_COUNT extinguisher type(s)"
    echo "  Sample: $(echo $TYPES_RESPONSE | head -c 200)..."
else
    echo "  ✗ FAILED: No extinguisher types returned"
    echo "  Response: $TYPES_RESPONSE"
fi
echo ""

# Test Extinguishers endpoint
echo "[ TEST 5 ] Testing GET /api/extinguishers..."
EXTINGUISHERS_RESPONSE=$(curl -s -X GET "$API_BASE/extinguishers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Tenant-ID: $DEMO001_ID")

if echo "$EXTINGUISHERS_RESPONSE" | grep -q '"extinguisherId"'; then
    EXT_COUNT=$(echo "$EXTINGUISHERS_RESPONSE" | grep -o '"extinguisherId"' | wc -l)
    echo "  ✓ PASSED: Retrieved $EXT_COUNT extinguisher(s)"
    echo "  Sample: $(echo $EXTINGUISHERS_RESPONSE | head -c 200)..."
else
    echo "  ✗ FAILED: No extinguishers returned"
    echo "  Response: $EXTINGUISHERS_RESPONSE"
fi
echo ""

echo "============================================================================"
echo "API TEST SUITE COMPLETED"
echo "============================================================================"
echo ""
echo "If all tests passed, the frontend should now work without console errors!"
echo "Test at: https://fireproofapp.net"
echo ""
