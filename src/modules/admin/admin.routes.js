const express = require('express');
const router = express.Router();
const adminController = require('./admin.controller');
const protectAdmin = require('../../shared/middleware/authAdmin');

// --- Routes Publiques (Accessibles par la page front Admin) ---
router.post('/register', adminController.registerAdmin);
router.post('/login', adminController.loginAdmin);

// --- Routes Protégées (Nécessitent d'être connecté) ---
router.get('/reports/pending', protectAdmin, adminController.getPendingReports);
router.patch('/reports/:id_signalement/claim', protectAdmin, adminController.claimReport);

module.exports = router;