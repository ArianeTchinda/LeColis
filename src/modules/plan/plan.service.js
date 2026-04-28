const planRepository = require('./plan.repository');
const { AppError } = require('../../shared/middleware/errorHandler');
const logger = require('../../shared/utils/logger');

// ──────────────────────────────────────────────
// SERVICE PLAN — Table statique de configuration
// Pas de logique utilisateur, juste CRUD admin
// ──────────────────────────────────────────────

/**
 * Récupère tous les plans disponibles.
 */
const getAllPlans = async () => {
  return planRepository.findAll();
};

/**
 * Récupère un plan par son ID.
 */
const getPlanById = async (id) => {
  const plan = await planRepository.findById(id);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  return plan;
};

/**
 * Crée un nouveau plan (admin uniquement).
 */
const createPlan = async ({ nom, duree, nb_publication }) => {
  const plan = await planRepository.create({ nom, duree, nb_publication });
  logger.info(`Plan créé : "${plan.nom}" (durée: ${plan.duree}j, publications: ${plan.nb_publication})`);
  return plan;
};

/**
 * Met à jour un plan existant (admin uniquement).
 */
const updatePlan = async (id, { nom, duree, nb_publication }) => {
  const plan = await planRepository.update(id, { nom, duree, nb_publication });
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  logger.info(`Plan #${id} mis à jour : "${plan.nom}"`);
  return plan;
};

/**
 * Supprime un plan (admin uniquement).
 */
const deletePlan = async (id) => {
  const plan = await planRepository.remove(id);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  logger.info(`Plan #${id} supprimé : "${plan.nom}"`);
  return plan;
};

module.exports = { getAllPlans, getPlanById, createPlan, updatePlan, deletePlan };
