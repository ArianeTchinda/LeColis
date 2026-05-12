const db = require('../../shares/database/config');

const getMyNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type; 

    let query;
    if (userType === 'admin') {
      query = 'SELECT * FROM notification WHERE id_admin = $1 ORDER BY id DESC';
    } else {
      query = 'SELECT * FROM notification WHERE id_escort = $1 ORDER BY id DESC';
    }

    const result = await db.query(query, [userId]);
    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur récupération notifications" });
  }
};

// NOUVELLE FONCTION : Marquer une notification comme lue
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userType = req.user.type;

    const field = userType === 'admin' ? 'id_admin' : 'id_escort';

    const result = await db.query(
      `UPDATE notification SET is_read = TRUE WHERE id = $1 AND ${field} = $2 RETURNING *`,
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ status: 'error', message: "Notification non trouvée" });
    }

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur mise à jour notification" });
  }
};

module.exports = { getMyNotifications, markAsRead };