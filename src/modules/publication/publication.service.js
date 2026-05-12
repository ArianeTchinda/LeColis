const publicationRepository = require('./publication.repository');
const subscriptionService = require('../subscription/subscription.service');
const subscriptionRepository = require('../subscription/subscription.repository');
const { executeTransaction } = require('../../shares/database/transaction');
const { AppError } = require('../../shares/middleware/errorHandler');
const logger = require('../../shares/utils/logger');

/**
 * @swagger
 * /api/v1/publications:
 *   post:
 *     summary: Créer une publication
 *     tags: [Publications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [titre, description]
 *             properties:
 *               titre: { type: string }
 *               description: { type: string }
 *               montant: { type: number }
 *               duree: { type: integer }
 *     responses:
 *       201:
 *         description: Publication créée
 */
const createPublication = async ({ titre, description, montant, duree, id_escort }) => {
  const subscription = await subscriptionService.getActiveSubscription(id_escort);

  if (!subscription) {
    throw new AppError('Aucun abonnement actif.', 403);
  }

  const currentCount = subscription.nb_publications_utilisees;
  const maxPublications = subscription.plan_nb_publication;

  if (currentCount >= maxPublications) {
    throw new AppError(`Quota de publications atteint (${currentCount}/${maxPublications}).`, 403);
  }

  const publication = await executeTransaction(async (client) => {
    // 1. Incrémenter l'usage
    await subscriptionRepository.incrementUsage(client, subscription.id);
    
    // 2. Créer la publication
    return publicationRepository.create(client, {
      escort_id: id_escort,
      abonnement_plan_id: subscription.id,
      titre,
      description,
      statut: 'actif',
      montant,
      duree
    });
  });

  logger.info(`📢 Publication #${publication.id} créée par escort #${id_escort}`);
  return publication;
};

/**
 * @swagger
 * /api/v1/publications:
 *   get:
 *     summary: Récupérer les publications actives
 *     tags: [Publications]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer }
 *       - in: query
 *         name: offset
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Liste des publications
 */
const getActivePublications = async ({ limit, offset } = {}) => {
  return publicationRepository.findAllActive({ limit, offset });
};

const getPublicationsByEscort = async (escortId) => {
  return publicationRepository.findByEscortId(escortId);
};

const getPublicationById = async (id) => {
  const publication = await publicationRepository.findById(id);
  if (!publication) {
    throw new AppError('Publication introuvable.', 404);
  }
  // On incrémente les vues de manière asynchrone (pas grave si ça fail ou si c'est lent)
  publicationRepository.incrementViews(id).catch(err => logger.error("Erreur increment views", err));
  
  return publication;
};

const deletePublication = async (id, escortId) => {
  const publication = await publicationRepository.findById(id);
  if (!publication) {
    throw new AppError('Publication introuvable.', 404);
  }

  if (publication.escort_id !== parseInt(escortId, 10)) {
    throw new AppError('Non autorisé.', 403);
  }

  return publicationRepository.remove(id);
};

const deactivateExpiredPublications = async (escortId) => {
  const deactivated = await publicationRepository.deactivateAllByEscortId(escortId);
  return deactivated.length;
};

module.exports = {
  createPublication,
  getActivePublications,
  getPublicationsByEscort,
  getPublicationById,
  deletePublication,
  deactivateExpiredPublications,
};
