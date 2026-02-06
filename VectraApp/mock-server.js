const http = require('http');

const PORT = 3000;

// Mock user database
const users = [];
let tokenCounter = 1;

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Content-Type', 'application/json');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    const data = body ? JSON.parse(body) : {};
    
    console.log(`${req.method} ${req.url}`, data);

    // Routes
    if (req.url === '/auth/register/rider' && req.method === 'POST') {
      // Register
      const user = {
        id: `user_${Date.now()}`,
        email: data.email,
        phone: data.phone,
        fullName: data.fullName,
        role: 'RIDER',
        isVerified: false,
        createdAt: new Date().toISOString(),
      };
      users.push({ ...user, password: data.password });
      
      res.writeHead(201);
      res.end(JSON.stringify({ status: 'created', user }));
    }
    else if (req.url === '/auth/login' && req.method === 'POST') {
      // Login
      const user = users.find(u => u.email === data.email && u.password === data.password);
      
      if (!user) {
        // For demo: auto-create user if not found
        const newUser = {
          id: `user_${Date.now()}`,
          email: data.email,
          phone: '+1234567890',
          fullName: 'Demo User',
          role: 'RIDER',
          isVerified: true,
          createdAt: new Date().toISOString(),
        };
        users.push({ ...newUser, password: data.password });
        
        const token = `token_${tokenCounter++}_${Date.now()}`;
        res.writeHead(200);
        res.end(JSON.stringify({
          status: 'ok',
          user: newUser,
          accessToken: token,
          refreshToken: `refresh_${token}`,
          refreshTokenId: `rtid_${Date.now()}`,
        }));
        return;
      }

      const { password, ...safeUser } = user;
      const token = `token_${tokenCounter++}_${Date.now()}`;
      
      res.writeHead(200);
      res.end(JSON.stringify({
        status: 'ok',
        user: safeUser,
        accessToken: token,
        refreshToken: `refresh_${token}`,
        refreshTokenId: `rtid_${Date.now()}`,
      }));
    }
    else if (req.url === '/auth/logout' && req.method === 'POST') {
      res.writeHead(200);
      res.end(JSON.stringify({ status: 'ok' }));
    }
    else if (req.url === '/auth/refresh' && req.method === 'POST') {
      const token = `token_${tokenCounter++}_${Date.now()}`;
      res.writeHead(200);
      res.end(JSON.stringify({
        status: 'ok',
        accessToken: token,
        refreshToken: `refresh_${token}`,
        refreshTokenId: `rtid_${Date.now()}`,
      }));
    }
    else if (req.url === '/profile/me' && req.method === 'GET') {
      res.writeHead(200);
      res.end(JSON.stringify({
        id: 'user_demo',
        email: 'demo@vectra.com',
        fullName: 'Demo User',
        role: 'RIDER',
        isVerified: true,
      }));
    }
    else if (req.url === '/auth/me/permissions' && req.method === 'GET') {
      res.writeHead(200);
      res.end(JSON.stringify({
        status: 'ok',
        user: { id: 'user_demo', role: 'RIDER' },
        permissions: ['ride:request', 'ride:cancel', 'profile:read', 'profile:update'],
      }));
    }
    else {
      res.writeHead(404);
      res.end(JSON.stringify({ error: 'Not found', path: req.url }));
    }
  });
});

server.listen(PORT, () => {
  console.log(`\n🚀 Mock Server running at http://localhost:${PORT}`);
  console.log('\nAvailable endpoints:');
  console.log('  POST /auth/register/rider - Register new rider');
  console.log('  POST /auth/login - Login (auto-creates user for demo)');
  console.log('  POST /auth/logout - Logout');
  console.log('  POST /auth/refresh - Refresh token');
  console.log('  GET  /profile/me - Get profile');
  console.log('\n📱 Now run your Flutter app and test!\n');
});
