const planService = require('./plan.service');
const asyncHandler = require('../../shares/middleware/asyncHandler');

/**
 * @swagger
 * components:
 *   schemas:
 *     PlanInput:
 *       type: object
 *       required: [nom, nb_publications, duree_jours, prix]
 *       properties:
 *         nom: { type: string }
 *         nb_publications: { type: integer }
 *         duree_jours: { type: integer }
 *         prix: { type: number }
 *         description: { type: string }
 */

/**
 * @swagger
 * /api/v1/plans:
 *   get:
 *     summary: Recuperer tous les plans disponibles
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
    data: plans,
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   get:
 *     summary: Recuperer un plan par ID
 *     tags: [Plans]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Details du plan
 *       404:
 *         description: Plan introuvable
 */
const getOne = asyncHandler(async (req, res) => {
  const plan = await planService.getPlanById(req.params.id);
  res.status(200).json({
    status: 'success',
    data: plan,
  });
});

/**
 * @swagger
 * /api/v1/plans:
 *   post:
 *     summary: Cree un nouveau plan (admin)
 *     tags: [Plans]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PlanInput'
 *     responses:
 *       201:
 *         description: Plan cree
 */
const create = asyncHandler(async (req, res) => {
  const plan = await planService.createPlan(req.body);
  res.status(201).json({
    status: 'success',
    data: plan,
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   put:
 *     summary: Met a jour un plan (admin)
 *     tags: [Plans]
 *     security:
 *       - bearerAuth: []
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
 *         description: Plan mis a jour
 *       404:
 *         description: Plan introuvable
 */
const update = asyncHandler(async (req, res) => {
  const plan = await planService.updatePlan(req.params.id, req.body);
  res.status(200).json({
    status: 'success',
    data: plan,
  });
});

/**
 * @swagger
 * /api/v1/plans/{id}:
 *   delete:
 *     summary: Supprime un plan (admin)
 *     tags: [Plans]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       204:
 *         description: Plan supprime
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
