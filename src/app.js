const express = require('express');
const helmet = require('helmet');
const xss = require('xss-clean');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
require('dotenv').config();

// Vérification de la connexion DB dès le lancement
const pool = require('./shared/database/config');

const app = express();

// --- SÉCURITÉ ET MIDDLEWARES ---

// 1. Protection des en-têtes HTTP
app.use(helmet());

// 2. Autorise les requêtes depuis ton futur Front-end
app.use(cors());

// 3. Analyse du JSON (limité à 10kb pour éviter les surcharges)
app.use(express.json({ limit: '10kb' }));

// 4. Nettoyage contre les injections de scripts (XSS)
app.use(xss());

// 5. Limitation du nombre de requêtes par IP (Anti-Brute Force)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limite chaque IP à 100 requêtes
  message: "Trop de tentatives. Réessayez dans 15 minutes."
});
app.use('/api', limiter);

// --- IMPORTATION DES ROUTES (À décommenter au fur et à mesure) ---

// const escortRoutes = require('./modules/escort/escort.routes');
// const adminRoutes = require('./modules/admin/admin.routes');

// --- MONTAGE DES ROUTES ---

// Route de santé (Health Check)
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API opérationnelle' });
});

// app.use('/api/v1/escorts', escortRoutes);
// app.use('/api/v1/admins', adminRoutes);

// --- GESTION DES ERREURS 404 ---
app.all('*', (req, res) => {
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