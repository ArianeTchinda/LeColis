const express = require('express');
const router = express.Router();
const adminController = require('./admin.controller');
const protectAdmin = require('../../shares/middleware/authadmin');

/**
 * @swagger
 * tags:
 *   - name: Admin
 *     description: Gestion de l'administration, authentification et modération
 */

/**
 * @swagger
 * /api/v1/admin/register:
 *   post:
 *     summary: Inscrire un nouvel administrateur
 *     tags: [Admin]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nom
 *               - prenom
 *               - email
 *               - password
 *             properties:
 *               nom:
 *                 type: string
 *               prenom:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       201:
 *         description: Admin créé avec succès
 */
router.post('/register', adminController.registerAdmin);

/**
 * @swagger
 * /api/v1/admin/login:
 *   post:
 *     summary: Connexion Administrateur
 *     tags: [Admin]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Connexion réussie, retourne un token admin
 */
router.post('/login', adminController.loginAdmin);

/**
 * @swagger
 * /api/v1/admin/reports/pending:
 *   get:
 *     summary: Liste des signalements en attente (Dashboard)
 *     description: Récupère tous les signalements qui n'ont pas encore été traités par un admin.
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des signalements récupérée
 *       401:
 *         description: Accès refusé (Token admin invalide)
 */
router.get('/reports/pending', protectAdmin, adminController.getPendingReports);

/**
 * @swagger
 * /api/v1/admin/reports/{id_signalement}/claim:
 *   patch:
 *     summary: Prendre en charge un signalement
 *     description: L'admin connecté s'assigne un signalement spécifique pour enquête.
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id_signalement
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du signalement à traiter
 *     responses:
 *       200:
 *         description: Signalement assigné avec succès
 *       404:
 *         description: Signalement non trouvé
 */
router.patch('/reports/:id_signalement/claim', protectAdmin, adminController.claimReport);

module.exports = router;