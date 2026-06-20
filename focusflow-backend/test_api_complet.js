const http = require('http');

const PORT = 3000;

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

function assert(condition, message) {
  if (!condition) {
    throw new Error(`❌ ASSERTION FAILED: ${message}`);
  }
}

async function runComprehensiveTests() {
  console.log('=============================================');
  console.log('🚀 DÉMARRAGE DU TEST DU PARCOURS COMPLET API');
  console.log('=============================================\n');

  let token = '';
  let taskIds = [];
  const email = `samba_${Date.now()}@test.com`;
  const password = 'mySecretPassword123!';

  try {
    // ----------------------------------------------------------------------
    // ÉTAPE 1 : GESTION DES UTILISATEURS (AUTH)
    // ----------------------------------------------------------------------
    console.log('--- ÉTAPE 1 : AUTHENTIFICATION ---');
    
    // 1A. Inscription valide
    process.stdout.write('1A. Création de compte... ');
    let res = await request('POST', '/auth/register', { email, password, name: 'Samba' });
    assert(res.status === 201, `Status attendu 201, reçu ${res.status}`);
    console.log('✅ OK');

    // 1B. Inscription avec le même email (Doit échouer)
    process.stdout.write('1B. Création avec email doublon (Doit échouer)... ');
    res = await request('POST', '/auth/register', { email, password, name: 'Samba 2' });
    assert(res.status === 400, `Status attendu 400, reçu ${res.status}`);
    console.log('✅ OK (Bloqué avec succès)');

    // 1C. Connexion avec mauvais mot de passe
    process.stdout.write('1C. Login avec mauvais mot de passe... ');
    res = await request('POST', '/auth/login', { email, password: 'wrongpassword' });
    assert(res.status === 401, `Status attendu 401, reçu ${res.status}`);
    console.log('✅ OK (Accès refusé)');

    // 1D. Connexion réussie
    process.stdout.write('1D. Login avec bons identifiants... ');
    res = await request('POST', '/auth/login', { email, password });
    assert(res.status === 200, `Status attendu 200, reçu ${res.status}`);
    assert(res.data.token, 'Le token JWT est manquant');
    token = res.data.token;
    console.log('✅ OK (Token reçu)');


    // ----------------------------------------------------------------------
    // ÉTAPE 2 : GESTION DES TÂCHES
    // ----------------------------------------------------------------------
    console.log('\n--- ÉTAPE 2 : GESTION DES TÂCHES ---');

    // 2A. Récupération des tâches (Doit être vide)
    process.stdout.write('2A. Vérification des tâches initiales... ');
    res = await request('GET', '/tasks', null, token);
    assert(res.status === 200, `Status attendu 200, reçu ${res.status}`);
    assert(Array.isArray(res.data) && res.data.length === 0, 'La liste devrait être vide');
    console.log('✅ OK (0 tâche)');

    // 2B. Création de multiples tâches
    process.stdout.write('2B. Création de 3 tâches (Basse, Moyenne, Haute)... ');
    const t1 = await request('POST', '/tasks', { title: 'Apprendre Flutter', priority: 'high' }, token);
    const t2 = await request('POST', '/tasks', { title: 'Faire du sport', priority: 'medium' }, token);
    const t3 = await request('POST', '/tasks', { title: 'Lire un livre', priority: 'low' }, token);
    
    assert(t1.status === 201 && t2.status === 201 && t3.status === 201, 'Erreur lors de la création');
    taskIds = [t1.data.id, t2.data.id, t3.data.id];
    console.log('✅ OK');

    // 2C. Vérification du nombre de tâches
    process.stdout.write('2C. Récupération des 3 tâches... ');
    res = await request('GET', '/tasks', null, token);
    assert(res.data.length === 3, `Attendu 3 tâches, reçu ${res.data.length}`);
    console.log('✅ OK');

    // 2D. Modification d'une tâche (Marquer comme terminée)
    process.stdout.write('2D. Marquer la première tâche comme terminée... ');
    res = await request('PUT', `/tasks/${taskIds[0]}`, { isCompleted: true }, token);
    assert(res.status === 200, `Status attendu 200, reçu ${res.status}`);
    assert(res.data.isCompleted === true, 'La tâche n\'a pas été marquée comme terminée');
    console.log('✅ OK');


    // ----------------------------------------------------------------------
    // ÉTAPE 3 : MINUTEUR ET SESSIONS (POMODORO)
    // ----------------------------------------------------------------------
    console.log('\n--- ÉTAPE 3 : SESSIONS POMODORO ---');

    // 3A. Enregistrer une session de 25 min liée à une tâche
    process.stdout.write('3A. Enregistrement d\'une session Pomodoro (25min) liée à la tâche 2... ');
    res = await request('POST', '/sessions', {
      durationMs: 25 * 60 * 1000, // 25 minutes
      startTime: new Date(Date.now() - 25 * 60 * 1000).toISOString(),
      endTime: new Date().toISOString(),
      taskId: taskIds[1]
    }, token);
    assert(res.status === 201, `Status attendu 201, reçu ${res.status}`);
    console.log('✅ OK');

    // 3B. Enregistrer une session libre (sans tâche)
    process.stdout.write('3B. Enregistrement d\'une session Pomodoro libre... ');
    res = await request('POST', '/sessions', {
      durationMs: 15 * 60 * 1000, // 15 minutes
      startTime: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
      endTime: new Date().toISOString()
    }, token);
    assert(res.status === 201, `Status attendu 201, reçu ${res.status}`);
    console.log('✅ OK');

    // 3C. Récupérer les statistiques
    process.stdout.write('3C. Récupération de l\'historique des sessions... ');
    res = await request('GET', '/sessions', null, token);
    assert(res.status === 200, `Status attendu 200, reçu ${res.status}`);
    assert(res.data.length === 2, `Attendu 2 sessions, reçu ${res.data.length}`);
    console.log('✅ OK (2 sessions trouvées)');


    // ----------------------------------------------------------------------
    // ÉTAPE 4 : NETTOYAGE
    // ----------------------------------------------------------------------
    console.log('\n--- ÉTAPE 4 : NETTOYAGE (SUPPRESSION) ---');

    process.stdout.write('4A. Suppression de la première tâche... ');
    res = await request('DELETE', `/tasks/${taskIds[0]}`, null, token);
    assert(res.status === 200, `Status attendu 200, reçu ${res.status}`);
    console.log('✅ OK');

    process.stdout.write('4B. Vérification finale (Il doit rester 2 tâches)... ');
    res = await request('GET', '/tasks', null, token);
    assert(res.data.length === 2, `Attendu 2 tâches, reçu ${res.data.length}`);
    console.log('✅ OK');

    console.log('\n=============================================');
    console.log('🏆 SUCCÈS TOTAL : LE PARCOURS COMPLET FONCTIONNE PARFAITEMENT !');
    console.log('=============================================');

  } catch (error) {
    console.log('\n❌ ÉCHEC DU TEST !');
    console.error(error.message);
  }
}

runComprehensiveTests();
