const axios = require('axios');
const api = axios.create({
  baseURL: 'http://localhost:7001/api',
  validateStatus: () => true
});

async function seedInspections() {
  // Login
  console.log('Logging in...');
  const loginResp = await api.post('/authentication/login', {
    email: 'chris@servicevision.net',
    password: 'Gv51076'
  });

  if (loginResp.status !== 200) {
    console.error('Login failed:', loginResp.status, loginResp.data);
    return;
  }

  const token = loginResp.data.accessToken;
  api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  api.defaults.headers.common['X-Tenant-ID'] = '634f2b52-d32a-46dd-a045-d158e793adcb';

  console.log('✓ Logged in successfully\n');

  // Get Extinguishers
  console.log('Fetching Extinguishers...');
  const extResp = await api.get('/Extinguishers');
  console.log('Extinguishers response status:', extResp.status);
  console.log('Extinguishers response data:', JSON.stringify(extResp.data).substring(0, 500));
  console.log('Is array?', Array.isArray(extResp.data));
  console.log('Length:', extResp.data?.length);

  if (extResp.status !== 200 || !Array.isArray(extResp.data) || extResp.data.length === 0) {
    console.error('Failed to get Extinguishers - empty result or error');
    return;
  }
  const extinguishers = extResp.data;
  console.log(`✓ Found ${extinguishers.length} extinguishers\n`);

  // Get InspectionTypes
  console.log('Fetching InspectionTypes...');
  const inspTypeResp = await api.get('/InspectionTypes');
  if (inspTypeResp.status !== 200 || !Array.isArray(inspTypeResp.data) || inspTypeResp.data.length === 0) {
    console.error('Failed to get InspectionTypes:', inspTypeResp.status);
    return;
  }
  const inspectionTypes = inspTypeResp.data;
  const monthlyType = inspectionTypes.find(t => t.typeName === 'Monthly Test');
  const annualType = inspectionTypes.find(t => t.typeName === 'Annual Test');
  console.log(`✓ Found ${inspectionTypes.length} inspection types\n`);

  if (!monthlyType) {
    console.error('Monthly Test inspection type not found');
    return;
  }

  // Create sample inspections
  console.log('Creating sample inspections...');

  const inspections = [
    {
      extinguisherId: extinguishers[0].extinguisherId,
      inspectionTypeId: monthlyType.inspectionTypeId,
      inspectionDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(), // 15 days ago
      isPressureGaugeNormal: true,
      isAccessible: true,
      isSignageVisible: true,
      isPinSealed: true,
      notes: 'Routine monthly inspection - all checks passed',
      inspectionStatus: 'Completed'
    },
    {
      extinguisherId: extinguishers[1]?.extinguisherId || extinguishers[0].extinguisherId,
      inspectionTypeId: monthlyType.inspectionTypeId,
      inspectionDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(), // 10 days ago
      isPressureGaugeNormal: true,
      isAccessible: true,
      isSignageVisible: true,
      isPinSealed: true,
      notes: 'Monthly inspection - unit in good condition',
      inspectionStatus: 'Completed'
    },
    {
      extinguisherId: extinguishers[2]?.extinguisherId || extinguishers[0].extinguisherId,
      inspectionTypeId: monthlyType.inspectionTypeId,
      inspectionDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days ago
      isPressureGaugeNormal: true,
      isAccessible: true,
      isSignageVisible: true,
      isPinSealed: true,
      notes: 'Monthly inspection - no issues found',
      inspectionStatus: 'Completed'
    }
  ];

  // Add annual inspection if type exists
  if (annualType && extinguishers[0]) {
    inspections.push({
      extinguisherId: extinguishers[0].extinguisherId,
      inspectionTypeId: annualType.inspectionTypeId,
      inspectionDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days ago
      isPressureGaugeNormal: true,
      isAccessible: true,
      isSignageVisible: true,
      isPinSealed: true,
      notes: 'Annual comprehensive inspection - passed all checks',
      inspectionStatus: 'Completed'
    });
  }

  let created = 0;
  for (const inspection of inspections) {
    const resp = await api.post('/Inspections', inspection);
    if (resp.status === 201 || resp.status === 200) {
      created++;
      console.log(`  ✓ Created inspection for extinguisher ${inspection.extinguisherId.substring(0, 8)}`);
    } else {
      console.log(`  ⚠️ Failed to create inspection: ${resp.status}`);
      console.log(`     Response:`, JSON.stringify(resp.data).substring(0, 200));
    }
  }

  console.log(`\n✓ Created ${created} of ${inspections.length} inspections`);

  // Summary
  const summaryResp = await api.get('/Inspections');
  console.log(`\nTotal inspections in database: ${Array.isArray(summaryResp.data) ? summaryResp.data.length : 0}`);
}

seedInspections().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
