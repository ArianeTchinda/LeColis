// src/index.js
require('dotenv').config();

const express      = require('express');
const cors         = require('cors');
const morgan       = require('morgan');
const errorHandler = require('./middlewares/errorHandler');

const authRoutes         = require('./routes/auth');
const profilRoutes       = require('./routes/profil');
const publicationRoutes  = require('./routes/publications');
const abonnementRoutes   = require('./routes/abonnements');
const adminRoutes        = require('./routes/admin');
const referentielRoutes  = require('./routes/referentiel');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── CORS : parse les origines depuis .env ─────────────────
const allowedOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map(o => o.trim())
  .filter(Boolean);

const corsOptions = {
  origin: function (origin, callback) {
    // Autorise les requêtes sans origin (Postman, mobile, etc.)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
      callback(null, true);
    } else {
      callback(new Error(`CORS bloqué pour l'origine : ${origin}`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

// ── Middlewares globaux ───────────────────────────────────
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── Routes ────────────────────────────────────────────────
app.use('/api/auth',         authRoutes);
app.use('/api/profil',       profilRoutes);
app.use('/api/publications',  publicationRoutes);
app.use('/api/abonnements',  abonnementRoutes);
app.use('/api/admin',        adminRoutes);
app.use('/api',              referentielRoutes);

// ── Health check ──────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString() });
});

// ── 404 ───────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: 'Route introuvable.' });
});

// ── Gestionnaire d'erreurs ────────────────────────────────
app.use(errorHandler);

// ── Démarrage ─────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 LeColis API démarrée sur http://localhost:${PORT}`);
  console.log(`   Mode : ${process.env.NODE_ENV || 'development'}`);
  console.log(`   Origines CORS autorisées : ${allowedOrigins.join(', ')}`);
  console.log(`   Admin : POST /api/admin/login\n`);
});

module.exports = app;