const { AppError } = require('../../shares/middleware/errorHandler');

/**
 * Valide la création d'une publication.
 */
const validatePublication = (req, res, next) => {
  const { titre, description, id_escort } = req.body;

  if (!titre || !titre.trim()) {
    return next(new AppError('Le champ "titre" est requis.', 400));
  }

  if (titre.length > 255) {
    return next(new AppError('Le titre ne doit pas dépasser 255 caractères.', 400));
  }

  if (!description || !description.trim()) {
    return next(new AppError('Le champ "description" est requis.', 400));
  }

  if (!id_escort) {
    return next(new AppError('Le champ "id_escort" est requis.', 400));
  }

  if (!Number.isInteger(Number(id_escort))) {
    return next(new AppError('"id_escort" doit être un entier.', 400));
  }

  // Normaliser
  req.body.titre = titre.trim();
  req.body.description = description.trim();
  req.body.id_escort = parseInt(id_escort, 10);
  if (req.body.id_categorie) {
    req.body.id_categorie = parseInt(req.body.id_categorie, 10);
  }

  next();
};

module.exports = { validatePublication };
