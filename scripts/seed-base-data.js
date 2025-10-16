#!/usr/bin/env node
/**
 * Seed Base/System Data via API
 *
 * This script creates system-level reference data that is tenant-agnostic:
 * - ExtinguisherTypes (ABC, CO2, Water, etc.)
 * - InspectionTypes (Monthly, Annual, 5-Year, 12-Year, Hydrostatic)
 * - ChecklistTemplates (if needed)
 *
 * This should be run ONCE to set up the system before creating tenant-specific data.
 * It is idempotent - it can be run multiple times safely.
 *
 * Usage:
 *   node seed-base-data.js
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
  console.log('🔐 Logging in as SystemAdmin...');
  try {
    const response = await api.post('/authentication/login', {
      email: CONFIG.TEST_EMAIL,
      password: CONFIG.TEST_PASSWORD
    });

    if (response.status !== 200) {
      throw new Error(`Login failed with status ${response.status}: ${JSON.stringify(response.data)}`);
    }

    authToken = response.data.accessToken;
    setAuthHeaders();
    console.log('✅ Login successful!\n');
    return authToken;
  } catch (error) {
    console.error('❌ Login failed:', error.message);
    throw error;
  }
}

async function createExtinguisherTypes() {
  console.log('🧯 Creating Extinguisher Types...');

  const extinguisherTypes = [
    {
      typeCode: 'ABC',
      typeName: 'ABC Dry Chemical',
      description: 'Multi-purpose dry chemical extinguisher for Class A, B, and C fires',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 12
    },
    {
      typeCode: 'BC',
      typeName: 'BC Dry Chemical',
      description: 'Dry chemical extinguisher for Class B and C fires',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 12
    },
    {
      typeCode: 'CO2',
      typeName: 'Carbon Dioxide',
      description: 'CO2 extinguisher for Class B and C fires',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 5
    },
    {
      typeCode: 'H2O',
      typeName: 'Water',
      description: 'Water extinguisher for Class A fires only',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 5
    },
    {
      typeCode: 'FOAM',
      typeName: 'Foam',
      description: 'Foam extinguisher for Class A and B fires',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 5
    },
    {
      typeCode: 'K',
      typeName: 'Class K Kitchen',
      description: 'Wet chemical extinguisher for Class K fires (cooking oils/fats)',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 5
    },
    {
      typeCode: 'HALON',
      typeName: 'Halon 1211',
      description: 'Halon extinguisher for Class B and C fires (legacy)',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 12
    },
    {
      typeCode: 'CLEAN',
      typeName: 'Clean Agent',
      description: 'Clean agent extinguisher (Halon replacement) for Class B and C fires',
      monthlyInspectionRequired: true,
      annualInspectionRequired: true,
      hydrostaticTestYears: 12
    }
  ];

  let created = 0;
  let existing = 0;

  for (const type of extinguisherTypes) {
    try {
      const response = await api.post('/ExtinguisherTypes', type);

      if (response.status === 201 || response.status === 200) {
        created++;
        console.log(`  ✅ Created: ${type.typeName}`);
      } else if (response.status === 409 || response.status === 400) {
        existing++;
        console.log(`  → Already exists: ${type.typeName}`);
      } else {
        console.log(`  ⚠️  Unexpected status ${response.status} for ${type.typeName}`);
        console.log(`     Response:`, JSON.stringify(response.data));
      }
    } catch (error) {
      console.error(`  ❌ Failed to create ${type.typeName}:`, error.message);
    }
  }

  console.log(`✅ Extinguisher Types: ${created} created, ${existing} already existed\n`);
}

async function createInspectionTypes() {
  console.log('📋 Creating Inspection Types...');

  const inspectionTypes = [
    {
      typeName: 'Monthly',
      description: 'Monthly visual inspection as per NFPA 10',
      frequencyDays: 30,
      requiresServiceTechnician: false
    },
    {
      typeName: 'Annual',
      description: 'Annual maintenance inspection as per NFPA 10',
      frequencyDays: 365,
      requiresServiceTechnician: true
    },
    {
      typeName: '6-Year',
      description: '6-year maintenance inspection (internal examination for certain types)',
      frequencyDays: 2190, // 6 * 365
      requiresServiceTechnician: true
    },
    {
      typeName: '12-Year',
      description: '12-year hydrostatic test or extended service',
      frequencyDays: 4380, // 12 * 365
      requiresServiceTechnician: true
    },
    {
      typeName: 'Hydrostatic',
      description: 'Hydrostatic pressure test (frequency varies by extinguisher type)',
      frequencyDays: 1825, // 5 * 365 (varies: 5, 12 years)
      requiresServiceTechnician: true
    },
    {
      typeName: 'Recharge',
      description: 'Recharge after use or when pressure is low',
      frequencyDays: 0, // As needed
      requiresServiceTechnician: true
    }
  ];

  let created = 0;
  let existing = 0;

  for (const type of inspectionTypes) {
    try {
      const response = await api.post('/InspectionTypes', type);

      if (response.status === 201 || response.status === 200) {
        created++;
        console.log(`  ✅ Created: ${type.typeName}`);
      } else if (response.status === 409 || response.status === 400) {
        existing++;
        console.log(`  → Already exists: ${type.typeName}`);
      } else {
        console.log(`  ⚠️  Unexpected status ${response.status} for ${type.typeName}`);
      }
    } catch (error) {
      console.error(`  ❌ Failed to create ${type.typeName}:`, error.message);
    }
  }

  console.log(`✅ Inspection Types: ${created} created, ${existing} already existed\n`);
}

async function main() {
  console.log('========================================');
  console.log('🌱 FireProof Base Data Seeder');
  console.log('========================================\n');
  console.log('This script creates system-level reference data:');
  console.log('  - Extinguisher Types (ABC, CO2, Water, etc.)');
  console.log('  - Inspection Types (Monthly, Annual, etc.)\n');
  console.log(`API: ${CONFIG.API_BASE_URL}\n`);

  try {
    await login();
    await createExtinguisherTypes();
    await createInspectionTypes();

    console.log('========================================');
    console.log('✅ Base data creation completed!');
    console.log('========================================\n');
    console.log('System is now ready for tenant-specific data.');
    console.log('Run: node seed-test-data.js\n');
  } catch (error) {
    console.error('\n========================================');
    console.error('❌ Base data creation failed!');
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
