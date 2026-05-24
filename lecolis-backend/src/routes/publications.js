// src/routes/publications.js
const router  = require('express').Router();
const pubCtrl = require('../controllers/publicationController');
const abCtrl  = require('../controllers/abonnementController');

// ── Publications publiques ──
router.get('/',              pubCtrl.lister);
router.get('/:id',           pubCtrl.detail);
router.post('/:id/avis',     pubCtrl.ajouterAvis);
router.post('/:id/signaler', pubCtrl.signaler);

// ── Plans (publics) ──
router.get('/plans', abCtrl.listerPlans);

module.exports = router;
