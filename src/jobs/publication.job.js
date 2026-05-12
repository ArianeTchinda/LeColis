const publicationRepository = require('../modules/publication/publication.repository');
const subscriptionRepository = require('../modules/subscription/subscription.repository');
const logger = require('../shares/utils/logger');

/**
 * Job de désactivation des publications quand la souscription expire.
 * À appeler après le job d'expiration des souscriptions.
 */
const runDeactivatePublications = async () => {
  try {
    logger.info('[CRON] Début du job de désactivation des publications...');

    // Récupérer les souscriptions fraîchement expirées
    const expired = await subscriptionRepository.findExpired();

    for (const sub of expired) {
      await publicationRepository.deactivateAllByEscortId(sub.id_escort);
      logger.info(`[CRON] Publications désactivées pour escort #${sub.id_escort}`);
    }

    logger.info(`[CRON] Job de désactivation terminé.`);
  } catch (error) {
    logger.error(`[CRON] Erreur lors de la désactivation des publications: ${error.message}`);
  }
};

module.exports = { runDeactivatePublications };
