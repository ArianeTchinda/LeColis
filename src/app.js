const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const cron = require('node-cron');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

// Configs et Utils
const swaggerSpec = require('./shares/config/swagger.js');
const db = require('./shares/database/db');
const logger = require('./shares/utils/logger');
const { errorHandler } = require('./shares/middleware/errorHandler');

// Jobs CRON
const { runExpireSubscriptions } = require('./jobs/subscription.job');

// Import des Routes
const routes = require('./routes'); // Routeur centralisé v2.0

const app = express();
const server = http.createServer(app);

// INITIALISATION SOCKET.IO

const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Logique Socket.io
io.on('connection', (socket) => {
    logger.info(`Un utilisateur connecté: ${socket.id}`);

    socket.on('join_admin_room', () => {
        socket.join('admins');
        logger.info('Un admin a rejoint la room admins');
    });

    socket.on('join_escort_room', (escortId) => {
        socket.join(`escort_${escortId}`);
        logger.info(`Escorte ${escortId} connectée à sa room`);
    });

    socket.on('disconnect', () => {
        logger.info('Utilisateur déconnecté');
    });
});

// MIDDLEWARES DE SECURITE ET BASE

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// Injection de Socket.io dans les requêtes
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Rate Limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: { status: 'fail', message: "Trop de requêtes. Réessayez dans 15 minutes." }
});
app.use('/api', limiter);

// DOCUMENTATION SWAGGER

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/api-docs.json', (req, res) => res.json(swaggerSpec));

// ROUTES

// Health Check
app.get('/api/v1/health', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'API opérationnelle',
        timestamp: new Date().toISOString(),
    });
});

// Montage des routes v2.0
app.use('/api/v1', routes);

// GESTION DES ERREURS

// 404 - Toujours après les routes
app.all('/*splat', (req, res) => {
    res.status(404).json({
        status: 'fail',
        message: `Impossible de trouver ${req.originalUrl} sur ce serveur.`
    });
});

// Middleware global d'erreur (en dernier)
app.use(errorHandler);

// JOBS CRON

cron.schedule('0 * * * *', () => {
    logger.info('Démarrage du job CRON : Expiration des abonnements');
    runExpireSubscriptions();
});

// LANCEMENT DU SERVEUR

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    logger.info(`Serveur démarré sur le port ${PORT}`);
    logger.info(`Swagger : http://localhost:${PORT}/api-docs`);
});