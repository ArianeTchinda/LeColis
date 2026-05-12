const pool = require('../../shares/database/db');

// ──────────────────────────────────────────────────────────
// REPOSITORY PUBLICATION — SQL pur, aucune logique métier
// Table : publication (id, escort_id, abonnement_plan_id, 
//                      titre, description, statut, montant, 
//                      duree, vh_publication)
// ──────────────────────────────────────────────────────────

/**
 * Crée une publication (appelé dans une transaction).
 */
const create = async (client, { escort_id, abonnement_plan_id, titre, description, statut, montant, duree }) => {
  const query = `
    INSERT INTO publication (escort_id, abonnement_plan_id, titre, description, statut, montant, duree)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *;
  `;
  const { rows } = await client.query(query, [escort_id, abonnement_plan_id, titre, description, statut || 'actif', montant, duree]);
  return rows[0];
};

/**
 * Récupère une publication par ID avec jointures.
 */
const findById = async (id) => {
  const query = `
    SELECT p.*, u.pseudonyme AS escort_pseudo
    FROM publication p
    JOIN escort e ON p.escort_id = e.id
    JOIN utilisateur u ON e.utilisateur_id = u.id
    WHERE p.id = $1;
  `;
  const { rows } = await pool.query(query, [id]);
  return rows[0] || null;
};

/**
 * Récupère toutes les publications actives (vitrine publique).
 */
const findAllActive = async ({ limit = 50, offset = 0 } = {}) => {
  const query = `
    SELECT p.*, u.pseudonyme AS escort_pseudo, u.age, l.ville
    FROM publication p
    JOIN escort e ON p.escort_id = e.id
    JOIN utilisateur u ON e.utilisateur_id = u.id
    LEFT JOIN localisation l ON e.localisation_id = l.id
    WHERE p.statut = 'actif'
    ORDER BY p.created_at DESC
    LIMIT $1 OFFSET $2;
  `;
  const { rows } = await pool.query(query, [limit, offset]);
  return rows;
};

/**
 * Récupère les publications d'un escort.
 */
const findByEscortId = async (escortId) => {
  const query = `
    SELECT * FROM publication 
    WHERE escort_id = $1
    ORDER BY created_at DESC;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows;
};

/**
 * Met à jour le statut d'une publication.
 */
const updateStatus = async (id, statut) => {
  const query = `UPDATE publication SET statut = $1 WHERE id = $2 RETURNING *;`;
  const { rows } = await pool.query(query, [statut, id]);
  return rows[0] || null;
};

/**
 * Incrémente le nombre de vues.
 */
const incrementViews = async (id) => {
  const query = `UPDATE publication SET vh_publication = vh_publication + 1 WHERE id = $1 RETURNING vh_publication;`;
  const { rows } = await pool.query(query, [id]);
  return rows[0] ? rows[0].vh_publication : 0;
};

/**
 * Supprime une publication.
 */
const remove = async (id) => {
  const { rows } = await pool.query('DELETE FROM publication WHERE id = $1 RETURNING *;', [id]);
  return rows[0] || null;
};

/**
 * Compte les publications ACTIVES d'un escort (pour vérifier le quota).
 */
const countActiveByEscortId = async (escortId) => {
  const query = `SELECT COUNT(*)::int AS count FROM publication WHERE escort_id = $1 AND statut = 'actif';`;
  const { rows } = await pool.query(query, [escortId]);
  return rows[0].count;
};

/**
 * Désactive toutes les publications d'un escort (quand souscription expire).
 */
const deactivateAllByEscortId = async (escortId) => {
  const query = `
    UPDATE publication SET statut = 'inactif'
    WHERE escort_id = $1 AND statut = 'actif'
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows;
};

module.exports = {
  create,
  findById,
  findAllActive,
  findByEscortId,
  updateStatus,
  incrementViews,
  remove,
  countActiveByEscortId,
  deactivateAllByEscortId,
};
