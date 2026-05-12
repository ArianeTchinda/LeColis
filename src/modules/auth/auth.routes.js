const express = require('express');
const router = express.Router();
const authCtrl = require('./auth.controller');
const { protect } = require('../../shares/middleware/auth');

router.post('/refresh', authCtrl.refresh);
router.post('/logout', protect, authCtrl.logout);

module.exports = router;
