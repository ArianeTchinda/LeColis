const jwt = require('jsonwebtoken');
const db = require('../../shares/config/config');
const { generateTokens } = require('../../shares/utils/auth');

/**
 * @swagger
 * /api/v1/auth/refresh:
 *   post:
 *     summary: Rafraichir le token d'acces
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken: { type: string }
 *     responses:
 *       200:
 *         description: Nouveaux tokens generes
 */
const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ status: 'error', message: "Refresh token requis." });
    }

    // 1. Verifier le token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    // 2. Verifier en base s'il n'a pas ete revoque
    const result = await db.query('SELECT * FROM utilisateur WHERE id = $1 AND refresh_token = $2', [decoded.id, refreshToken]);
    
    if (result.rows.length === 0) {
      return res.status(401).json({ status: 'error', message: "Token invalide ou revoque." });
    }

    const user = result.rows[0];

    // 3. Generer de nouveaux tokens
    const tokens = await generateTokens(user);

    res.status(200).json({
      status: 'success',
      ...tokens
    });

  } catch (error) {
    return res.status(401).json({ status: 'error', message: "Token invalide ou expire." });
  }
};

/**
 * @swagger
 * /api/v1/auth/logout:
 *   post:
 *     summary: Deconnexion (revoquer le refresh token)
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Deconnecte
 */
const logout = async (req, res) => {
  try {
    const userId = req.user.id;
    await db.query('UPDATE utilisateur SET refresh_token = NULL WHERE id = $1', [userId]);
    res.status(200).json({ status: 'success', message: "Deconnecte avec succes." });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur lors de la deconnexion." });
  }
};

module.exports = { refresh, logout };
