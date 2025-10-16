const axios = require('axios');
const api = axios.create({
  baseURL: 'http://localhost:7001/api',
  validateStatus: () => true
});

async function check() {
  // Login
  const loginResp = await api.post('/authentication/login', {
    email: 'chris@servicevision.net',
    password: 'Gv51076'
  });
  
  const token = loginResp.data.accessToken;
  api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  api.defaults.headers.common['X-Tenant-ID'] = '634f2b52-d32a-46dd-a045-d158e793adcb';
  
  // Check ExtinguisherTypes
  const extTypesResp = await api.get('/ExtinguisherTypes?tenantId=634f2b52-d32a-46dd-a045-d158e793adcb');
  console.log(`ExtinguisherTypes: ${extTypesResp.data.length} found`);
  
  // Check InspectionTypes
  const inspTypesResp = await api.get('/InspectionTypes');
  console.log(`InspectionTypes: ${inspTypesResp.data.length} found`);
  
  // Check Locations
  const locsResp = await api.get('/Locations');
  console.log(`Locations: ${locsResp.data.length} found`);
}

check();
