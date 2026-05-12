const subscriptionRepository = require('./subscription.repository');
const planRepository = require('../plan/plan.repository');
const paymentService = require('../payment/payment.service');
const { executeTransaction } = require('../../shares/database/transaction');
const { addDays, isExpired } = require('../../shares/utils/date');
const { AppError } = require('../../shares/middleware/errorHandler');
const { SUBSCRIPTION_STATUS } = require('./subscription.constants');
const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────────────────
// SERVICE SUBSCRIPTION — MODULE CENTRAL 🔥
//
// Contrôle l'accès premium. C'est LUI qui décide :
//   ✔️ Qui peut publier
//   ✔️ Quand (période active)
//   ✔️ Combien (quota via le plan)
//
// RÈGLES MÉTIER ABSOLUES :
//   ❌ Pas de souscription sans paiement
//   ❌ Pas de double abonnement actif
//   ✔️ Historique conservé (jamais de suppression)
//   ✔️ Expiration automatique par date_fin
// ──────────────────────────────────────────────────────────

/**
 * FLOW COMPLET DE SOUSCRIPTION :
 *
 * 1. Escort choisit un plan
 * 2. Paiement est effectué → payment.service valide la transaction
 * 3. Souscription est créée :
 *    - date_debut = now
 *    - date_fin   = now + plan.duree
 *    - status     = active
 * 4. Escort peut maintenant publier (selon quota du plan)
 */
const subscribe = async ({ escortId, planId, montant, moyen_payement }) => {
  // ── 1. Vérifier qu'il n'a PAS déjà un abonnement actif ──
  const existing = await subscriptionRepository.findActiveByEscortId(escortId);
  if (existing) {
    throw new AppError('Vous avez déjà un abonnement actif. Attendez son expiration ou annulez-le.', 400);
  }

  // ── 2. Vérifier que le plan existe ──
  const plan = await planRepository.findById(planId);
  if (!plan) {
    throw new AppError('Le plan sélectionné est introuvable.', 404);
  }

  // ── 3. Traitement du paiement ──
  // ⚠️ RÈGLE : pas de souscription sans paiement réussi
  const paymentResult = await paymentService.processPayment({
    amount: montant,
    method: moyen_payement,
    escortId,
  });

  if (!paymentResult.success) {
    throw new AppError('Le paiement a échoué. Aucune souscription créée.', 402);
  }

  // ── 4. Créer la souscription dans une TRANSACTION ──
  const subscription = await executeTransaction(async (client) => {
    const date_fin = addDays(new Date(), plan.duree);

    return subscriptionRepository.create(client, {
      date_fin,
      montant,
      status: SUBSCRIPTION_STATUS.ACTIVE,
      moyen_payement,
      id_escort: escortId,
      id_plan: planId,
    });
  });

  logger.info(
    `✅ Souscription #${subscription.id} créée — escort #${escortId} — plan "${plan.nom}" — expire le ${subscription.date_fin}`
  );

  return subscription;
};

/**
 * Récupère l'abonnement actif d'un escort.
 * Retourne null si aucun abonnement actif.
 */
const getActiveSubscription = async (escortId) => {
  const subscription = await subscriptionRepository.findActiveByEscortId(escortId);

  // Vérification supplémentaire : si la date_fin est passée, expirer en temps réel
  if (subscription && isExpired(subscription.date_fin)) {
    await executeTransaction(async (client) => {
      await subscriptionRepository.updateStatus(client, subscription.id, SUBSCRIPTION_STATUS.EXPIRED);
    });
    logger.info(`Souscription #${subscription.id} expirée en temps réel (escort #${escortId})`);
    return null;
  }

  return subscription;
};

/**
 * Récupère l'historique complet des souscriptions (jamais supprimé).
 */
const getSubscriptionHistory = async (escortId) => {
  return subscriptionRepository.findAllByEscortId(escortId);
};

/**
 * Récupère une souscription par son ID.
 */
const getSubscriptionById = async (id) => {
  const subscription = await subscriptionRepository.findById(id);
  if (!subscription) {
    throw new AppError('Souscription introuvable.', 404);
  }
  return subscription;
};

/**
 * JOB CRON — Expire automatiquement les souscriptions dont date_fin < aujourd'hui.
 * Appelé par jobs/subscription.job.js
 *
 * @returns {number} Nombre de souscriptions expirées.
 */
const expireSubscriptions = async () => {
  const expired = await subscriptionRepository.findExpired();

  for (const sub of expired) {
    await executeTransaction(async (client) => {
      await subscriptionRepository.updateStatus(client, sub.id, SUBSCRIPTION_STATUS.EXPIRED);
    });
    logger.info(`⏰ Souscription #${sub.id} expirée automatiquement (escort #${sub.id_escort})`);
  }

  return expired.length;
};

module.exports = {
  subscribe,
  getActiveSubscription,
  getSubscriptionHistory,
  getSubscriptionById,
  expireSubscriptions,
};
