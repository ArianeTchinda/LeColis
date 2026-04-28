const planService = require('./plan.service');
const asyncHandler = require('../../shared/middleware/asyncHandler');

// ──────────────────────────────────────────────
// CONTROLLER PLAN — Juste API, aucune logique
// Reçoit request → appelle service → retourne response
// ──────────────────────────────────────────────

/**
 * @swagger
 * /api/v1/plans:
 *   get:
 *     summary: Récupère tous les plans disponibles
 *     tags: [Plans]
 *     responses:
 *       200:
 *         description: Liste des plans
 */
const getAll = asyncHandler(async (req, res) => {
  const plans = await planService.getAllPlans();
  res.status(200).json({
    status: 'success',
    results: plans.length,
    data: { plans },
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   get:
 *     summary: Récupère un plan par ID
 *     tags: [Plans]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Détails du plan
 *       404:
 *         description: Plan introuvable
 */
const getOne = asyncHandler(async (req, res) => {
  const plan = await planService.getPlanById(req.params.id);
  res.status(200).json({
    status: 'success',
    data: { plan },
  });
});

/**
 * @swagger
 * /api/v1/plans:
 *   post:
 *     summary: Crée un nouveau plan (admin)
 *     tags: [Plans]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PlanInput'
 *     responses:
 *       201:
 *         description: Plan créé
 */
const create = asyncHandler(async (req, res) => {
  const plan = await planService.createPlan(req.body);
  res.status(201).json({
    status: 'success',
    data: { plan },
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   put:
 *     summary: Met à jour un plan (admin)
 *     tags: [Plans]
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
 *             $ref: '#/components/schemas/PlanInput'
 *     responses:
 *       200:
 *         description: Plan mis à jour
 *       404:
 *         description: Plan introuvable
 */
const update = asyncHandler(async (req, res) => {
  const plan = await planService.updatePlan(req.params.id, req.body);
  res.status(200).json({
    status: 'success',
    data: { plan },
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   delete:
 *     summary: Supprime un plan (admin)
 *     tags: [Plans]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       204:
 *         description: Plan supprimé
 *       404:
 *         description: Plan introuvable
 */
const remove = asyncHandler(async (req, res) => {
  await planService.deletePlan(req.params.id);
  res.status(204).json({
    status: 'success',
    data: null,
  });
});

module.exports = { getAll, getOne, create, update, remove };
