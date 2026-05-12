const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const cron = require('node-cron');
const swaggerSpec = require('./shares/config/swagger.js');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

// Connexion DB
const db = require('./shares/database/db');

// Routes centralisées
const routes = require('./routes');

// Middleware d'erreur global
const { errorHandler } = require('./shares/middleware/errorHandler');

// Jobs CRON
const { runExpireSubscriptions } = require('./jobs/subscription.job');

const logger = require('./shares/utils/logger');

const app = express();

// ═══════════════════════════════════════════════
// SÉCURITÉ ET MIDDLEWARES
// ═══════════════════════════════════════════════

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Trop de tentatives. Réessayez dans 15 minutes.',
});
app.use('/api', limiter);

// ═══════════════════════════════════════════════
// SWAGGER UI
// ═══════════════════════════════════════════════

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Endpoint JSON brut du swagger
app.get('/api-docs.json', (req, res) => res.json(swaggerSpec));


/*
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});
*/

// ═══════════════════════════════════════════════
// ROUTES
// ═══════════════════════════════════════════════

/**
 * @swagger
 * /api/v1/health:
 *   get:
 *     summary: Vérifie l'état du serveur
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Le serveur est opérationnel
 */
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'API opérationnelle',
    timestamp: new Date().toISOString(),
  });
});

// Montage de toutes les routes modules
app.use('/api/v1', routes);

// ═══════════════════════════════════════════════
// GESTION DES ERREURS
// ═══════════════════════════════════════════════

// 404 — Route non trouvée
app.all(/.*/, (req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Impossible de trouver ${req.originalUrl} sur ce serveur.`,
  });
});

// Middleware global d'erreur
app.use(errorHandler);

// ═══════════════════════════════════════════════
// JOB CRON — Expiration automatique
// ═══════════════════════════════════════════════

// Exécuter toutes les heures à minute 0
cron.schedule('0 * * * *', () => {
  runExpireSubscriptions();
});

logger.info('⏰ Job CRON d\'expiration planifié (toutes les heures)');

// ═══════════════════════════════════════════════
// LANCEMENT DU SERVEUR
// ═══════════════════════════════════════════════

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  logger.info(`🚀 Serveur démarré sur le port ${PORT}`);
  logger.info(`📚 Swagger UI disponible sur http://localhost:${PORT}/api-docs`);
});