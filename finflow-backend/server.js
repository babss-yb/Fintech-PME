require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(express.json());

// ==========================================
// AUTHENTICATION
// ==========================================

app.post('/api/auth/register', async (req, res) => {
  try {
    const { firstName, lastName, email, phone, password, companyName } = req.body;
    
    // Check if user exists
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(400).json({ success: false, errorMessage: 'Cet email est déjà utilisé.' });
    }

    const user = await prisma.user.create({
      data: { firstName, lastName, email, phone, password, companyName }
    });

    res.status(201).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, errorMessage: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || user.password !== password) {
      return res.status(401).json({ success: false, errorMessage: 'Email ou mot de passe invalide.' });
    }

    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, errorMessage: error.message });
  }
});

app.put('/api/auth/profile', async (req, res) => {
  try {
    const { id, firstName, lastName, email, phone, companyName } = req.body;
    
    const user = await prisma.user.update({
      where: { id },
      data: { firstName, lastName, email, phone, companyName }
    });

    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, errorMessage: error.message });
  }
});

// ==========================================
// PROJECTS
// ==========================================

// Get all projects for a specific user
app.get('/api/projects', async (req, res) => {
  try {
    // Dans une vraie API, l'userId serait extrait d'un token JWT
    // Pour simplifier, on prend tous les projets
    const projects = await prisma.project.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json(projects);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.post('/api/projects', async (req, res) => {
  try {
    const { title, description, userId } = req.body;
    const project = await prisma.project.create({
      data: { title, description, userId: userId || "dummy-user" }
    });
    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.put('/api/projects/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description } = req.body;
    const project = await prisma.project.update({
      where: { id: parseInt(id) },
      data: { title, description }
    });
    res.status(200).json(project);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.delete('/api/projects/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.project.delete({
      where: { id: parseInt(id) }
    });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

// ==========================================
// SERVER START
// ==========================================
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
