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
  api.defaults.headers.common['Authorization'] = 'Bearer ' + token;
  api.defaults.headers.common['X-Tenant-ID'] = '634f2b52-d32a-46dd-a045-d158e793adcb';

  console.log('Checking InspectionTypes...');
  const inspResp = await api.get('/InspectionTypes');
  console.log('Status:', inspResp.status);
  console.log('Count:', Array.isArray(inspResp.data) ? inspResp.data.length : 0);
  if (Array.isArray(inspResp.data) && inspResp.data.length > 0) {
    console.log('Types:', inspResp.data.map(t => t.typeName).join(', '));
  }
}

check();
