const db = require('../../shares/config/config');

/**
 * @swagger
 * /api/v1/avis:
 *   post:
 *     summary: Ajouter un avis sur une escort
 *     tags: [Avis]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [escort_id, rate]
 *             properties:
 *               escort_id: { type: integer }
 *               rate: { type: integer, minimum: 1, maximum: 5 }
 *               message: { type: string }
 *     responses:
 *       201:
 *         description: Avis ajoute
 */
const addAvis = async (req, res) => {
  try {
    const { escort_id, rate, message } = req.body;
    const utilisateur_id = req.user.id;

    if (!escort_id || rate === undefined) {
      return res.status(400).json({ status: 'error', message: "ID escort et note requis." });
    }

    const query = `
      INSERT INTO avis (escort_id, utilisateur_id, rate, message)
      VALUES ($1, $2, $3, $4)
      RETURNING *;
    `;
    
    const result = await db.query(query, [escort_id, utilisateur_id, rate, message]);
    res.status(201).json({ status: 'success', data: result.rows[0] });

  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/avis/escort/{escort_id}:
 *   get:
 *     summary: Recuperer les avis d'une escort
 *     tags: [Avis]
 *     parameters:
 *       - in: path
 *         name: escort_id
 *         required: true
 *         schema: { type: integer }
 *     responses:
 *       200:
 *         description: Liste des avis
 */
const getAvisByEscort = async (req, res) => {
  try {
    const { escort_id } = req.params;

    const query = `
      SELECT a.*, u.pseudonyme as client_pseudo
      FROM avis a
      JOIN utilisateur u ON a.utilisateur_id = u.id
      WHERE a.escort_id = $1
      ORDER BY a.created_at DESC;
    `;
    
    const result = await db.query(query, [escort_id]);

    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

module.exports = { addAvis, getAvisByEscort };