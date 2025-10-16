const axios = require('axios');
const api = axios.create({
  baseURL: 'http://localhost:7001/api',
  validateStatus: () => true
});

async function check() {
  const loginResp = await api.post('/authentication/login', {
    email: 'chris@servicevision.net',
    password: 'Gv51076'
  });
  
  const token = loginResp.data.accessToken;
  api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  api.defaults.headers.common['X-Tenant-ID'] = '634f2b52-d32a-46dd-a045-d158e793adcb';
  
  console.log('Checking ExtinguisherTypes...');
  const extResp = await api.get('/ExtinguisherTypes?tenantId=634f2b52-d32a-46dd-a045-d158e793adcb');
  console.log(`Status: ${extResp.status}`);
  console.log(`Data type: ${typeof extResp.data}, isArray: ${Array.isArray(extResp.data)}`);
  console.log(`Count: ${Array.isArray(extResp.data) ? extResp.data.length : 'N/A'}`);
  
  console.log('\nChecking InspectionTypes...');
  const inspResp = await api.get('/InspectionTypes');
  console.log(`Status: ${inspResp.status}`);
  console.log(`Data type: ${typeof inspResp.data}, isArray: ${Array.isArray(inspResp.data)}`);
  console.log(`Count: ${Array.isArray(inspResp.data) ? inspResp.data.length : 'N/A'}`);
  if (inspResp.data.length > 0) {
    console.log(`First item:`, JSON.stringify(inspResp.data[0]));
  }
}

check();
