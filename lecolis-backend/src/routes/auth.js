// src/routes/auth.js
const router = require('express').Router();
const ctrl   = require('../controllers/authController');
const resetCtrl  = require('../controllers/resetMdpController');
const { body, validationResult } = require('express-validator');

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
}

// POST /auth/register
router.post('/register',
  [
    body('pseudo').trim().isLength({ min: 3 }).withMessage('Pseudo : 3 caractères min.'),
    body('email').isEmail().normalizeEmail().withMessage('Email invalide.'),
    body('telephone').trim().notEmpty().withMessage('Téléphone requis.'),
    body('motDePasse').isLength({ min: 6 }).withMessage('Mot de passe : 6 caractères min.'),
  ],
  validate,
  ctrl.register,
);

// POST /auth/login
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('motDePasse').notEmpty(),
  ],
  validate,
  ctrl.login,
);

// POST /auth/refresh
router.post('/refresh', ctrl.refresh);

// POST /auth/logout
router.post('/logout', ctrl.logout);

// ── Reset mot de passe (3 étapes) ────────────────────────

// Étape 1 : demander un code par email
router.post('/mot-de-passe-oublie',
  [ body('email').isEmail().normalizeEmail().withMessage('Email invalide.') ],
  validate,
  resetCtrl.demanderReinit,
);

// Étape 2 : vérifier le code → renvoie reinitId
router.post('/verifier-code',
  [
    body('email').isEmail().normalizeEmail(),
    body('code').trim().isLength({ min: 6, max: 6 }).withMessage('Code à 6 chiffres requis.'),
  ],
  validate,
  resetCtrl.verifierCode,
);

// Étape 3 : définir le nouveau mot de passe
router.post('/reinitialiser-mdp',
  [
    body('reinitId').notEmpty().withMessage('reinitId requis.'),
    body('nouveauMotDePasse').isLength({ min: 6 }).withMessage('6 caractères minimum.'),
  ],
  validate,
  resetCtrl.reinitialiserMdp,
);

module.exports = router;

