const publicationService = require('./publication.service');
const asyncHandler = require('../../shares/middleware/asyncHandler');

// ──────────────────────────────────────────────
// CONTROLLER PUBLICATION — Juste API
// Reçoit request → appelle service → retourne response
// ──────────────────────────────────────────────

/**
 * @swagger
 * /api/v1/publications:
 *   post:
 *     summary: Crée une publication (vérifie abonnement + quota)
 *     tags: [Publications]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PublicationInput'
 *     responses:
 *       201:
 *         description: Publication créée
 *       403:
 *         description: Pas d'abonnement actif ou quota dépassé
 */
const create = asyncHandler(async (req, res) => {
  const publication = await publicationService.createPublication(req.body);

  res.status(201).json({
    status: 'success',
    message: 'Publication créée avec succès.',
    data: { publication },
  });
});

/**
 * @swagger
 * /api/v1/publications:
 *   get:
 *     summary: Récupère toutes les publications actives (vitrine publique)
 *     tags: [Publications]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Liste des publications actives
 */
const getAll = asyncHandler(async (req, res) => {
  const limit = parseInt(req.query.limit, 10) || 50;
  const offset = parseInt(req.query.offset, 10) || 0;

  const publications = await publicationService.getActivePublications({ limit, offset });

  res.status(200).json({
    status: 'success',
    results: publications.length,
    data: { publications },
  });
});

/**
 * @swagger
 * /api/v1/publications/escort/{escortId}:
 *   get:
 *     summary: Récupère les publications d'un escort
 *     tags: [Publications]
 *     parameters:
 *       - in: path
 *         name: escortId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Publications de l'escort
 */
const getByEscort = asyncHandler(async (req, res) => {
  const publications = await publicationService.getPublicationsByEscort(
    parseInt(req.params.escortId, 10)
  );

  res.status(200).json({
    status: 'success',
    results: publications.length,
    data: { publications },
  });
});

/**
 * @swagger
 * /api/v1/publications/{id}:
 *   get:
 *     summary: Récupère une publication par ID
 *     tags: [Publications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Détails de la publication
 *       404:
 *         description: Publication introuvable
 */
const getOne = asyncHandler(async (req, res) => {
  const publication = await publicationService.getPublicationById(
    parseInt(req.params.id, 10)
  );

  res.status(200).json({
    status: 'success',
    data: { publication },
  });
});

/**
 * @swagger
 * /api/v1/publications/{id}:
 *   delete:
 *     summary: Supprime une publication (propriétaire uniquement)
 *     tags: [Publications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id_escort
 *             properties:
 *               id_escort:
 *                 type: integer
 *     responses:
 *       204:
 *         description: Publication supprimée
 *       403:
 *         description: Non propriétaire
 *       404:
 *         description: Publication introuvable
 */
const remove = asyncHandler(async (req, res) => {
  await publicationService.deletePublication(
    parseInt(req.params.id, 10),
    req.body.id_escort
  );

  res.status(204).json({
    status: 'success',
    data: null,
  });
});

module.exports = { create, getAll, getByEscort, getOne, remove };
