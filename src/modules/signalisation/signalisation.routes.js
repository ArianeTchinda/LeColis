// src/modules/signalisation/signalisation.routes.js
const express = require('express');
const router = express.Router();
const sigCtrl = require('./signalisation.controller');
const { protect } = require('../../shares/middleware/auth');

/**
 * @swagger
 * tags:
 *   - name: Signalisation
 *     description: Gestion des signalements (Reports) des escortes
 */

/**
 * @swagger
 * /api/v1/signalisation:
 *   post:
 *     summary: Signaler une escorte
 *     description: Permet à un utilisateur (ou visiteur) de signaler un comportement abusif.
 *     tags: [Signalisation]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - raison
 *               - id_escort
 *             properties:
 *               raison:
 *                 type: string
 *                 example: "Profil trompeur ou comportement suspect"
 *               id_escort:
 *                 type: integer
 *                 example: 5
 *     responses:
 *       201:
 *         description: Signalement enregistré avec succès.
 *       400:
 *         description: Données manquantes.
 */
router.post('/', sigCtrl.createSignalement);

/**
 * @swagger
 * /api/v1/signalisation/{id}/assign:
 *   patch:
 *     summary: Assigner un admin à un signalement
 *     description: Permet à un administrateur de prendre en charge un dossier de signalement.
 *     tags: [Signalisation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID du signalement
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               id_admin:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       200:
 *         description: Admin assigné au signalement.
 *       401:
 *         description: Non autorisé.
 */
router.patch('/:id/assign', protect, sigCtrl.assignAdminToSignalement);

module.exports = router;