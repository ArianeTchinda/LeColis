const { Pool } = require('pg');
require('dotenv').config();

// On crée une instance de Pool (une seule fois pour toute l'app)
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
  // Options de gestion du Pool
  max: 20, // Nombre maximum de clients dans le pool
  idleTimeoutMillis: 30000, // Temps avant de fermer une connexion inactive
  connectionTimeoutMillis: 2000, // Temps max pour établir une connexion
});

// Petit log au démarrage uniquement
console.log('✅ Pool de connexions PostgreSQL initialisé');

// On exporte une fonction query personnalisée
module.exports = {
  query: (text, params) => {
    // On utilise le pool pour exécuter la requête
    return pool.query(text, params);
  },
  pool // Au cas où tu aurais besoin d'accéder au pool directement plus tard
};