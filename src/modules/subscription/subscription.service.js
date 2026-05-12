const subscriptionRepository = require('./subscription.repository');
const planRepository = require('../plan/plan.repository');
const { executeTransaction } = require('../../shares/database/transaction');
const { addDays, isExpired } = require('../../shares/utils/date');
const { AppError } = require('../../shares/middleware/errorHandler');
const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────────────────
// SERVICE SUBSCRIPTION — MODULE CENTRAL v2.0
// ──────────────────────────────────────────────────────────

/**
 * FLOW DE SOUSCRIPTION v2.0 :
 * 1. Vérifier si un abonnement actif existe déjà.
 * 2. Créer l'abonnement.
 */
const subscribe = async ({ escortId, planId }) => {
  const existing = await subscriptionRepository.findActiveByEscortId(escortId);
  if (existing) {
    throw new AppError('Vous avez déjà un abonnement actif.', 400);
  }

  const plan = await planRepository.findById(planId);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }

  const subscription = await executeTransaction(async (client) => {
    const date_fin = addDays(new Date(), plan.duree_jours);
    return subscriptionRepository.create(client, {
      escort_id: escortId,
      plan_id: planId,
      date_debut: new Date(),
      date_fin,
      statut: 'actif'
    });
  });

  logger.info(`✅ Abonnement #${subscription.id} créé pour escort #${escortId}`);
  return subscription;
};

const upgradeSubscription = async ({ escortId, newPlanId }) => {
  const current = await subscriptionRepository.findActiveByEscortId(escortId);
  
  const newPlan = await planRepository.findById(newPlanId);
  if (!newPlan) {
    throw new AppError('Le nouveau plan est introuvable.', 404);
  }

  const subscription = await executeTransaction(async (client) => {
    // 1. Si un abonnement existe, on le marque comme annulé (pour historique)
    if (current) {
      await subscriptionRepository.updateStatus(client, current.id, 'annulé');
      logger.info(`🚫 Abonnement #${current.id} annulé pour upgrade (escort #${escortId})`);
    }

    // 2. Créer le nouvel abonnement
    const date_fin = addDays(new Date(), newPlan.duree_jours);
    return subscriptionRepository.create(client, {
      escort_id: escortId,
      plan_id: newPlanId,
      date_debut: new Date(),
      date_fin,
      statut: 'actif'
    });
  });

  logger.info(`🚀 Upgrade réussi ! Nouvel abonnement #${subscription.id} (Plan: ${newPlan.nom})`);
  return subscription;
};

const getActiveSubscription = async (escortId) => {
  const subscription = await subscriptionRepository.findActiveByEscortId(escortId);

  if (subscription && isExpired(subscription.date_fin)) {
    await executeTransaction(async (client) => {
      await subscriptionRepository.updateStatus(client, subscription.id, 'expiré');
    });
    logger.info(`Abonnement #${subscription.id} expiré (escort #${escortId})`);
    return null;
  }

  return subscription;
};

const getSubscriptionHistory = async (escortId) => {
  return subscriptionRepository.findAllByEscortId(escortId);
};

const expireSubscriptions = async () => {
  const expired = await subscriptionRepository.findExpired();

  for (const sub of expired) {
    await executeTransaction(async (client) => {
      await subscriptionRepository.updateStatus(client, sub.id, 'expiré');
    });
  }

  return expired.length;
};

module.exports = {
  subscribe,
  upgradeSubscription,
  getActiveSubscription,
  getSubscriptionHistory,
  expireSubscriptions,
};
