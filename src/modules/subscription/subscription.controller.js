const subscriptionService = require('./subscription.service');
const asyncHandler = require('../../shares/middleware/asyncHandler');

// ──────────────────────────────────────────────
// CONTROLLER SUBSCRIPTION — Juste API
// Reçoit request → appelle service → retourne response
// ──────────────────────────────────────────────

/**
 * @swagger
 * /api/v1/subscriptions:
 *   post:
 *     summary: Souscrire à un plan (paiement + activation)
 *     tags: [Souscriptions]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/SubscriptionInput'
 *     responses:
 *       201:
 *         description: Souscription créée avec succès
 *       400:
 *         description: Abonnement déjà actif ou données invalides
 *       402:
 *         description: Paiement échoué
 *       404:
 *         description: Plan introuvable
 */
const subscribe = asyncHandler(async (req, res) => {
  const { escortId, planId, montant, moyen_payement } = req.body;

  const subscription = await subscriptionService.subscribe({
    escortId,
    planId,
    montant,
    moyen_payement,
  });

  res.status(201).json({
    status: 'success',
    message: 'Souscription créée avec succès.',
    data: { subscription },
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/active/{escortId}:
 *   get:
 *     summary: Récupère l'abonnement actif d'un escort
 *     tags: [Souscriptions]
 *     parameters:
 *       - in: path
 *         name: escortId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Abonnement actif (ou null si aucun)
 */
const getActive = asyncHandler(async (req, res) => {
  const subscription = await subscriptionService.getActiveSubscription(
    parseInt(req.params.escortId, 10)
  );

  res.status(200).json({
    status: 'success',
    data: { subscription },
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/history/{escortId}:
 *   get:
 *     summary: Récupère l'historique des souscriptions d'un escort
 *     tags: [Souscriptions]
 *     parameters:
 *       - in: path
 *         name: escortId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Historique des souscriptions
 */
const getHistory = asyncHandler(async (req, res) => {
  const subscriptions = await subscriptionService.getSubscriptionHistory(
    parseInt(req.params.escortId, 10)
  );

  res.status(200).json({
    status: 'success',
    results: subscriptions.length,
    data: { subscriptions },
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/{id}:
 *   get:
 *     summary: Récupère une souscription par ID
 *     tags: [Souscriptions]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Détails de la souscription
 *       404:
 *         description: Souscription introuvable
 */
const getOne = asyncHandler(async (req, res) => {
  const subscription = await subscriptionService.getSubscriptionById(
    parseInt(req.params.id, 10)
  );

  res.status(200).json({
    status: 'success',
    data: { subscription },
  });
});

module.exports = { subscribe, getActive, getHistory, getOne };
