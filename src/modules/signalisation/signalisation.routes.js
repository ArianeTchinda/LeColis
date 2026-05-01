// src/modules/signalisation/signalisation.routes.js
const express = require('express');
const router = express.Router();
const sigCtrl = require('./signalisation.controller');

router.post('/', sigCtrl.createSignalement);
router.patch('/:id/assign', sigCtrl.assignAdminToSignalement);

module.exports = router; // <--- BIEN VÉRIFIER CETTE LIGNE