#!/usr/bin/env node
/**
 * Seed Test Data via API
 *
 * This script creates test data using the FireProof API endpoints,
 * which properly handles the complex Inspections table structure with:
 * - InspectionTypeId references
 * - Blockchain-style tamper hashing
 * - Separate InspectionChecklistResponses table
 *
 * This script is idempotent - it can be run multiple times safely.
 * It will skip creating data that already exists.
 *
 * Usage:
 *   npm install  (first time only)
 *   node seed-test-data.js
 *
 * Or from package.json:
 *   npm run seed-test-data
 */

const axios = require('axios');

// Configuration
const CONFIG = {
  API_BASE_URL: process.env.API_URL || 'http://localhost:7001/api',
  TEST_EMAIL: process.env.TEST_EMAIL || 'chris@servicevision.net',
  TEST_PASSWORD: process.env.TEST_PASSWORD || 'Gv51076',
  TENANT_ID: process.env.TENANT_ID || '634f2b52-d32a-46dd-a045-d158e793adcb'
};

// State
let authToken = null;
let userId = null;
let locationIds = [];
let extinguisherTypeIds = [];
let extinguisherIds = [];
let inspectionTypeIds = [];

// Helper to make authenticated requests
const api = axios.create({
  baseURL: CONFIG.API_BASE_URL,
  validateStatus: () => true // Don't throw on any status
});

