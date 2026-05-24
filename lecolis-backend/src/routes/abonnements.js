// src/routes/abonnements.js
const router = require('express').Router();
const ctrl   = require('../controllers/abonnementController');
const { authEscort } = require('../middlewares/auth');

// Plans (publics)
router.get('/plans', ctrl.listerPlans);

// Souscription (authentifié)
router.post('/souscrire', authEscort, ctrl.souscrire);

module.exports = router;
