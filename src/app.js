const express = require('express');
const helmet = require('helmet');
const xss = require('xss-clean');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
require('dotenv').config();

// Vérification de la connexion DB dès le lancement
const db = require('./shares/database/config');

const app = express();

// --- SÉCURITÉ ET MIDDLEWARES ---

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));
app.use(xss());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 100, 
  message: "Trop de tentatives. Réessayez dans 15 minutes."
});
app.use('/api', limiter);

// --- ROUTES ---

// Route de santé (Health Check)
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API opérationnelle' });
});

// --- GESTION DES ERREURS 404 (Version Express 5) ---
// On utilise '/*' au lieu de '*' pour éviter l'erreur PathError
app.all(/.*/, (req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Impossible de trouver ${req.originalUrl} sur ce serveur.`
  });
});

// --- LANCEMENT ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
});