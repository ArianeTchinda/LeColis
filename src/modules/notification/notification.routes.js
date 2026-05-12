const express = require('express');
const router = express.Router();
const notifCtrl = require('./notification.controller');
const { protect } = require('../../shares/middleware/auth');

/**
 * @swagger
 * tags:
 *   - name: Notifications
 *     description: Gestion des alertes et messages pour Escortes et Admins
 */

/**
 * @swagger
 * /api/v1/notifications:
 *   get:
 *     summary: Récupérer mes notifications
 *     description: Retourne la liste des notifications liées à l'utilisateur connecté (Escorte ou Admin).
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des notifications récupérée avec succès.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                       message:
 *                         type: string
 *                       is_read:
 *                         type: boolean
 *                       id_escort:
 *                         type: integer
 *                       id_admin:
 *                         type: integer
 *       401:
 *         description: Non autorisé (Token manquant ou invalide)
 */
router.get('/', protect, notifCtrl.getMyNotifications);

/**
 * @swagger
 * /api/v1/notifications/{id}/read:
 *   patch:
 *     summary: Marquer une notification comme lue
 *     description: Change le statut `is_read` à true pour une notification spécifique.
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la notification à mettre à jour
 *     responses:
 *       200:
 *         description: Notification marquée comme lue.
 *       404:
 *         description: Notification non trouvée ou ne vous appartient pas.
 */
router.patch('/:id/read', protect, notifCtrl.markAsRead);

module.exports = router;