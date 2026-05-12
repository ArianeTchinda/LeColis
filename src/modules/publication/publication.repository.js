const pool = require('../../shares/database/db');

// ──────────────────────────────────────────────────────────
// REPOSITORY PUBLICATION — SQL pur, aucune logique métier
// Table : publication (id, titre, description, status,
//                      id_categorie, id_escort)
// ──────────────────────────────────────────────────────────

/**
 * Crée une publication (appelé dans une transaction).
 */
const create = async (client, { titre, description, status, id_categorie, id_escort }) => {
  const query = `
    INSERT INTO publication (titre, description, status, id_categorie, id_escort)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *;
  `;
  const { rows } = await client.query(query, [titre, description, status, id_categorie, id_escort]);
  return rows[0];
};

/**
 * Récupère une publication par ID avec jointures.
 */
const findById = async (id) => {
  const query = `
    SELECT p.*, c.nom AS categorie_nom, e.pseudo AS escort_pseudo
    FROM publication p
    LEFT JOIN categorie c ON p.id_categorie = c.id
    LEFT JOIN escort e ON p.id_escort = e.id
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
    SELECT p.*, c.nom AS categorie_nom, e.pseudo AS escort_pseudo
    FROM publication p
    LEFT JOIN categorie c ON p.id_categorie = c.id
    LEFT JOIN escort e ON p.id_escort = e.id
    WHERE p.status = 'active'
    ORDER BY p.id DESC
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
    SELECT p.*, c.nom AS categorie_nom
    FROM publication p
    LEFT JOIN categorie c ON p.id_categorie = c.id
    WHERE p.id_escort = $1
    ORDER BY p.id DESC;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows;
};

/**
 * Met à jour le statut d'une publication.
 */
const updateStatus = async (id, status) => {
  const query = `UPDATE publication SET status = $1 WHERE id = $2 RETURNING *;`;
  const { rows } = await pool.query(query, [status, id]);
  return rows[0] || null;
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
  const query = `SELECT COUNT(*)::int AS count FROM publication WHERE id_escort = $1 AND status = 'active';`;
  const { rows } = await pool.query(query, [escortId]);
  return rows[0].count;
};

/**
 * Désactive toutes les publications d'un escort (quand souscription expire).
 */
const deactivateAllByEscortId = async (escortId) => {
  const query = `
    UPDATE publication SET status = 'inactive'
    WHERE id_escort = $1 AND status = 'active'
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
  remove,
  countActiveByEscortId,
  deactivateAllByEscortId,
};
