const express = require('express');
const router = express.Router();
const notifCtrl = require('./notification.controller');
const {protect} = require('../../shares/middleware/auth'); // Middleware JWT global

router.get('/', protect, notifCtrl.getMyNotifications);

module.exports = router;