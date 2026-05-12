const planRepository = require('./plan.repository');
const { AppError } = require('../../shares/middleware/errorHandler');
const logger = require('../../shares/utils/logger');

// ──────────────────────────────────────────────
// SERVICE PLAN — v2.0
// ──────────────────────────────────────────────

const getAllPlans = async () => {
  return planRepository.findAll();
};

const getPlanById = async (id) => {
  const plan = await planRepository.findById(id);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  return plan;
};

const createPlan = async (data) => {
  const plan = await planRepository.create(data);
  logger.info(`Plan créé : "${plan.nom}"`);
  return plan;
};

const updatePlan = async (id, data) => {
  const plan = await planRepository.update(id, data);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  logger.info(`Plan #${id} mis à jour : "${plan.nom}"`);
  return plan;
};

const deletePlan = async (id) => {
  const plan = await planRepository.remove(id);
  if (!plan) {
    throw new AppError('Plan introuvable.', 404);
  }
  logger.info(`Plan #${id} supprimé : "${plan.nom}"`);
  return plan;
};

module.exports = { getAllPlans, getPlanById, createPlan, updatePlan, deletePlan };
