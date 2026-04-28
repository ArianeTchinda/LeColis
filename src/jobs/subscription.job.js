const subscriptionService = require('../modules/subscription/subscription.service');
const publicationService = require('../modules/publication/publication.service');
const subscriptionRepository = require('../modules/subscription/subscription.repository');
const logger = require('../shared/utils/logger');

// ──────────────────────────────────────────────
// JOB CRON — Expiration automatique
//
// 1. Expire les souscriptions dont date_fin < aujourd'hui
// 2. Désactive les publications des escorts concernés
// ──────────────────────────────────────────────

const runExpireSubscriptions = async () => {
  try {
    logger.info('⏰ [CRON] Début du job d\'expiration...');

    // Étape 1 : Récupérer les souscriptions à expirer AVANT de les mettre à jour
    const toExpire = await subscriptionRepository.findExpired();

    // Étape 2 : Expirer les souscriptions
    const expiredCount = await subscriptionService.expireSubscriptions();

    // Étape 3 : Désactiver les publications des escorts concernés
    let pubsDeactivated = 0;
    for (const sub of toExpire) {
      const count = await publicationService.deactivateExpiredPublications(sub.id_escort);
      pubsDeactivated += count;
    }

    logger.info(
      `✅ [CRON] Terminé — ${expiredCount} souscription(s) expirée(s), ${pubsDeactivated} publication(s) désactivée(s)`
    );
  } catch (error) {
    logger.error(`❌ [CRON] Erreur: ${error.message}`);
  }
};

module.exports = { runExpireSubscriptions };
