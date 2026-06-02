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
const paiementRoutes     = require('./routes/paiement'); 
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
app.use('/api/paiement',     paiementRoutes);
app.use('/api/admin',        adminRoutes);
app.use('/api',              referentielRoutes);

// Ajouter avant les autres routes
app.get('/api/proxy-image', async (req, res) => {
  try {
    let imageUrl = req.query.url;
    if (!imageUrl) return res.status(400).json({ error: 'URL manquante' });
    
    // Réécrire l'URL publique (émulateur) en URL interne (backend)
    // Le client envoie: http://10.0.2.2:9000/... 
    // Le backend doit utiliser: http://localhost:9000/...
    if (imageUrl.includes('10.0.2.2')) {
      imageUrl = imageUrl.replace('10.0.2.2', 'localhost');
      console.log('[proxy-image] URL réécrite:', imageUrl);
    }
    
    const response = await fetch(imageUrl);
    if (!response.ok) {
      throw new Error(`MinIO retourna ${response.status}`);
    }
    
    res.setHeader('Content-Type', response.headers.get('content-type'));
    res.setHeader('Access-Control-Allow-Origin', '*');
    const buffer = Buffer.from(await response.arrayBuffer());
    res.send(buffer);
  } catch (err) {
    console.error('[proxy-image] Erreur:', err.message);
    res.status(500).json({ error: 'Erreur proxy', details: err.message });
  }
});

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