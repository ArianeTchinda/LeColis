const express = require('express');
const router = express.Router();
const sigCtrl = require('./signalisation.controller');
const { protect } = require('../../shares/middleware/auth');

// Tout le monde peut signaler (si connecté)
router.post('/', protect, sigCtrl.createSignalement);

module.exports = router;