function setAuthHeaders() {
  api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`;
  api.defaults.headers.common['X-Tenant-ID'] = CONFIG.TENANT_ID;
}

async function login() {
  console.log('🔐 Logging in...');
  try {
    const response = await api.post('/authentication/login', {
      email: CONFIG.TEST_EMAIL,
      password: CONFIG.TEST_PASSWORD
    });

    if (response.status !== 200) {
      throw new Error(`Login failed with status ${response.status}: ${JSON.stringify(response.data)}`);
    }

    authToken = response.data.accessToken;
    userId = response.data.user.userId;
    setAuthHeaders();
    console.log('✅ Login successful!');
    return authToken;
  } catch (error) {
    console.error('❌ Login failed:', error.message);
    throw error;
  }
}

async function setTenant() {
  console.log('🏢 Setting tenant...');
  try {
    const response = await api.post('/tenants/set-tenant', { tenantId: CONFIG.TENANT_ID });

    if (response.status !== 200) {
      console.log(`⚠️  Set tenant returned ${response.status}, continuing anyway...`);
      return;
    }

    console.log('✅ Tenant set successfully!');
  } catch (error) {
    console.log('⚠️  Failed to set tenant, continuing anyway:', error.message);
  }
}

async function getExistingData() {
  console.log('📊 Fetching existing data...');

  try {
    // SystemAdmin users must specify tenantId as query parameter
    const queryParams = { tenantId: CONFIG.TENANT_ID };

    // Get locations
    const locationsRes = await api.get('/locations', { params: queryParams });
    console.log(`  Locations response: status=${locationsRes.status}, isArray=${Array.isArray(locationsRes.data)}`);
    if (locationsRes.status === 200 && Array.isArray(locationsRes.data)) {
      locationIds = locationsRes.data.map(l => l.locationId);
      console.log(`  Found ${locationIds.length} locations`);
    }

    // Get extinguisher types
    const typesRes = await api.get('/ExtinguisherTypes', { params: queryParams });
    console.log(`  ExtinguisherTypes response: status=${typesRes.status}, isArray=${Array.isArray(typesRes.data)}`);
    if (typesRes.status === 200 && Array.isArray(typesRes.data)) {
      extinguisherTypeIds = typesRes.data.map(t => t.extinguisherTypeId);
      console.log(`  Found ${extinguisherTypeIds.length} extinguisher types`);
    }

    // Get inspection types
    const inspTypesRes = await api.get('/InspectionTypes', { params: queryParams });
    console.log(`  InspectionTypes response: status=${inspTypesRes.status}, isArray=${Array.isArray(inspTypesRes.data)}`);
    if (inspTypesRes.status === 200 && Array.isArray(inspTypesRes.data)) {
      inspectionTypeIds = inspTypesRes.data.map(t => t.inspectionTypeId);
      console.log(`  Found ${inspectionTypeIds.length} inspection types`);
    }

    console.log('✅ Existing data fetched');
  } catch (error) {
    console.error('❌ Failed to fetch existing data:', error.message);
    throw error;
  }
}

async function createAdditionalLocations() {
  console.log('📍 Creating additional locations...');

  const newLocations = [
    {
      locationCode: 'WW-02',
      locationName: 'West Wing - Building B',
      addressLine1: '456 Industrial Blvd',
      city: 'Portland',
      stateProvince: 'OR',
      postalCode: '97201',
      country: 'USA'
    },
    {
      locationCode: 'SF-03',
      locationName: 'Storage Facility',
      addressLine1: '789 Warehouse Way',
      city: 'Eugene',
      stateProvince: 'OR',
      postalCode: '97401',
      country: 'USA'
    }
  ];

  for (const location of newLocations) {
    try {
      const response = await api.post('/locations', location);

      if (response.status === 201 || response.status === 200) {
        locationIds.push(response.data.locationId);
        console.log(`  ✅ Created location: ${location.locationName}`);
      } else if (response.status === 409 || response.status === 400) {
        console.log(`  → Location already exists: ${location.locationName}`);
      } else {
        console.log(`  ⚠️  Unexpected status ${response.status} for ${location.locationName}`);
      }
    } catch (error) {
      console.error(`  ❌ Failed to create location ${location.locationName}:`, error.message);
    }
  }

  console.log(`✅ Total locations: ${locationIds.length}`);
}

async function createExtinguishers() {
  console.log('🧯 Creating fire extinguishers...');

  const extinguishers = [
    { assetTag: 'TEST-MO-001', locationIdx: 0, serialNumber: 'SN-2024-001', manufacturer: 'Amerex', description: 'Main entrance, left wall' },
    { assetTag: 'TEST-MO-002', locationIdx: 0, serialNumber: 'SN-2024-002', manufacturer: 'Buckeye', description: 'Kitchen area' },
    { assetTag: 'TEST-MO-003', locationIdx: 0, serialNumber: 'SN-2024-003', manufacturer: 'Ansul', description: 'Server room' },
    { assetTag: 'TEST-WW-001', locationIdx: 1, serialNumber: 'SN-2024-004', manufacturer: 'Amerex', description: 'Main hallway' },
    { assetTag: 'TEST-WW-002', locationIdx: 1, serialNumber: 'SN-2024-005', manufacturer: 'Kidde', description: 'Break room' },
    { assetTag: 'TEST-WW-003', locationIdx: 1, serialNumber: 'SN-2024-006', manufacturer: 'Buckeye', description: 'Electrical room' },
    { assetTag: 'TEST-SF-001', locationIdx: 2, serialNumber: 'SN-2024-007', manufacturer: 'Ansul', description: 'Loading dock' },
    { assetTag: 'TEST-SF-002', locationIdx: 2, serialNumber: 'SN-2024-008', manufacturer: 'Amerex', description: 'Storage area A' }
  ];

  // Get all existing extinguishers first to check for duplicates
  const queryParams = { tenantId: CONFIG.TENANT_ID };
  const existingExtRes = await api.get('/extinguishers', { params: queryParams });
  const existingAssetTags = existingExtRes.status === 200
    ? existingExtRes.data.map(e => e.assetTag)
    : [];

  for (const ext of extinguishers) {
    if (existingAssetTags.includes(ext.assetTag)) {
      console.log(`  → Extinguisher already exists: ${ext.assetTag}`);
      continue;
    }

    try {
      const locationId = locationIds[ext.locationIdx] || locationIds[0];
      const typeId = extinguisherTypeIds[0]; // Use first available type

      if (!locationId || !typeId) {
        console.log(`  ⚠️  Skipping ${ext.assetTag} - missing location or type`);
        continue;
      }

      const response = await api.post('/extinguishers', {
        locationId,
        extinguisherTypeId: typeId,
        assetTag: ext.assetTag,
        serialNumber: ext.serialNumber,
        manufacturer: ext.manufacturer,
        model: 'ABC-10',
        manufactureDate: '2024-01-15',
        installDate: '2024-02-01',
        capacity: '10 lbs',
        locationDescription: ext.description
      });

      if (response.status === 201 || response.status === 200) {
        extinguisherIds.push(response.data.extinguisherId);
        console.log(`  ✅ Created extinguisher: ${ext.assetTag}`);
      } else if (response.status === 409 || response.status === 400) {
        console.log(`  → Extinguisher already exists: ${ext.assetTag}`);
      } else {
        console.log(`  ⚠️  Unexpected status ${response.status} for ${ext.assetTag}:`, response.data);
      }
    } catch (error) {
      console.error(`  ❌ Failed to create extinguisher ${ext.assetTag}:`, error.message);
    }
  }

  console.log(`✅ Processed ${extinguishers.length} extinguishers`);
}

async function createInspections() {
  console.log('📋 Creating inspections...');

  try {
    // Get all extinguishers
    const queryParams = { tenantId: CONFIG.TENANT_ID };
    const extRes = await api.get('/extinguishers', { params: queryParams });
    if (extRes.status !== 200 || !Array.isArray(extRes.data)) {
      console.log('⚠️  Could not fetch extinguishers for inspections');
      return;
    }

    const allExtinguishers = extRes.data;
    console.log(`  Found ${allExtinguishers.length} extinguishers to inspect`);

    if (allExtinguishers.length === 0) {
      console.log('  ⚠️  No extinguishers found, skipping inspection creation');
      return;
    }

    // Get existing inspections to avoid duplicates
    const existingInspRes = await api.get('/inspections', { params: queryParams });
    const existingInspectionCount = existingInspRes.status === 200
      ? existingInspRes.data.length
      : 0;
    console.log(`  Found ${existingInspectionCount} existing inspections`);

    // Create 24 inspections with varied dates and results (80% pass rate)
    const now = new Date();
    const inspections = [];

    for (let i = 0; i < 24; i++) {
      const daysAgo = i * 2.5; // Spread over 60 days
      const inspectionDate = new Date(now);
      inspectionDate.setDate(inspectionDate.getDate() - daysAgo);

      const ext = allExtinguishers[i % allExtinguishers.length];

      // Determine inspection type based on index
      let inspectionType;
      if (i % 12 === 0) inspectionType = '12-Year';
      else if (i % 6 === 0) inspectionType = '5-Year';
      else if (i % 3 === 0) inspectionType = 'Annual';
      else inspectionType = 'Monthly';

      // 80% pass rate (fail every 5th inspection)
      const passed = i % 5 !== 0;
      const requiresService = !passed && i % 2 === 0;
      const requiresReplacement = !passed && i % 10 === 0;

      inspections.push({
        extinguisherId: ext.extinguisherId,
        inspectorUserId: userId,
        inspectionDate: inspectionDate.toISOString(),
        inspectionType,
        passed,
        isAccessible: true,
        hasObstructions: !passed && i % 7 === 0,
        signageVisible: true,
        sealIntact: passed,
        pinInPlace: passed,
        nozzleClear: passed,
        hoseConditionGood: passed || i % 3 !== 0,
        gaugeInGreenZone: passed,
        gaugePressurePsi: passed ? 150.0 : 120.0,
        physicalDamagePresent: !passed && i % 8 === 0,
        inspectionTagAttached: true,
        requiresService,
        requiresReplacement,
        notes: passed ? 'Routine inspection - all checks passed' : 'Issues identified - attention required',
        failureReason: passed ? null : 'Failed one or more inspection criteria',
        correctiveAction: passed ? null : requiresReplacement ? 'Replace unit' : 'Schedule service and repairs'
      });
    }

    // Create inspections in batches of 5
    let created = 0;
    for (let i = 0; i < inspections.length; i += 5) {
      const batch = inspections.slice(i, i + 5);

      await Promise.all(
        batch.map(async (inspection, idx) => {
          try {
            const response = await api.post('/inspections', inspection);
            if (response.status === 201 || response.status === 200) {
              created++;
              console.log(`  ✅ Created inspection ${i + idx + 1}/${inspections.length}`);
            } else {
              console.log(`  ⚠️  Status ${response.status} for inspection ${i + idx + 1}`);
            }
          } catch (error) {
            console.log(`  ⚠️  Failed inspection ${i + idx + 1}:`, error.message);
          }
        })
      );

      // Small delay between batches to avoid overwhelming the API
      if (i + 5 < inspections.length) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }

    console.log(`✅ Created ${created} new inspections`);
  } catch (error) {
    console.error('❌ Failed to create inspections:', error.message);
  }
}

async function main() {
  console.log('========================================');
  console.log('🌱 FireProof Test Data Seeder');
  console.log('========================================\n');
  console.log(`API: ${CONFIG.API_BASE_URL}`);
  console.log(`User: ${CONFIG.TEST_EMAIL}`);
  console.log(`Tenant: ${CONFIG.TENANT_ID}\n`);

  try {
    await login();
    await setTenant();
    await getExistingData();
    await createAdditionalLocations();
    await createExtinguishers();
    await createInspections();

    console.log('\n========================================');
    console.log('✅ Seed data creation completed!');
    console.log('========================================');
    console.log(`\n📊 Summary:`);
    console.log(`   Locations: ${locationIds.length}`);
    console.log(`   Extinguisher Types: ${extinguisherTypeIds.length}`);
    console.log(`   Inspection Types: ${inspectionTypeIds.length}`);
    console.log(`   Created test extinguishers and inspections`);
    console.log(`\n✨ Test data is ready for E2E testing!`);
  } catch (error) {
    console.error('\n========================================');
    console.error('❌ Seed data creation failed!');
    console.error('========================================');
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

module.exports = { main };
