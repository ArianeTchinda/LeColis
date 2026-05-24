// src/routes/profil.js
const router = require('express').Router();
const ctrl   = require('../controllers/profilController');
const pubCtrl = require('../controllers/publicationController');
const abCtrl  = require('../controllers/abonnementController');
const { authEscort } = require('../middlewares/auth');
const { uploadPhoto, uploadImages } = require('../middlewares/upload');

// Toutes les routes profil requièrent auth
router.use(authEscort);

// ── Profil ──
router.get('/',             ctrl.getMe);
router.put('/',             ctrl.updateMe);
router.put('/photo',        uploadPhoto, ctrl.updatePhoto);
router.put('/mot-de-passe', ctrl.updatePassword);

// ── Notifications ──
router.get('/notifications',         ctrl.getNotifications);
router.put('/notifications/:id/lue', ctrl.marquerLue);

// ── Transactions ──
router.get('/transactions', ctrl.getTransactions);

// ── Abonnement ──
router.get('/abonnement',            abCtrl.monAbonnement);
router.get('/historique-abonnements', abCtrl.historique);

// ── Publications ──
router.get('/publications',                        pubCtrl.mesPubs);
router.post('/publications',                       pubCtrl.creer);
router.put('/publications/:id',                    pubCtrl.modifier);
router.delete('/publications/:id',                 pubCtrl.supprimer);
router.post('/publications/:id/images', uploadImages, pubCtrl.ajouterImages);
router.delete('/publications/:id/images/:imageId', pubCtrl.supprimerImage);

module.exports = router;
