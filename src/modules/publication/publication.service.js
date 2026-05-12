const publicationRepository = require('./publication.repository');
const subscriptionService = require('../subscription/subscription.service');
const { executeTransaction } = require('../../shares/database/transaction');
const { AppError } = require('../../shares/middleware/errorHandler');
const { PUBLICATION_STATUS } = require('./publication.constants');
const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────────────────
// SERVICE PUBLICATION — LE PLUS CRITIQUE 🔥
//
// AVANT chaque création de publication, on vérifie :
//   1. ✅ Souscription active ?
//   2. ✅ Date_fin non expirée ?
//   3. ✅ Quota de publications respecté ?
//
// SI UNE RÈGLE FAIL → publication REFUSÉE ❌
// ──────────────────────────────────────────────────────────

/**
 * Crée une publication UNIQUEMENT si toutes les règles métier sont respectées.
 *
 * FLOW :
 *   1. Récupérer souscription active (vérifie aussi expiration en temps réel)
 *   2. Compter publications actives de l'escort
 *   3. Vérifier quota du plan
 *   4. Si tout OK → INSERT publication
 */
const createPublication = async ({ titre, description, id_categorie, id_escort }) => {
  // ── RÈGLE 1 : Vérifier souscription active ──
  const subscription = await subscriptionService.getActiveSubscription(id_escort);

  if (!subscription) {
    throw new AppError(
      'Publication impossible : aucun abonnement actif. Veuillez souscrire à un plan.',
      403
    );
  }

  // ── RÈGLE 2 : Vérifier quota du plan ──
  const currentCount = await publicationRepository.countActiveByEscortId(id_escort);
  const maxPublications = subscription.plan_nb_publication;

  if (currentCount >= maxPublications) {
    throw new AppError(
      `Limite de publications atteinte (${currentCount}/${maxPublications}). ` +
      `Votre plan "${subscription.plan_nom}" ne permet pas plus de publications. ` +
      `Passez à un plan supérieur.`,
      403
    );
  }

  // ── RÈGLE 3 : Tout OK → Créer la publication ──
  const publication = await executeTransaction(async (client) => {
    return publicationRepository.create(client, {
      titre,
      description,
      status: PUBLICATION_STATUS.ACTIVE,
      id_categorie: id_categorie || null,
      id_escort,
    });
  });

  logger.info(
    `📢 Publication #${publication.id} créée par escort #${id_escort} ` +
    `(${currentCount + 1}/${maxPublications} publications utilisées)`
  );

  return publication;
};

/**
 * Récupère toutes les publications actives (vitrine publique).
 */
const getActivePublications = async ({ limit, offset } = {}) => {
  return publicationRepository.findAllActive({ limit, offset });
};

/**
 * Récupère les publications d'un escort (toutes, actives ou non).
 */
const getPublicationsByEscort = async (escortId) => {
  return publicationRepository.findByEscortId(escortId);
};

/**
 * Récupère une publication par ID.
 */
const getPublicationById = async (id) => {
  const publication = await publicationRepository.findById(id);
  if (!publication) {
    throw new AppError('Publication introuvable.', 404);
  }
  return publication;
};

/**
 * Supprime une publication.
 */
const deletePublication = async (id, escortId) => {
  const publication = await publicationRepository.findById(id);

  if (!publication) {
    throw new AppError('Publication introuvable.', 404);
  }

  // Vérifier que l'escort est bien le propriétaire
  if (publication.id_escort !== parseInt(escortId, 10)) {
    throw new AppError('Vous ne pouvez supprimer que vos propres publications.', 403);
  }

  return publicationRepository.remove(id);
};

/**
 * JOB CRON — Désactive les publications des escorts dont la souscription vient d'expirer.
 */
const deactivateExpiredPublications = async (escortId) => {
  const deactivated = await publicationRepository.deactivateAllByEscortId(escortId);
  if (deactivated.length > 0) {
    logger.info(`🔒 ${deactivated.length} publication(s) désactivée(s) pour escort #${escortId}`);
  }
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
