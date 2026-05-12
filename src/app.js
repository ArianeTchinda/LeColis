require('dotenv').config();
const express = require('express');
const http = require('http'); // AJOUTÉ
const { Server } = require('socket.io');
const { initBucket } = require('./shares/services/minio.service');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const swaggerJsDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const swaggerOptions = {
  swaggerDefinition: {
    openapi: '3.0.0',
    info: {
      title: 'API LeColis',
      version: '1.0.0',
      description: 'Documentation de l\'API pour le projet LeColis (DEV 2)',
      contact: {
        name: 'BlackFlower'
      },
      servers: [{ url: 'http://localhost:5000' }]
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        }
      }
    }
  },
  // Chemin vers tes fichiers de routes pour extraire la doc
  apis: ['./src/modules/**/*.routes.js'], 
};



initBucket();

// Initialisation Express
const app = express();

// Swagger docs (build after app creation to avoid referencing `app` before init)
const swaggerDocs = swaggerJsDoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

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
  windowMs: 15 * 60 * 1000, 
  max: 100, 
  message: { status: 'fail', message: "Trop de tentatives. Réessayez dans 15 minutes." }
});
app.use('/api', limiter);

// --- ROUTES ---

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
});

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
});