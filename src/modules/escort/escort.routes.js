const express = require('express');
const router = express.Router();
const upload = require('../../shares/middleware/multerConfig');
const escortController = require('./escort.controller');
const { protect } = require('../../shares/middleware/auth');

/**
 * @swagger
 * tags:
 *   - name: Escortes
 *     description: Gestion des profils escortes (Auth, Profil, Documents)
 */

/**
 * @swagger
 * /api/v1/escorts/register:
 *   post:
 *     summary: Inscription d'une nouvelle escorte
 *     tags: [Escortes]
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               nom:
 *                 type: string
 *               pseudo:
 *                 type: string
 *               mail:
 *                 type: string
 *               password:
 *                 type: string
 *               age:
 *                 type: integer
 *               telephone:
 *                 type: string
 *               id_localisation:
 *                 type: integer
 *               profile_picture:
 *                 type: string
 *                 format: binary
 *               recto_card:
 *                 type: string
 *                 format: binary
 *               verso_card:
 *                 type: string
 *                 format: binary
 *     responses:
 *       201:
 *         description: Escorte créée avec succès
 *       400:
 *         description: Données invalides
 */
router.post('/register', 
  upload.fields([
    { name: 'profile_picture', maxCount: 1 },
    { name: 'recto_card', maxCount: 1 },
    { name: 'verso_card', maxCount: 1 }
  ]), 
  escortController.registerEscort
);

/**
 * @swagger
 * /api/v1/escorts/login:
 *   post:
 *     summary: Connexion escorte
 *     tags: [Escortes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mail:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Connexion réussie, retourne un token
 *       401:
 *         description: Identifiants invalides
 */
router.post('/login', escortController.loginEscort);

/**
 * @swagger
 * /api/v1/escorts/me:
 *   get:
 *     summary: Récupérer mon profil (Escorte connectée)
 *     tags: [Escortes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Données du profil
 */
router.get('/me', protect, escortController.getMe);

/**
 * @swagger
 * /api/v1/escorts/update-me:
 *   patch:
 *     summary: Mettre à jour mes informations textuelles
 *     tags: [Escortes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nom:
 *                 type: string
 *               pseudo:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profil mis à jour
 */
router.patch('/update-me', protect, escortController.updateMe);

/**
 * @swagger
 * /api/v1/escorts/update-photo:
 *   patch:
 *     summary: Mettre à jour uniquement la photo de profil
 *     tags: [Escortes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               profile_picture:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Photo mise à jour avec succès
 */
router.patch('/update-photo', 
  protect, 
  upload.single('profile_picture'), 
  escortController.updateProfilePicture
);

module.exports = router;