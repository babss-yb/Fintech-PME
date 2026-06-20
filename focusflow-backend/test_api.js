const http = require('http');

const PORT = 3000;
const BASE_URL = `http://localhost:${PORT}/api`;

function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: PORT,
      path: `/api${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: data ? JSON.parse(data) : null });
        } catch(e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('🚀 Démarrage des tests E2E de l\'API FocusFlow...');
  let token = '';
  let taskId = null;

  try {
    // 1. Inscription
    console.log('\n--- Test 1: Inscription ---');
    const randomEmail = `test_${Date.now()}@example.com`;
    let res = await request('POST', '/auth/register', {
      email: randomEmail,
      password: 'password123',
      name: 'Testeur'
    });
    console.log(`Status: ${res.status}`);
    if (res.status === 201 && res.data.token) {
      console.log('✅ Inscription réussie. Token reçu.');
      token = res.data.token;
    } else {
      console.error('❌ Echec de l\'inscription:', res.data);
      return;
    }

    // 2. Connexion
    console.log('\n--- Test 2: Connexion ---');
    res = await request('POST', '/auth/login', {
      email: randomEmail,
      password: 'password123'
    });
    console.log(`Status: ${res.status}`);
    if (res.status === 200 && res.data.token) {
      console.log('✅ Connexion réussie.');
    } else {
      console.error('❌ Echec de la connexion:', res.data);
      return;
    }

    // 3. Test de route protégée SANS token (Doit échouer)
    console.log('\n--- Test 3: Accès protégé sans token ---');
    res = await request('GET', '/tasks');
    console.log(`Status: ${res.status}`);
    if (res.status === 401) {
      console.log('✅ Accès refusé (Comportement attendu).');
    } else {
      console.error('❌ L\'accès aurait dû être refusé.');
      return;
    }

    // 4. Création d'une tâche AVEC token
    console.log('\n--- Test 4: Création d\'une tâche ---');
    res = await request('POST', '/tasks', {
      title: 'Tâche de test automatisé',
      priority: 'high'
    }, token);
    console.log(`Status: ${res.status}`);
    if (res.status === 201 && res.data.id) {
      console.log('✅ Tâche créée avec succès:', res.data.title);
      taskId = res.data.id;
    } else {
      console.error('❌ Echec de la création de tâche:', res.data);
      return;
    }

    // 5. Récupération des tâches
    console.log('\n--- Test 5: Récupération des tâches ---');
    res = await request('GET', '/tasks', null, token);
    console.log(`Status: ${res.status}`);
    if (res.status === 200 && Array.isArray(res.data) && res.data.length > 0) {
      console.log(`✅ Tâches récupérées: ${res.data.length}`);
    } else {
      console.error('❌ Echec de la récupération des tâches:', res.data);
      return;
    }

    // 6. Création d'une session Pomodoro
    console.log('\n--- Test 6: Création de session Pomodoro ---');
    res = await request('POST', '/sessions', {
      durationMs: 1500000,
      startTime: new Date(Date.now() - 1500000).toISOString(),
      endTime: new Date().toISOString(),
      taskId: taskId
    }, token);
    console.log(`Status: ${res.status}`);
    if (res.status === 201) {
      console.log('✅ Session Pomodoro enregistrée avec succès.');
    } else {
      console.error('❌ Echec de l\'enregistrement de session:', res.data);
      return;
    }

    // 7. Suppression de la tâche
    console.log('\n--- Test 7: Suppression de la tâche ---');
    res = await request('DELETE', `/tasks/${taskId}`, null, token);
    console.log(`Status: ${res.status}`);
    if (res.status === 200) {
      console.log('✅ Tâche supprimée avec succès.');
    } else {
      console.error('❌ Echec de la suppression de tâche:', res.data);
      return;
    }

    console.log('\n🎉 TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS ! L\'API FONCTIONNE PARFAITEMENT !');

  } catch (error) {
    console.error('Erreur inattendue:', error);
  }
}

runTests();
