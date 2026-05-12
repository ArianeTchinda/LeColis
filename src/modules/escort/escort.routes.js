const express = require('express');
const router = express.Router();
const upload = require('../../shares/middleware/multerConfig');
const escortController = require('./escort.controller');
const { protect } = require('../../shares/middleware/auth');

// 'upload.fields' permet de recevoir plusieurs fichiers avec des noms différents
router.post('/register', 
  upload.fields([
    {name: 'profile_picture', maxCount: 1},
    { name: 'recto_card', maxCount: 1 },
    { name: 'verso_card', maxCount: 1 }
  ]), 
  escortController.registerEscort
);

router.post('/login', escortController.loginEscort);
router.get('/me', protect, escortController.getMe);
router.patch('/update-me', protect, escortController.updateMe);
router.patch('/update-photo', 
  protect, 
  upload.single('profile_picture'), 
  escortController.updateProfilePicture
);

module.exports = router;