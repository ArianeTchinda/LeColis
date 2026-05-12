const express = require('express');
const router = express.Router();
const avisController = require('./avis.controller');
const { protect } = require('../../shares/middleware/auth');

// Laisser un avis (nécessite d'être connecté)
router.post('/', protect, avisController.addAvis);

// Récupérer les avis d'une escort (public)
router.get('/escort/:escort_id', avisController.getAvisByEscort);

module.exports = router;