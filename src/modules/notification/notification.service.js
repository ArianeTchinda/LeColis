const db = require('../../shares/database/config');

const createNotification = async (io, data) => {
  const { message, id_escort, id_admin } = data;

  try {
    const query = `
      INSERT INTO notification (message, id_escort, id_admin, is_read)
      VALUES ($1, $2, $3, FALSE)
      RETURNING *;
    `;
    const result = await db.query(query, [message, id_escort, id_admin]);
    const notif = result.rows[0];

    if (id_admin) {
      io.to('admins').emit('new_notification', notif);
    } 
    
    if (id_escort) {
      io.to(`escort_${id_escort}`).emit('new_notification', notif);
    }

    return notif;
  } catch (error) {
    console.error("Erreur Notification Service:", error);
  }
};

module.exports = { createNotification };