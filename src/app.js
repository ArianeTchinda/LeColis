const express = require('express');
const http = require('http'); // AJOUTÉ
const { Server } = require('socket.io');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
require('dotenv').config();

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
const adminRoutes = require('./src/modules/admin/admin.routes');
const signalisationRoutes = require('./src/modules/signalisation/signalisation.routes');

app.use('/api/v1/admins', adminRoutes);
app.use('/api/v1/signalisation', signalisationRoutes);

app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API opérationnelle' });
});

// --- GESTION DES ERREURS 404 ---
app.all('*', (req, res) => {
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