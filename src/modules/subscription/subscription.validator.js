const { AppError } = require('../../shared/middleware/errorHandler');
const { PAYMENT_METHODS } = require('./subscription.constants');

/**
 * Valide la création d'une souscription.
 */
const validateSubscription = (req, res, next) => {
  const { escortId, planId, montant, moyen_payement } = req.body;

  if (!escortId) {
    return next(new AppError('Le champ "escortId" est requis.', 400));
  }
  if (!Number.isInteger(Number(escortId))) {
    return next(new AppError('"escortId" doit être un entier.', 400));
  }

  if (!planId) {
    return next(new AppError('Le champ "planId" est requis.', 400));
  }
  if (!Number.isInteger(Number(planId))) {
    return next(new AppError('"planId" doit être un entier.', 400));
  }

  if (montant === undefined || montant === null) {
    return next(new AppError('Le champ "montant" est requis.', 400));
  }
  if (isNaN(Number(montant)) || Number(montant) <= 0) {
    return next(new AppError('"montant" doit être un nombre positif.', 400));
  }

  if (!moyen_payement || !moyen_payement.trim()) {
    return next(new AppError('Le champ "moyen_payement" est requis.', 400));
  }

  const validMethods = Object.values(PAYMENT_METHODS);
  if (!validMethods.includes(moyen_payement)) {
    return next(new AppError(
      `"moyen_payement" invalide. Valeurs acceptées : ${validMethods.join(', ')}`,
      400
    ));
  }

  // Normaliser
  req.body.escortId = parseInt(escortId, 10);
  req.body.planId = parseInt(planId, 10);
  req.body.montant = parseFloat(montant);

  next();
};

module.exports = { validateSubscription };
