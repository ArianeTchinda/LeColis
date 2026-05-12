const express = require('express');
const http = require('http'); // AJOUTÉ
const { Server } = require('socket.io');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const cron = require('node-cron');
const swaggerSpec = require('./shares/config/swagger.js');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

<<<<<<< HEAD
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
=======
// Initialisation Express
const app = express();

// CRÉATION DU SERVEUR HTTP (Indispensable pour Socket.io)
const server = http.createServer(app); 

// INITIALISATION SOCKET.IO
const io = new Server(server, {
  cors: {
    origin: "*", 
    methods: ["GET", "POST"]
  }
});

// --- SÉCURITÉ ET MIDDLEWARES ---
>>>>>>> origin/LAETITIA

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));


// Rendre "io" accessible dans tous tes controllers via req.io
app.use((req, res, next) => {
  req.io = io;
  next();
});

// LOGIQUE SOCKET.IO
io.on('connection', (socket) => {
  console.log('🔌 Un utilisateur connecté:', socket.id);

  socket.on('join_admin_room', () => {
    socket.join('admins');
    console.log('🛡️  Un admin a rejoint la room');
  });

  socket.on('join_escort_room', (escortId) => {
    socket.join(`escort_${escortId}`);
    console.log(`Escorte ${escortId} écoute ses notifications`);
  });
  socket.on('disconnect', () => {
    console.log('❌ Utilisateur déconnecté');
  });
});

// LIMITER LE NOMBRE DE REQUÊTES
const limiter = rateLimit({
<<<<<<< HEAD
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Trop de tentatives. Réessayez dans 15 minutes.',
=======
  windowMs: 15 * 60 * 1000, 
  max: 100, 
  message: { status: 'fail', message: "Trop de tentatives. Réessayez dans 15 minutes." }
>>>>>>> origin/LAETITIA
});
app.use('/api', limiter);

// ═══════════════════════════════════════════════
// SWAGGER UI
// ═══════════════════════════════════════════════

<<<<<<< HEAD
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Endpoint JSON brut du swagger
app.get('/api-docs.json', (req, res) => res.json(swaggerSpec));


/*
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
=======
// Import des routes (Une fois que tu les auras créées)
const adminRoutes = require('./modules/admin/admin.routes');
const signalisationRoutes = require('./modules/signalisation/signalisation.routes');
const notificationRoutes = require('./modules/notification/notification.routes');
const escortRoutes = require('./modules/escort/escort.routes');
const avisRoutes = require('./modules/avis/avis.routes');


// --- ROUTES ---

console.log('Vérification des chargements :');
console.log('- Admin:', typeof adminRoutes);
console.log('- Signalisation:', typeof signalisationRoutes);
console.log('- Notification:', typeof notificationRoutes);
console.log('- Escort:', typeof escortRoutes);
console.log('- Avis:', typeof avisRoutes);

// Utilisation sécurisée pour identifier la ligne exacte du crash
try { app.use('/api/v1/escorts', escortRoutes); } catch(e) { console.error('Crash sur Escorts'); }
try { app.use('/api/v1/avis', avisRoutes); } catch(e) { console.error('Crash sur Avis'); }
try { app.use('/api/v1/admins', adminRoutes); } catch(e) { console.error('Crash sur Admins'); }
try { app.use('/api/v1/signalisation', signalisationRoutes); } catch(e) { console.error('Crash sur Signalisation'); }
try { app.use('/api/v1/notifications', notificationRoutes); } catch(e) { console.error('Crash sur Notifications'); }

app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API opérationnelle' });
>>>>>>> origin/LAETITIA
});
*/

<<<<<<< HEAD
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
=======
// --- GESTION DES ERREURS 404 ---
app.use((req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Impossible de trouver ${req.originalUrl} sur ce serveur.`
  });
});

// --- LANCEMENT DU SERVEUR ---
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
>>>>>>> origin/LAETITIA
});