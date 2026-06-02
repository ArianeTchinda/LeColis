// src/routes/paiement.js
const router = require('express').Router();
const ctrl   = require('../controllers/paiementController');
const { authEscort } = require('../middlewares/auth');

// Créer un lien de paiement TaraMoney (🔐 token requis)
router.post('/creer-lien', authEscort, ctrl.creerLien);

// Page de retour après redirection TaraMoney (sans token — appelé par navigateur)
router.get('/retour', ctrl.retour);

// Vérifier le statut d'une transaction (🔐 token requis)
router.get('/statut/:transactionId', authEscort, ctrl.statutPaiement);

// Webhook TaraMoney (sans token — appelé directement par TaraMoney)
router.post('/webhook', ctrl.webhook);

module.exports = router;