const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const path = require('path'); // Nécessaire pour les chemins de fichiers
require('dotenv').config();

const db = require('./shares/database/config');
// IMPORT DES ROUTES (Adapte le chemin si nécessaire)
const escortRoutes = require('./modules/escort/escort.routes'); 

const app = express();

// --- SÉCURITÉ ET MIDDLEWARES ---

// Modifie Helmet pour autoriser l'affichage des images en local
app.use(helmet({ crossOriginResourcePolicy: false })); 
app.use(cors());
app.use(express.static('public'));

// ATTENTION : express.json() doit être AVANT les routes, 
// mais Multer gère le multipart tout seul. 10kb est un peu serré si tu reçois de longs textes.
app.use(express.json({ limit: '50kb' })); 


// RENDRE LE DOSSIER UPLOADS ACCESSIBLE
// Exemple : http://localhost:5000/uploads/documents/photo.jpg
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 100, 
  message: "Trop de tentatives. Réessayez dans 15 minutes."
});
app.use('/api', limiter);

// --- ROUTES ---

app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: 'success', message: 'API opérationnelle' });
});

// BRANCHEMENT DES ROUTES ESCORTES
app.use('/api/v1/escort', escortRoutes);

// --- GESTION DES ERREURS 404 ---
app.use((req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Impossible de trouver ${req.originalUrl} sur ce serveur.`
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
});