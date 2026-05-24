// src/routes/admin.js
const router = require('express').Router();
const ctrl   = require('../controllers/adminController');
const { authAdmin } = require('../middlewares/auth');

// ── Auth admin (publique) ──
router.post('/login', ctrl.login);

// ── Routes protégées ──
router.use(authAdmin);

router.get('/dashboard',          ctrl.dashboard);

// Escorts
router.get('/escorts',            ctrl.listerEscorts);
router.get('/escorts/:id',        ctrl.detailEscort);
router.put('/escorts/:id/verifier',   ctrl.verifierEscort);
router.post('/escorts/:id/sanctionner', ctrl.sanctionner);
router.put('/escorts/:id/debloquer',  ctrl.debloquer);

// Signalements
router.get('/signalements',          ctrl.listerSignalements);
router.put('/signalements/:id',      ctrl.traiterSignalement);

// Plans
router.get('/plans',                 ctrl.listerPlans);
router.put('/plans/:id',             ctrl.modifierPlan);

// Abonnements
router.put('/abonnements/:id/ajuster', ctrl.ajusterAbonnement);

// Notifications
router.post('/notifications/envoyer', ctrl.envoyerNotification);

// Transactions
router.get('/transactions',           ctrl.listerTransactions);

// Publications
router.get('/publications',                      ctrl.listerPublications);
router.put('/publications/:id/statut',           ctrl.changerStatutPublication);

module.exports = router;
