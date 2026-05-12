const db = require('../../shares/database/config');

const createNotification = async (io, data) => {
  const { message, id_escort, id_admin } = data;

  try {
    // 1. Sauvegarde en Base de données (uniquement tes colonnes)
    const query = `
      INSERT INTO notification (message, id_escort, id_admin)
      VALUES ($1, $2, $3)
      RETURNING *;
    `;
    const result = await db.query(query, [message, id_escort, id_admin]);
    const notif = result.rows[0];

    // 2. Envoi Temps Réel
    if (id_admin) {
      // Si id_admin est rempli, on notifie les admins
      io.to('admins').emit('new_notification', notif);
    } 
    
    if (id_escort) {
      // Si id_escort est rempli, on notifie l'escorte sur sa room privée
      io.to(`escort_${id_escort}`).emit('new_notification', notif);
    }

    return notif;
  } catch (error) {
    console.error("Erreur Notification Service:", error);
  }
};

module.exports = { createNotification };