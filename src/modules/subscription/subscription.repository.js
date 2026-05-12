const pool = require('../../shares/database/db');

// ─────────────────────────────────────────────────────────────
// REPOSITORY ABONNEMENT_PLAN — SQL pur, aucune logique métier
// Table : abonnement_plan (id, escort_id, plan_id, date_debut, 
//                          date_fin, nb_publications_utilisees, statut)
// ─────────────────────────────────────────────────────────────

/**
 * Crée un abonnement (appelé dans une transaction).
 */
const create = async (client, { escort_id, plan_id, date_debut, date_fin, statut }) => {
  const query = `
    INSERT INTO abonnement_plan (escort_id, plan_id, date_debut, date_fin, statut)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *;
  `;
  const values = [escort_id, plan_id, date_debut || new Date(), date_fin, statut || 'actif'];
  const { rows } = await client.query(query, values);
  return rows[0];
};

/**
 * Récupère l'abonnement ACTIF d'un escort (le plus récent).
 */
const findActiveByEscortId = async (escortId) => {
  const query = `
    SELECT a.*, p.nom AS plan_nom, p.duree_jours AS plan_duree, p.nb_publications AS plan_nb_publication
    FROM abonnement_plan a
    JOIN plan p ON a.plan_id = p.id
    WHERE a.escort_id = $1 AND a.statut = 'actif'
    ORDER BY a.date_debut DESC
    LIMIT 1;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows[0] || null;
};

/**
 * Récupère l'historique complet des abonnements d'un escort.
 */
const findAllByEscortId = async (escortId) => {
  const query = `
    SELECT a.*, p.nom AS plan_nom, p.nb_publications AS plan_nb_publication
    FROM abonnement_plan a
    JOIN plan p ON a.plan_id = p.id
    WHERE a.escort_id = $1
    ORDER BY a.date_debut DESC;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows;
};

/**
 * Récupère un abonnement par ID.
 */
const findById = async (id) => {
  const query = `
    SELECT a.*, p.nom AS plan_nom, p.nb_publications AS plan_nb_publication
    FROM abonnement_plan a
    JOIN plan p ON a.plan_id = p.id
    WHERE a.id = $1;
  `;
  const { rows } = await pool.query(query, [id]);
  return rows[0] || null;
};

/**
 * Met à jour le statut d'un abonnement.
 */
const updateStatus = async (client, subscriptionId, statut) => {
  const query = `UPDATE abonnement_plan SET statut = $1 WHERE id = $2 RETURNING *;`;
  const { rows } = await client.query(query, [statut, subscriptionId]);
  return rows[0];
};

/**
 * Incrémente le nombre de publications utilisées.
 */
const incrementUsage = async (client, id) => {
  const query = `UPDATE abonnement_plan SET nb_publications_utilisees = nb_publications_utilisees + 1 WHERE id = $1 RETURNING nb_publications_utilisees;`;
  const { rows } = await client.query(query, [id]);
  return rows[0].nb_publications_utilisees;
};

/**
 * Récupère les abonnements expirés.
 */
const findExpired = async () => {
  const query = `
    SELECT * FROM abonnement_plan
    WHERE statut = 'actif' AND date_fin < CURRENT_DATE;
  `;
  const { rows } = await pool.query(query);
  return rows;
};

module.exports = {
  create,
  findActiveByEscortId,
  findAllByEscortId,
  findById,
  updateStatus,
  incrementUsage,
  findExpired,
};
