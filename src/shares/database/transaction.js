const pool = require('./db');

/**
 * Exécute un callback dans une transaction PostgreSQL.
 * Gère automatiquement BEGIN, COMMIT et ROLLBACK.
 *
 * @param {Function} callback - Fonction async recevant le client PG.
 * @returns {*} Résultat du callback.
 */
const executeTransaction = async (callback) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = { executeTransaction };
