const db = require('../../shares/config/config');

/**
 * @swagger
 * /api/v1/signalisation:
 *   post:
 *     summary: Signaler une escort
 *     tags: [Signalements]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [escort_id, motif]
 *             properties:
 *               escort_id: { type: integer }
 *               motif: { type: string, enum: [faux_compte, spam, contenu_inapproprié, autre] }
 *               description: { type: string }
 *     responses:
 *       201:
 *         description: Signalement enregistre
 */
const createSignalement = async (req, res) => {
  try {
    const { escort_id, motif, description } = req.body;
    const rapporteur_id = req.user.id;

    if (!escort_id || !motif) {
      return res.status(400).json({ status: 'error', message: "ID escort et motif requis." });
    }

    const query = `
      INSERT INTO signalement (rapporteur_id, escort_id, motif, description)
      VALUES ($1, $2, $3, $4)
      RETURNING *;
    `;
    
    const result = await db.query(query, [rapporteur_id, escort_id, motif, description]);
    const newSignalement = result.rows[0];

    // Notification admin en temps reel
    if (req.io) {
      req.io.to('admins').emit('new_signalement', newSignalement);
    }

    res.status(201).json({ status: 'success', data: newSignalement });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

module.exports = { createSignalement };