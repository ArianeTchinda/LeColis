const paymentGateway = require('./payment.gateway');
const paymentRepository = require('./payment.repository');
const logger = require('../../shares/utils/logger');
const { AppError } = require('../../shares/middleware/errorHandler');

// ──────────────────────────────────────────────
// SERVICE PAYMENT — Validation financière
// Rôle :
//   1. Valider la transaction
//   2. Logger le résultat
//   3. Retourner success/fail au service subscription
//
// ⚠️ UN PAIEMENT RÉUSSI = souscription activée
// ⚠️ UN PAIEMENT ÉCHOUÉ = aucune action
// ──────────────────────────────────────────────

/**
 * Traite un paiement pour une souscription.
 *
 * @param {object} params
 * @param {number} params.amount - Montant en XAF.
 * @param {string} params.method - Moyen de paiement (mobile_money, orange_money, etc.).
 * @param {number} params.escortId - ID de l'escort qui paie.
 * @returns {object} { success, transactionId }
 */
const processPayment = async ({ amount, method, escortId }) => {
  // Validation de base
  if (!amount || amount <= 0) {
    throw new AppError('Le montant du paiement doit être supérieur à 0.', 400);
  }

  const reference = `SUB_${escortId}_${Date.now()}`;

  try {
    // 1. Appel au gateway de paiement
    const result = await paymentGateway.initiatePayment({ amount, method, reference });

    // 2. Logger le résultat
    await paymentRepository.logPayment({
      transactionId: result.transactionId,
      amount,
      method,
      escortId,
      status: result.success ? 'success' : 'failed',
    });

    if (!result.success) {
      logger.warn(`Paiement échoué pour escort #${escortId} — ${amount} XAF`);
    }

    return result;
  } catch (error) {
    logger.error(`Erreur paiement escort #${escortId}: ${error.message}`);
    return { success: false, error: error.message };
  }
};

module.exports = { processPayment };
