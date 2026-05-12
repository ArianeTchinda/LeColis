const express = require('express');
const subscriptionController = require('./subscription.controller');
const { protect } = require('../../shares/middleware/auth');

const router = express.Router();

router.post('/', protect, subscriptionController.subscribe);
router.post('/upgrade', protect, subscriptionController.upgrade);
router.get('/active', protect, subscriptionController.getActive);
router.get('/history', protect, subscriptionController.getHistory);

module.exports = router;
