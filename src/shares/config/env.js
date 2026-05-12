require('dotenv').config();

const env = {
  port: process.env.PORT || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',

  db: {
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    name: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT || 5432,
  },

  // Ajouter ici les clés API de paiement, etc.
  // payment: {
  //   apiKey: process.env.PAYMENT_API_KEY,
  //   secretKey: process.env.PAYMENT_SECRET_KEY,
  // },
};

module.exports = env;
