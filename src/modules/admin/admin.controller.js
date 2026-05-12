const db = require('../../shares/config/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

/**
 * @swagger
 * /api/v1/admins/register:
 *   post:
 *     summary: Créer un nouvel administrateur
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nom, prenom, email, password, pseudonyme, age]
 *             properties:
 *               nom: { type: string }
 *               prenom: { type: string }
 *               email: { type: string }
 *               password: { type: string }
 *               pseudonyme: { type: string }
 *               age: { type: integer }
 *     responses:
 *       201:
 *         description: Admin créé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 */
const registerAdmin = async (req, res) => {
  try {
    const { nom, prenom, email, password, pseudonyme, age } = req.body;

    if (!nom || !email || !password || !pseudonyme || !age) {
      return res.status(400).json({ status: 'error', message: "Nom, email, mot de passe, pseudonyme et âge requis." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const query = `
      INSERT INTO utilisateur (nom, prenom, mail, password, pseudonyme, age, role)
      VALUES ($1, $2, $3, $4, $5, $6, 'admin')
      RETURNING id, nom, prenom, mail, role;
    `;
    
    const result = await db.query(query, [nom, prenom, email, hashedPassword, pseudonyme, age]);
    res.status(201).json({ status: 'success', data: result.rows[0] });

  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ status: 'error', message: "Cet email ou pseudonyme est déjà utilisé." });
    }
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/admins/login:
 *   post:
 *     summary: Connexion administrateur
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: Connexion réussie
 *       401:
 *         description: Identifiants incorrects
 */
const { generateTokens } = require('../../shares/utils/auth');

const loginAdmin = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await db.query('SELECT * FROM utilisateur WHERE mail = $1 AND role = \'admin\'', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects ou non autorise." });
    }

    const admin = result.rows[0];
    const isMatch = await bcrypt.compare(password, admin.password);
    
    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const { accessToken, refreshToken } = await generateTokens(admin);

    res.status(200).json({
      status: 'success',
      token: accessToken,
      refreshToken,
      admin: { id: admin.id, nom: admin.nom, email: admin.mail, role: admin.role }
    });

  } catch (error) {
    console.error("Erreur Login Admin:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la connexion." });
  }
};

/**
 * @swagger
 * /api/v1/admins/reports/pending:
 *   get:
 *     summary: Récupérer les signalements en attente
 *     tags: [Signalements]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des signalements
 */
const getPendingReports = async (req, res) => {
  try {
    const query = `
      SELECT s.id, s.motif, s.description, u_rapporteur.pseudonyme as rapporteur_nom, e_u.pseudonyme as escort_nom, e.id as escort_id
      FROM signalement s
      JOIN utilisateur u_rapporteur ON s.rapporteur_id = u_rapporteur.id
      JOIN escort e ON s.escort_id = e.id
      JOIN utilisateur e_u ON e.utilisateur_id = e_u.id
      WHERE s.statut = 'en_attente'
      ORDER BY s.created_at ASC;
    `;
    const result = await db.query(query);
    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/admins/reports/{id_signalement}/claim:
 *   patch:
 *     summary: Traiter un signalement
 *     tags: [Signalements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id_signalement
 *         required: true
 *         schema: { type: integer }
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               statut: { type: string, enum: [traité, rejeté] }
 *     responses:
 *       200:
 *         description: Signalement traité
 */
const claimReport = async (req, res) => {
  try {
    const { id_signalement } = req.params;
    const { statut } = req.body; // 'traité' ou 'rejeté'
    const id_admin = req.user.id;

    const query = `
      UPDATE signalement 
      SET traite_par = $1, statut = $2, updated_at = NOW()
      WHERE id = $3 AND statut = 'en_attente'
      RETURNING *;
    `;
    
    const result = await db.query(query, [id_admin, statut || 'traité', id_signalement]);

    if (result.rows.length === 0) {
       return res.status(400).json({ status: 'error', message: "Signalement déjà traité ou inexistant." });
    }

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur traitement signalement" });
  }
};
module.exports = { registerAdmin, loginAdmin, getPendingReports, claimReport };