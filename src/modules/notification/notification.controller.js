const db = require('../../shares/config/config');

/**
 * @swagger
 * /api/v1/notifications:
 *   get:
 *     summary: Récupérer mes notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des notifications
 */
const getMyNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const query = 'SELECT * FROM notification WHERE utilisateur_id = $1 ORDER BY created_at DESC';
    const result = await db.query(query, [userId]);

    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur récupération notifications" });
  }
};

/**
 * @swagger
 * /api/v1/notifications/{id}/read:
 *   patch:
 *     summary: Marquer une notification comme lue
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Notification mise à jour
 */
const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const query = 'UPDATE notification SET lu = TRUE WHERE id = $1 AND utilisateur_id = $2 RETURNING *';
    const result = await db.query(query, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Notification non trouvée." });
    }

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur mise à jour notification" });
  }
};

module.exports = { getMyNotifications, markAsRead };