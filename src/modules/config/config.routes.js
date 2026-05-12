const express = require('express');
const router = express.Router();
const configController = require('./config.controller');
const protectAdmin = require('../../shares/middleware/authadmin');
const upload = require('../../shares/middleware/upload');

router.get('/logo', configController.getLogo);
router.patch('/admin/logo', protectAdmin, upload.single('logo'), configController.updateLogo);

module.exports = router;
