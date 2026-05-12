const db = require('../../shares/config/config');
const minio = require('../../shares/utils/minio');

/**
 * @swagger
 * /api/v1/config/logo:
 *   get:
 *     summary: Recuperer le logo actuel du site
 *     tags: [Config]
 *     responses:
 *       200:
 *         description: Logo recupere
 */
const getLogo = async (req, res) => {
  try {
    const query = 'SELECT * FROM logo_site WHERE actif = TRUE ORDER BY created_at DESC LIMIT 1';
    const result = await db.query(query);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Aucun logo configure." });
    }

    const logo = result.rows[0];
    logo.url_full = await minio.getFileUrl(logo.url_logo);

    res.status(200).json({ status: 'success', data: logo });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/config/logo:
 *   patch:
 *     summary: Mettre a jour le logo du site (Admin)
 *     tags: [Config]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [logo]
 *             properties:
 *               logo: { type: string, format: binary }
 *               label: { type: string }
 *     responses:
 *       200:
 *         description: Logo mis a jour
 */
const updateLogo = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ status: 'error', message: "Fichier logo requis." });
    }

    const { label } = req.body;
    const url_logo = await minio.uploadFile(req.file, 'config');

    await db.query('BEGIN');
    
    // Desactiver l'ancien logo
    await db.query('UPDATE logo_site SET actif = FALSE WHERE actif = TRUE');
    
    // Inserer le nouveau
    const query = `
      INSERT INTO logo_site (url_logo, label, actif, date_debut, date_fin)
      VALUES ($1, $2, TRUE, CURRENT_DATE, '2099-12-31')
      RETURNING *;
    `;
    const result = await db.query(query, [url_logo, label]);
    
    await db.query('COMMIT');

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    await db.query('ROLLBACK');
    res.status(500).json({ status: 'error', message: error.message });
  }
};

module.exports = { getLogo, updateLogo };
