// src/routes/referentiel.js
const router = require('express').Router();
const ctrl   = require('../controllers/referentielController');

// Localisation
router.get('/localisation/pays',      ctrl.getPays);
router.get('/localisation/regions',   ctrl.getRegions);
router.get('/localisation/villes',    ctrl.getVilles);
router.get('/localisation/quartiers', ctrl.getQuartiers);

// Catégories
router.get('/categories',      ctrl.getCategories);
router.get('/categories/flat', ctrl.getCategoriesFlat);

module.exports = router;
