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
router.post('/plans',                ctrl.creerPlan);    // créer un plan custom
router.put('/plans/:id',             ctrl.modifierPlan);
router.delete('/plans/:id',          ctrl.supprimerPlan);  // plans custom uniquement

// Abonnements
router.put('/abonnements/:id/ajuster',  ctrl.ajusterAbonnement);
router.post('/escorts/:id/cadeau',      ctrl.offrirCadeau);     // offrir un plan cadeau

// Notifications
router.post('/notifications/envoyer', ctrl.envoyerNotification);

// Transactions
router.get('/transactions',           ctrl.listerTransactions);

// Publications
router.get('/publications',                      ctrl.listerPublications);
router.put('/publications/:id/statut',           ctrl.changerStatutPublication);

// Analytics (graphiques dashboard)
router.get('/analytics',                        ctrl.analytics);
 
// Historique notifications envoyées
router.get('/notifications/historique',         ctrl.historiqueNotifications);

module.exports = router;