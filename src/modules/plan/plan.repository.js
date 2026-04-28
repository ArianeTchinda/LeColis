const pool = require('../../shared/database/db');

// ─────────────────────────────────────────────
// REPOSITORY PLAN — SQL pur, aucune logique métier
// Table : plan (id, nom, duree, nb_publication)
// ─────────────────────────────────────────────

const findAll = async () => {
  const { rows } = await pool.query('SELECT * FROM plan ORDER BY id ASC;');
  return rows;
};

const findById = async (id) => {
  const { rows } = await pool.query('SELECT * FROM plan WHERE id = $1;', [id]);
  return rows[0] || null;
};

const create = async ({ nom, duree, nb_publication }) => {
  const query = `
    INSERT INTO plan (nom, duree, nb_publication)
    VALUES ($1, $2, $3)
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [nom, duree, nb_publication]);
  return rows[0];
};

const update = async (id, { nom, duree, nb_publication }) => {
  const query = `
    UPDATE plan
    SET nom = $1, duree = $2, nb_publication = $3
    WHERE id = $4
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [nom, duree, nb_publication, id]);
  return rows[0] || null;
};

const remove = async (id) => {
  const { rows } = await pool.query('DELETE FROM plan WHERE id = $1 RETURNING *;', [id]);
  return rows[0] || null;
};

module.exports = { findAll, findById, create, update, remove };
