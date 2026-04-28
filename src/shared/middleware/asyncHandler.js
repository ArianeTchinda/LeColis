/**
 * Wrapper pour les fonctions async des contrôleurs Express.
 * Attrape automatiquement les rejections et les transmet au errorHandler.
 *
 * @param {Function} fn - Contrôleur async (req, res, next).
 * @returns {Function} Middleware Express.
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = asyncHandler;
