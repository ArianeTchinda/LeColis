const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────
// PAYMENT REPOSITORY — Traçabilité des paiements
// Note : pas de table `payment` dans le schéma actuel,
// les infos sont dans `souscription`.
// Ce repository prépare la future table payment.
// ──────────────────────────────────────────────

/**
 * Enregistre un log de paiement.
 * TODO : Créer une table `payment` pour traçabilité complète.
 */
const logPayment = async ({ transactionId, amount, method, escortId, status }) => {
  logger.info(`[Payment] ${status} — ${amount} XAF — ${method} — escort #${escortId} — txn: ${transactionId}`);
  return { transactionId, amount, method, escortId, status };
};

module.exports = { logPayment };
