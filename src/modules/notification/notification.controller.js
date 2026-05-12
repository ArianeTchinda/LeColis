const db = require('../../shares/database/config');

const getMyNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.type; // 'admin' ou 'escort'

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

module.exports = { getMyNotifications };