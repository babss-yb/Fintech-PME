require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_123';

// ==========================================
// AUTHENTICATION
// ==========================================

app.post('/api/auth/register', async (req, res) => {
  try {
    console.log('=== REGISTER ATTEMPT ===');
    console.log('Body:', req.body);
    let { email, password, name } = req.body;
    if (!email || !password || !name) {
      console.log('Validation failed: Missing fields');
      return res.status(400).json({ errorMessage: 'Tous les champs sont obligatoires.' });
    }
    email = email.toLowerCase().trim();
    
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      console.log(`Validation failed: Email ${email} already exists`);
      return res.status(400).json({ errorMessage: 'Cet email est déjà utilisé. Veuillez vous connecter.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashedPassword, name }
    });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    let { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ errorMessage: 'Email et mot de passe obligatoires.' });
    }
    email = email.toLowerCase().trim();
    
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(401).json({ errorMessage: 'Identifiants invalides.' });
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      return res.status(401).json({ errorMessage: 'Identifiants invalides.' });
    }

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.status(200).json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

// Middleware to protect routes
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ errorMessage: 'Non autorisé. Token manquant.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ errorMessage: 'Token invalide ou expiré.' });
  }
};

// ==========================================
// TASKS CRUD (Protected)
// ==========================================

app.get('/api/tasks', verifyToken, async (req, res) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { userId: req.userId },
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.post('/api/tasks', verifyToken, async (req, res) => {
  try {
    const { title, description, priority, category } = req.body;
    const task = await prisma.task.create({
      data: {
        title,
        description,
        priority: priority || 'medium',
        category,
        userId: req.userId
      }
    });
    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.put('/api/tasks/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, priority, category, isCompleted } = req.body;
    
    // Ensure the task belongs to the user
    const existing = await prisma.task.findUnique({ where: { id: parseInt(id) } });
    if (!existing || existing.userId !== req.userId) {
      return res.status(403).json({ errorMessage: 'Accès refusé.' });
    }

    const task = await prisma.task.update({
      where: { id: parseInt(id) },
      data: { title, description, priority, category, isCompleted }
    });
    res.status(200).json(task);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.delete('/api/tasks/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const existing = await prisma.task.findUnique({ where: { id: parseInt(id) } });
    if (!existing || existing.userId !== req.userId) {
      return res.status(403).json({ errorMessage: 'Accès refusé.' });
    }

    await prisma.task.delete({
      where: { id: parseInt(id) }
    });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

// ==========================================
// POMODORO SESSIONS (Protected)
// ==========================================

app.get('/api/sessions', verifyToken, async (req, res) => {
  try {
    const sessions = await prisma.pomodoroSession.findMany({
      where: { userId: req.userId },
      orderBy: { endTime: 'desc' },
      include: { task: true }
    });
    res.status(200).json(sessions);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

app.post('/api/sessions', verifyToken, async (req, res) => {
  try {
    const { durationMs, startTime, endTime, taskId, status } = req.body;
    
    if (taskId) {
      const existingTask = await prisma.task.findUnique({ where: { id: parseInt(taskId) } });
      if (!existingTask || existingTask.userId !== req.userId) {
         return res.status(403).json({ errorMessage: 'Accès refusé à cette tâche.' });
      }
    }

    const session = await prisma.pomodoroSession.create({
      data: {
        durationMs,
        startTime: new Date(startTime),
        endTime: new Date(endTime),
        taskId: taskId ? parseInt(taskId) : null,
        userId: req.userId,
        status: status || 'completed'
      }
    });
    res.status(201).json(session);
  } catch (error) {
    res.status(500).json({ errorMessage: error.message });
  }
});

// ==========================================
// SERVER START
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`FocusFlow Backend running on http://localhost:${PORT}`);
});
