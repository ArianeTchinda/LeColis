const pool = require('../../shares/database/db');

// ─────────────────────────────────────────────────────────────
// REPOSITORY SOUSCRIPTION — SQL pur, aucune logique métier
// Table : souscription (id, date_debut, date_fin, montant,
//                        status, moyen_payement, id_escort, id_plan)
// ─────────────────────────────────────────────────────────────

/**
 * Crée une souscription (appelé dans une transaction).
 * @param {object} client - Client PG transactionnel.
 */
const create = async (client, { date_fin, montant, status, moyen_payement, id_escort, id_plan }) => {
  const query = `
    INSERT INTO souscription (date_fin, montant, status, moyen_payement, id_escort, id_plan)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *;
  `;
  const values = [date_fin, montant, status, moyen_payement, id_escort, id_plan];
  const { rows } = await client.query(query, values);
  return rows[0];
};

/**
 * Récupère la souscription ACTIVE d'un escort (la plus récente).
 */
const findActiveByEscortId = async (escortId) => {
  const query = `
    SELECT s.*, p.nom AS plan_nom, p.duree AS plan_duree, p.nb_publication AS plan_nb_publication
    FROM souscription s
    LEFT JOIN plan p ON s.id_plan = p.id
    WHERE s.id_escort = $1 AND s.status = 'active'
    ORDER BY s.date_debut DESC
    LIMIT 1;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows[0] || null;
};

/**
 * Récupère l'historique complet des souscriptions d'un escort.
 */
const findAllByEscortId = async (escortId) => {
  const query = `
    SELECT s.*, p.nom AS plan_nom, p.duree AS plan_duree, p.nb_publication AS plan_nb_publication
    FROM souscription s
    LEFT JOIN plan p ON s.id_plan = p.id
    WHERE s.id_escort = $1
    ORDER BY s.date_debut DESC;
  `;
  const { rows } = await pool.query(query, [escortId]);
  return rows;
};

/**
 * Récupère une souscription par ID.
 */
const findById = async (id) => {
  const query = `
    SELECT s.*, p.nom AS plan_nom, p.duree AS plan_duree, p.nb_publication AS plan_nb_publication
    FROM souscription s
    LEFT JOIN plan p ON s.id_plan = p.id
    WHERE s.id = $1;
  `;
  const { rows } = await pool.query(query, [id]);
  return rows[0] || null;
};

/**
 * Met à jour le statut d'une souscription (appelé dans une transaction).
 */
const updateStatus = async (client, subscriptionId, status) => {
  const query = `UPDATE souscription SET status = $1 WHERE id = $2 RETURNING *;`;
  const { rows } = await client.query(query, [status, subscriptionId]);
  return rows[0];
};

/**
 * Récupère toutes les souscriptions actives dont la date_fin est dépassée.
 * (Pour le job CRON d'expiration)
 */
const findExpired = async () => {
  const query = `
    SELECT * FROM souscription
    WHERE status = 'active' AND date_fin < CURRENT_DATE;
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
  findExpired,
};
