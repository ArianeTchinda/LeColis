const db = require('../../shares/config/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const minio = require('../../shares/utils/minio');

/**
 * @swagger
 * /api/v1/escorts/register:
 *   post:
 *     summary: Inscription d'une nouvelle escort
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [nom, prenom, pseudonyme, age, mail, password, profile_picture, recto_card, verso_card]
 *             properties:
 *               nom: { type: string }
 *               prenom: { type: string }
 *               pseudonyme: { type: string }
 *               age: { type: integer }
 *               description: { type: string }
 *               telephone: { type: string }
 *               mail: { type: string }
 *               password: { type: string }
 *               pays: { type: string }
 *               ville: { type: string }
 *               quartier: { type: string }
 *               profile_picture: { type: string, format: binary }
 *               recto_card: { type: string, format: binary }
 *               verso_card: { type: string, format: binary }
 *     responses:
 *       201:
 *         description: Inscription réussie
 */
const registerEscort = async (req, res) => {
  const client = await db.pool.connect();
  try {
    const { nom, prenom, pseudonyme, age, description, telephone, mail, password, pays, ville, quartier } = req.body;
    const files = req.files || {};

    if (!files['profile_picture'] || !files['recto_card'] || !files['verso_card']) {
      return res.status(400).json({ 
        status: 'error', 
        message: "Inscription incomplète : La photo de profil ET les deux faces de la carte d'identité sont obligatoires." 
      });
    }

    await client.query('BEGIN');

    // 1. Upload images to Minio
    const profilePictureUrl = await minio.uploadFile(files['profile_picture'][0], 'profiles');
    const rectoCardUrl = await minio.uploadFile(files['recto_card'][0], 'documents');
    const versoCardUrl = await minio.uploadFile(files['verso_card'][0], 'documents');

    // 2. Hash password
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Insert Localisation
    const locRes = await client.query(
      'INSERT INTO localisation (pays, ville, quartier) VALUES ($1, $2, $3) RETURNING id',
      [pays, ville, quartier]
    );
    const idLocalisation = locRes.rows[0].id;

    // 4. Insert Utilisateur
    const userRes = await client.query(
      `INSERT INTO utilisateur (nom, prenom, pseudonyme, age, description, telephone, mail, password, role)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'escort')
       RETURNING id`,
      [nom, prenom, pseudonyme, age, description, telephone, mail, hashedPassword]
    );
    const utilisateurId = userRes.rows[0].id;

    // 5. Insert Escort Profile
    const escortQuery = `
      INSERT INTO escort (
        utilisateur_id, url_image_profil, localisation_id, url_cni_recto, url_cni_verso, verified
      ) VALUES ($1, $2, $3, $4, $5, 'en_attente')
      RETURNING id;
    `;
    const escortRes = await client.query(escortQuery, [utilisateurId, profilePictureUrl, idLocalisation, rectoCardUrl, versoCardUrl]);

    // 6. Assign Standard Plan automatically
    const planRes = await client.query('SELECT id, duree_jours FROM plan WHERE nom = \'Standard\' AND actif = TRUE LIMIT 1');
    if (planRes.rows.length > 0) {
      const plan = planRes.rows[0];
      const dateDebut = new Date();
      const dateFin = new Date();
      dateFin.setDate(dateFin.getDate() + plan.duree_jours);

      await client.query(
        `INSERT INTO abonnement_plan (escort_id, plan_id, date_debut, date_fin, statut)
         VALUES ($1, $2, $3, $4, 'actif')`,
        [escortRes.rows[0].id, plan.id, dateDebut, dateFin]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      status: 'success',
      message: "Inscription reussie ! Votre profil est complet et en attente de validation.",
      data: { utilisateur_id: utilisateurId, escort_id: escortRes.rows[0].id }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Erreur Inscription Escort:", error);
    res.status(500).json({ status: 'error', message: "Une erreur est survenue lors de l'inscription." });
  } finally {
    client.release();
  }
};

/**
 * @swagger
 * /api/v1/escorts/login:
 *   post:
 *     summary: Connexion escort
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [mail, password]
 *             properties:
 *               mail: { type: string }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: Connexion réussie
 */
const { generateTokens } = require('../../shares/utils/auth');

const loginEscort = async (req, res) => {
  try {
    const { mail, password } = req.body;

    const query = 'SELECT * FROM utilisateur WHERE mail = $1 AND role = \'escort\'';
    const result = await db.query(query, [mail]);

    if (result.rows.length === 0) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const { accessToken, refreshToken } = await generateTokens(user);

    res.status(200).json({
      status: 'success',
      token: accessToken,
      refreshToken,
      data: { id: user.id, pseudonyme: user.pseudonyme, mail: user.mail }
    });

  } catch (error) {
    console.error("Erreur Login Escort:", error);
    res.status(500).json({ status: 'error', message: "Erreur connexion." });
  }
};

/**
 * @swagger
 * /api/v1/escorts/me:
 *   get:
 *     summary: Récupérer mon profil escort
 *     tags: [Escorts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profil récupéré
 */
const getMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT 
        u.*, e.id as escort_id, e.url_image_profil, e.verified, e.tarif, e.disponible,
        l.pays, l.ville, l.quartier
      FROM utilisateur u
      JOIN escort e ON u.id = e.utilisateur_id
      LEFT JOIN localisation l ON e.localisation_id = l.id
      WHERE u.id = $1
    `;
    
    const result = await db.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Profil non trouvé." });
    }

    const profile = result.rows[0];
    profile.url_image_profil_full = await minio.getFileUrl(profile.url_image_profil);

    res.status(200).json({ status: 'success', data: profile });
  } catch (error) {
    console.error("Erreur GetMe Escort:", error);
    res.status(500).json({ status: 'error', message: "Erreur récupération profil." });
  }
};

/**
 * @swagger
 * /api/v1/escorts/me:
 *   patch:
 *     summary: Mettre à jour mon profil escort
 *     tags: [Escorts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nom: { type: string }
 *               prenom: { type: string }
 *               pseudonyme: { type: string }
 *               age: { type: integer }
 *               description: { type: string }
 *               tarif: { type: number }
 *               disponible: { type: boolean }
 *     responses:
 *       200:
 *         description: Profil mis à jour
 */
const updateMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const { nom, prenom, pseudonyme, age, description, telephone, tarif, disponible } = req.body;

    await db.query('BEGIN');

    await db.query(
      `UPDATE utilisateur SET nom=COALESCE($1, nom), prenom=COALESCE($2, prenom), pseudonyme=COALESCE($3, pseudonyme), 
       age=COALESCE($4, age), description=COALESCE($5, description), telephone=COALESCE($6, telephone), updated_at=NOW()
       WHERE id=$7`,
      [nom, prenom, pseudonyme, age, description, telephone, userId]
    );

    await db.query(
      `UPDATE escort SET tarif=COALESCE($1, tarif), disponible=COALESCE($2, disponible) WHERE utilisateur_id=$3`,
      [tarif, disponible, userId]
    );

    await db.query('COMMIT');

    res.status(200).json({ status: 'success', message: "Profil mis à jour." });
  } catch (error) {
    await db.query('ROLLBACK');
    res.status(500).json({ status: 'error', message: "Erreur mise à jour." });
  }
};

/**
 * @swagger
 * /api/v1/escorts/me/profile-picture:
 *   patch:
 *     summary: Mettre à jour la photo de profil
 *     tags: [Escorts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               profile_picture: { type: string, format: binary }
 *     responses:
 *       200:
 *         description: Photo mise à jour
 */
const updateProfilePicture = async (req, res) => {
  try {
    const userId = req.user.id;
    if (!req.file) {
      return res.status(400).json({ status: 'error', message: "Image requise." });
    }

    const oldRes = await db.query('SELECT url_image_profil FROM escort WHERE utilisateur_id=$1', [userId]);
    if (oldRes.rows.length > 0 && oldRes.rows[0].url_image_profil) {
      await minio.deleteFile(oldRes.rows[0].url_image_profil);
    }

    const newUrl = await minio.uploadFile(req.file, 'profiles');
    await db.query('UPDATE escort SET url_image_profil=$1 WHERE utilisateur_id=$2', [newUrl, userId]);

    res.status(200).json({ status: 'success', data: { url_image_profil: newUrl } });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur photo." });
  }
};

module.exports = { registerEscort, loginEscort, getMe, updateMe, updateProfilePicture };