const subscriptionService = require('./subscription.service');
const asyncHandler = require('../../shares/middleware/asyncHandler');

/**
 * @swagger
 * /api/v1/subscriptions:
 *   post:
 *     summary: Souscrire a un plan
 *     tags: [Souscriptions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [planId]
 *             properties:
 *               planId: { type: integer }
 *     responses:
 *       201:
 *         description: Souscription creee avec succes
 *       400:
 *         description: Abonnement deja actif
 */
const subscribe = asyncHandler(async (req, res) => {
  const { planId } = req.body;
  const escortId = req.user.id;

  const subscription = await subscriptionService.subscribe({
    escortId,
    planId,
  });

  res.status(201).json({
    status: 'success',
    data: subscription,
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/upgrade:
 *   post:
 *     summary: Changer de plan (Upgrade)
 *     tags: [Souscriptions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [newPlanId]
 *             properties:
 *               newPlanId: { type: integer }
 *     responses:
 *       200:
 *         description: Upgrade reussi
 */
const upgrade = asyncHandler(async (req, res) => {
  const { newPlanId } = req.body;
  const escortId = req.user.id;

  const subscription = await subscriptionService.upgradeSubscription({
    escortId,
    newPlanId,
  });

  res.status(200).json({
    status: 'success',
    message: 'Upgrade reussi !',
    data: subscription,
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/active:
 *   get:
 *     summary: Recuperer mon abonnement actif
 *     tags: [Souscriptions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Abonnement actif
 */
const getActive = asyncHandler(async (req, res) => {
  const escortId = req.user.id;
  const subscription = await subscriptionService.getActiveSubscription(escortId);

  res.status(200).json({
    status: 'success',
    data: subscription,
  });
});

/**
 * @swagger
 * /api/v1/subscriptions/history:
 *   get:
 *     summary: Recuperer l'historique de mes souscriptions
 *     tags: [Souscriptions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Historique des souscriptions
 */
const getHistory = asyncHandler(async (req, res) => {
  const escortId = req.user.id;
  const subscriptions = await subscriptionService.getSubscriptionHistory(escortId);

  res.status(200).json({
    status: 'success',
    results: subscriptions.length,
    data: subscriptions,
  });
});

module.exports = { subscribe, upgrade, getActive, getHistory };
