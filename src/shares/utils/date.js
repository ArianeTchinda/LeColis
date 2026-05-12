/**
 * Utilitaires de date pour le calcul de durées d'abonnement.
 */

/**
 * Ajoute un nombre de jours à une date.
 * @param {Date} date - Date de départ.
 * @param {number} days - Nombre de jours à ajouter.
 * @returns {Date} Nouvelle date.
 */
const addDays = (date, days) => {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
};

/**
 * Vérifie si une date est dans le passé.
 * @param {Date|string} date - Date à vérifier.
 * @returns {boolean}
 */
const isExpired = (date) => {
  return new Date(date) < new Date();
};

/**
 * Formate une date en YYYY-MM-DD.
 * @param {Date} date
 * @returns {string}
 */
const formatDate = (date) => {
  return new Date(date).toISOString().split('T')[0];
};

module.exports = { addDays, isExpired, formatDate };
