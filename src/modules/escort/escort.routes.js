const express = require('express');
const router = express.Router();
const upload = require('../../shares/middleware/upload');
const escortController = require('./escort.controller');

// 'upload.fields' permet de recevoir plusieurs fichiers avec des noms différents
router.post('/register', 
  upload.fields([
    { name: 'recto_card', maxCount: 1 },
    { name: 'verso_card', maxCount: 1 }
  ]), 
  escortController.registerEscort
);

module.exports = router;