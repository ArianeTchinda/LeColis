// src/routes/referentiel.js
const router      = require('express').Router();
const ctrl        = require('../controllers/referentielController');
const { authEscort } = require('../middlewares/auth');

// ── GET — lecture publique ────────────────────────────────
router.get('/localisation/pays',      ctrl.getPays);
router.get('/localisation/regions',   ctrl.getRegions);
router.get('/localisation/villes',    ctrl.getVilles);
router.get('/localisation/quartiers', ctrl.getQuartiers);

// ── POST — upsert (authentifié escort) ───────────────────
// "Créer si absent, retourner si existant"
// Déduplication insensible à la casse et aux accents côté controller
router.post('/localisation/pays',      authEscort, ctrl.upsertPays);
router.post('/localisation/regions',   authEscort, ctrl.upsertRegion);
router.post('/localisation/villes',    authEscort, ctrl.upsertVille);
router.post('/localisation/quartiers', authEscort, ctrl.upsertQuartier);

// ── Catégories ────────────────────────────────────────────
router.get('/categories',      ctrl.getCategories);
router.get('/categories/flat', ctrl.getCategoriesFlat);

module.exports = router;