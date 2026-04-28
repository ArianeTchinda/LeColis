const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

// Vérification de la connexion au démarrage
pool.on('connect', () => {
  console.log('✅ Base de données connectée avec succès');
});

pool.on('error', (err) => {
  console.error('❌ Erreur inattendue sur le client Postgres', err);
  process.exit(-1);
});

module.exports = pool;