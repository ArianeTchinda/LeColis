const express = require('express');
const router = express.Router();
const avisController = require('./avis.controller');

// Laisser un avis
router.post('/', avisController.addAvis);

// Récupérer les avis d'une escorte
router.get('/escort/:id_escort', avisController.getAvisByEscort);

module.exports = router;