const express = require('express');
const router = express.Router();
const catController = require('./categorie.controller');
const { protect } = require('../../shares/middleware/auth');

/**
 * @swagger
 * tags:
 *   - name: Categories
 *     description: Gestion des categories de services
 */

/**
 * @swagger
 * /api/v1/categories:
 *   get:
 *     summary: Récupérer toutes les catégories
 *     description: Retourne la liste complète des catégories disponibles sur la plateforme. Accessible à tous.
 *     tags: [Categories]
 *     responses:
 *       200:
 *         description: Liste des catégories récupérée avec succès.
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
 *                       nom:
 *                         type: string
 *                         example: "Massage"
 */
router.get('/', catController.getAllCategories);

/**
 * @swagger
 * /api/v1/categories:
 *   post:
 *     summary: Créer une nouvelle catégorie (Admin)
 *     description: Permet à un administrateur d'ajouter une catégorie à la plateforme.
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nom
 *             properties:
 *               nom:
 *                 type: string
 *                 example: "Nouvelle Catégorie"
 *     responses:
 *       201:
 *         description: Catégorie créée.
 *       401:
 *         description: Non autorisé.
 */
router.post('/', protect, catController.createCategorie); 

/**
 * @swagger
 * /api/v1/categories/{id}:
 *   delete:
 *     summary: Supprimer une catégorie (Admin)
 *     description: Supprime définitivement une catégorie via son ID.
 *     tags: [Categories]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la catégorie à supprimer
 *     responses:
 *       204:
 *         description: Catégorie supprimée.
 *       404:
 *         description: Catégorie non trouvée.
 */
router.delete('/:id', protect, catController.deleteCategorie);

module.exports = router;