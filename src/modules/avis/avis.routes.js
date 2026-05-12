const express = require('express');
const router = express.Router();
const avisController = require('./avis.controller');
const { protect } = require('../../shares/middleware/auth');

/**
 * @swagger
 * tags:
 *   - name: Avis
 *     description: Gestion des notes et commentaires sur les profils escortes
 */

/**
 * @swagger
 * /api/v1/avis:
 *   post:
 *     summary: Laisser un avis sur une escorte
 *     description: Permet d'ajouter un commentaire et une note (0 à 5) pour une escorte spécifique.
 *     tags: [Avis]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *               - rate
 *               - id_escort
 *             properties:
 *               message:
 *                 type: string
 *                 example: "Très professionnelle et ponctuelle."
 *               rate:
 *                 type: integer
 *                 minimum: 0
 *                 maximum: 5
 *                 example: 5
 *               id_escort:
 *                 type: integer
 *                 example: 3
 *     responses:
 *       201:
 *         description: Avis ajouté avec succès.
 *       400:
 *         description: Données invalides ou note hors limite.
 */
router.post('/', avisController.addAvis);

/**
 * @swagger
 * /api/v1/avis/escort/{id_escort}:
 *   get:
 *     summary: Récupérer les avis d'une escorte
 *     description: Retourne la liste de tous les commentaires et notes laissés pour une escorte via son ID.
 *     tags: [Avis]
 *     parameters:
 *       - in: path
 *         name: id_escort
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de l'escorte concernée
 *     responses:
 *       200:
 *         description: Liste des avis récupérée.
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
 *                       rate:
 *                         type: integer
 *                       date:
 *                         type: string
 *                         format: date
 *       404:
 *         description: Aucune escorte trouvée avec cet ID.
 */
router.get('/escort/:id_escort', avisController.getAvisByEscort);

module.exports = router;