const express = require('express');
const router = express.Router();
const notifCtrl = require('./notification.controller');
const { protect } = require('../../shares/middleware/auth');

router.get('/', protect, notifCtrl.getMyNotifications);
router.patch('/:id/read', protect, notifCtrl.markAsRead);

module.exports = router;