const http = require('http');

const baseUrl = 'http://localhost:3000/api';

async function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${baseUrl}${path}`);
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch(e) {
          resolve({ status: res.statusCode, data });
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
  console.log("--- DÉMARRAGE DES TESTS D'INTÉGRATION ---");
  
  // 1. REGISTER
  console.log("1. Test Inscription...");
  const registerRes = await request('POST', '/auth/register', {
    firstName: "Test",
    lastName: "User",
    email: `test${Date.now()}@example.com`,
    phone: "0123456789",
    password: "password123",
    companyName: "TestCorp"
  });
  console.log("Status:", registerRes.status);
  console.log("Data:", registerRes.data);
  
  if(registerRes.status !== 201) throw new Error("Échec de l'inscription");
  const user = registerRes.data.user;

  // 2. LOGIN
  console.log("\n2. Test Connexion...");
  const loginRes = await request('POST', '/auth/login', {
    email: user.email,
    password: "password123"
  });
  console.log("Status:", loginRes.status);
  
  if(loginRes.status !== 200) throw new Error("Échec de la connexion");

  // 3. CREATE PROJECT
  console.log("\n3. Test Création de projet...");
  const createProjRes = await request('POST', '/projects', {
    title: "Projet Alpha",
    description: "Ceci est un test",
    userId: user.id
  });
  console.log("Status:", createProjRes.status);
  
  if(createProjRes.status !== 201) throw new Error("Échec de création du projet");
  const projectId = createProjRes.data.id;

  // 4. GET PROJECTS
  console.log("\n4. Test Récupération des projets...");
  const getProjRes = await request('GET', '/projects');
  console.log("Status:", getProjRes.status);
  console.log("Nombre de projets:", getProjRes.data.length);
  
  if(getProjRes.status !== 200) throw new Error("Échec récupération des projets");

  // 5. UPDATE PROJECT
  console.log("\n5. Test Modification de projet...");
  const updateProjRes = await request('PUT', `/projects/${projectId}`, {
    title: "Projet Alpha - Modifié",
    description: "Ceci est une description modifiée"
  });
  console.log("Status:", updateProjRes.status);
  
  if(updateProjRes.status !== 200) throw new Error("Échec modification projet");

  // 6. DELETE PROJECT
  console.log("\n6. Test Suppression de projet...");
  const delProjRes = await request('DELETE', `/projects/${projectId}`);
  console.log("Status:", delProjRes.status);
  
  if(delProjRes.status !== 200) throw new Error("Échec suppression projet");

  console.log("\n✅ TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS !");
}

runTests().catch(console.error);
