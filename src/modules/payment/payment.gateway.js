const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────
// PAYMENT GATEWAY — Abstraction du provider
// À remplacer par l'intégration réelle
// (Orange Money, MTN MoMo, Stripe, etc.)
// ──────────────────────────────────────────────

/**
 * Initie un paiement auprès du provider.
 *
 * @param {object} params
 * @param {number} params.amount - Montant en XAF.
 * @param {string} params.method - Méthode de paiement.
 * @param {string} params.reference - Référence unique.
 * @returns {object} { success, transactionId, reference }
 */
const initiatePayment = async ({ amount, method, reference }) => {
  logger.info(`[PaymentGateway] Paiement: ${amount} XAF via ${method} (ref: ${reference})`);

  // ⚠️ TODO: Remplacer par l'appel API réel
  // Exemple: Orange Money API, MTN MoMo API, etc.

  // Simulation d'un paiement réussi pour le développement
  return {
    success: true,
    transactionId: `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
    reference,
  };
};

module.exports = { initiatePayment };
