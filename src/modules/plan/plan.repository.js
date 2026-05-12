const pool = require('../../shares/database/db');

// ─────────────────────────────────────────────
// REPOSITORY PLAN — SQL pur, aucune logique métier
// Table : plan (id, nom, nb_publications, duree_jours, prix, description, statut)
// ─────────────────────────────────────────────

const findAll = async () => {
  const { rows } = await pool.query('SELECT * FROM plan WHERE actif = TRUE ORDER BY prix ASC;');
  return rows;
};

const findById = async (id) => {
  const { rows } = await pool.query('SELECT * FROM plan WHERE id = $1;', [id]);
  return rows[0] || null;
};

const create = async ({ nom, nb_publications, duree_jours, prix, description }) => {
  const query = `
    INSERT INTO plan (nom, nb_publications, duree_jours, prix, description)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [nom, nb_publications, duree_jours, prix, description]);
  return rows[0];
};

const update = async (id, { nom, nb_publications, duree_jours, prix, description, actif }) => {
  const query = `
    UPDATE plan
    SET nom = COALESCE($1, nom), nb_publications = COALESCE($2, nb_publications), 
        duree_jours = COALESCE($3, duree_jours), prix = COALESCE($4, prix), 
        description = COALESCE($5, description), actif = COALESCE($6, actif)
    WHERE id = $7
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [nom, nb_publications, duree_jours, prix, description, actif, id]);
  return rows[0] || null;
};

const remove = async (id) => {
  const { rows } = await pool.query('DELETE FROM plan WHERE id = $1 RETURNING *;', [id]);
  return rows[0] || null;
};

module.exports = { findAll, findById, create, update, remove };
