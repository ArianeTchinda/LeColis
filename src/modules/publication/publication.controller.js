const publicationService = require('./publication.service');
const asyncHandler = require('../../shares/middleware/asyncHandler');

/**
 * @swagger
 * components:
 *   schemas:
 *     PublicationInput:
 *       type: object
 *       required: [titre, description]
 *       properties:
 *         titre: { type: string }
 *         description: { type: string }
 *         montant: { type: number }
 *         duree: { type: integer }
 */

/**
 * @swagger
 * /api/v1/publications:
 *   post:
 *     summary: Cree une publication (verifie abonnement + quota)
 *     tags: [Publications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PublicationInput'
 *     responses:
 *       201:
 *         description: Publication creee
 *       403:
 *         description: Pas d'abonnement actif ou quota depasse
 */
const create = asyncHandler(async (req, res) => {
  const escort_id = req.user.id;
  const publication = await publicationService.createPublication({ ...req.body, id_escort: escort_id });

  res.status(201).json({
    status: 'success',
    data: publication,
  });
});

/**
 * @swagger
 * /api/v1/publications:
 *   get:
 *     summary: Recupere toutes les publications actives (vitrine publique)
 *     tags: [Publications]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 50 }
 *       - in: query
 *         name: offset
 *         schema: { type: integer, default: 0 }
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
    data: publications,
  });
});

/**
 * @swagger
 * /api/v1/publications/escort/{escortId}:
 *   get:
 *     summary: Recupere les publications d'un escort
 *     tags: [Publications]
 *     parameters:
 *       - in: path
 *         name: escortId
 *         required: true
 *         schema: { type: integer }
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
    data: publications,
  });
});

/**
 * @swagger
 * /api/v1/publications/{id}:
 *   get:
 *     summary: Recupere une publication par ID
 *     tags: [Publications]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Details de la publication
 *       404:
 *         description: Publication introuvable
 */
const getOne = asyncHandler(async (req, res) => {
  const publication = await publicationService.getPublicationById(
    parseInt(req.params.id, 10)
  );

  res.status(200).json({
    status: 'success',
    data: publication,
  });
});

/**
 * @swagger
 * /api/v1/publications/{id}:
 *   delete:
 *     summary: Supprime une publication (proprietaire uniquement)
 *     tags: [Publications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       204:
 *         description: Publication supprimee
 */
const remove = asyncHandler(async (req, res) => {
  await publicationService.deletePublication(
    parseInt(req.params.id, 10),
    req.user.id
  );

  res.status(204).json({
    status: 'success',
    data: null,
  });
});

module.exports = { create, getAll, getByEscort, getOne, remove };
