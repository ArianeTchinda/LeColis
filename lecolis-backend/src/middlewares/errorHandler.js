// src/middlewares/errorHandler.js

function errorHandler(err, req, res, next) {
  console.error('[ERROR]', err.message);

  // Erreurs Prisma connues
  if (err.code === 'P2002') {
    const field = err.meta?.target?.join(', ') || 'champ';
    return res.status(409).json({ message: `${field} déjà utilisé.` });
  }
  if (err.code === 'P2025') {
    return res.status(404).json({ message: 'Ressource introuvable.' });
  }

  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    message: err.message || 'Erreur interne du serveur.',
  });
}

module.exports = errorHandler;
