const { AppError } = require('../../shared/middleware/errorHandler');

/**
 * Valide la création / mise à jour d'un plan.
 */
const validatePlan = (req, res, next) => {
  const { nom, duree, nb_publication } = req.body;

  if (!nom || !nom.trim()) {
    return next(new AppError('Le champ "nom" est requis.', 400));
  }

  if (duree === undefined || duree === null) {
    return next(new AppError('Le champ "duree" est requis.', 400));
  }

  if (!Number.isInteger(Number(duree)) || Number(duree) <= 0) {
    return next(new AppError('"duree" doit être un entier positif (nombre de jours).', 400));
  }

  if (nb_publication === undefined || nb_publication === null) {
    return next(new AppError('Le champ "nb_publication" est requis.', 400));
  }

  if (!Number.isInteger(Number(nb_publication)) || Number(nb_publication) <= 0) {
    return next(new AppError('"nb_publication" doit être un entier positif.', 400));
  }

  // Normaliser les types
  req.body.duree = parseInt(duree, 10);
  req.body.nb_publication = parseInt(nb_publication, 10);
  req.body.nom = nom.trim();

  next();
};

module.exports = { validatePlan };
