const express = require('express');
const router = express.Router();
const transactionController = require('./transaction.controller');
const { protect } = require('../../shares/middleware/auth');
const protectAdmin = require('../../shares/middleware/authadmin');

router.post('/', protect, transactionController.createTransaction);
router.get('/me', protect, transactionController.getMyTransactions);
router.get('/admin', protectAdmin, transactionController.getAllTransactions);

module.exports = router;
