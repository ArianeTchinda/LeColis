const express = require('express');
const subscriptionController = require('./subscription.controller');
const { validateSubscription } = require('./subscription.validator');

const router = express.Router();

router.post('/', validateSubscription, subscriptionController.subscribe);
router.get('/active/:escortId', subscriptionController.getActive);
router.get('/history/:escortId', subscriptionController.getHistory);
router.get('/:id', subscriptionController.getOne);

module.exports = router;
