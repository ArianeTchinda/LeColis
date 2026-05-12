const db = require('../../shares/database/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { minioClient, BUCKET_NAME } = require('../../shares/services/minio.service');

// Fonction utilitaire pour uploader vers MinIO et retourner l'URL
const uploadToMinio = async (file) => {
  const fileName = `${Date.now()}-${file.originalname.replace(/\s/g, '_')}`;
  await minioClient.putObject(
    BUCKET_NAME,
    fileName,
    file.buffer,
    file.size,
    { 'Content-Type': file.mimetype }
  );
  // Retourne le nom du fichier pour stockage en BDD
  return fileName;
};

const registerEscort = async (req, res) => {
  try {
    const { nom, pseudo, age, description, telephone, mail, password, pay, ville, quatiers } = req.body;
    const files = req.files || {};

    if (!files['profile_picture'] || !files['recto_card'] || !files['verso_card']) {
      return res.status(400).json({ 
        status: 'error', 
        message: "Inscription incomplète : La photo de profil ET les deux faces de la carte d'identité sont obligatoires." 
      });
    }

    // 1. Upload des 3 images vers MinIO
    const profilePictureName = await uploadToMinio(files['profile_picture'][0]);
    const rectoCardName = await uploadToMinio(files['recto_card'][0]);
    const versoCardName = await uploadToMinio(files['verso_card'][0]);

    // 2. Hachage du mot de passe
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Insertion Localisation
    const locRes = await db.query(
      'INSERT INTO localisation (pay, ville, quatiers) VALUES ($1, $2, $3) RETURNING id',
      [pay, ville, quatiers]
    );
    const idLocalisation = locRes.rows[0].id;

    // 4. Insertion Escorte
    const escortQuery = `
      INSERT INTO escort (
        nom, pseudo, age, description, telephone, mail, password, 
        id_localisation, profile_picture, recto_card, verso_card, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'en_attente')
      RETURNING id, pseudo, mail;
    `;

    const values = [
      nom, pseudo, age, description, telephone, mail, hashedPassword, 
      idLocalisation, profilePictureName, rectoCardName, versoCardName
    ];

    const result = await db.query(escortQuery, values);

    res.status(201).json({
      status: 'success',
      message: "Inscription réussie ! Votre profil est en attente de validation sur MinIO.",
      data: result.rows[0]
    });

  } catch (error) {
    console.error("Erreur Inscription MinIO:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de l'inscription (Storage)." });
  }
};

const loginEscort = async (req, res) => {
  try {
    const { mail, password } = req.body;

    if (!mail || !password) {
      return res.status(400).json({ status: 'error', message: "Email et mot de passe requis." });
    }

    const result = await db.query('SELECT * FROM escort WHERE mail = $1', [mail]);

    if (result.rows.length === 0) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const escort = result.rows[0];
    const isMatch = await bcrypt.compare(password, escort.password);

    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const token = jwt.sign(
      { id: escort.id, role: 'escort' },
      process.env.JWT_SECRET,
      { expiresIn: '168h' }
    );

    res.status(200).json({
      status: 'success',
      token,
      data: { id: escort.id, pseudo: escort.pseudo, mail: escort.mail }
    });

  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur Login." });
  }
};

const getMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT 
        e.id, e.nom, e.pseudo, e.age, e.description, e.telephone, e.mail, e.status, 
        e.profile_picture, e.recto_card, e.verso_card,
        l.pay, l.ville, l.quatiers
      FROM escort e
      LEFT JOIN localisation l ON e.id_localisation = l.id
      WHERE e.id = $1
    `;
    
    const result = await db.query(query, [userId]);
    if (result.rows.length === 0) return res.status(404).json({ message: "Non trouvé" });

    const escort = result.rows[0];

    // Construction de l'URL publique MinIO
    const minioUrlBase = `http://${process.env.MINIO_ENDPOINT}:${process.env.MINIO_PORT}/${BUCKET_NAME}/`;

    res.status(200).json({
      status: 'success',
      data: {
        ...escort,
        profile_picture_url: escort.profile_picture ? minioUrlBase + escort.profile_picture : null,
        recto_card_url: escort.recto_card ? minioUrlBase + escort.recto_card : null,
        verso_card_url: escort.verso_card ? minioUrlBase + escort.verso_card : null
      }
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur GetMe" });
  }
};

const updateMe = async (req, res) => {
  try {
    const { nom, pseudo, age, description, telephone } = req.body;
    const userId = req.user.id;

    const query = `
      UPDATE escort 
      SET 
        nom = COALESCE($1, nom), 
        pseudo = COALESCE($2, pseudo), 
        age = COALESCE($3, age), 
        description = COALESCE($4, description), 
        telephone = COALESCE($5, telephone)
      WHERE id = $6
      RETURNING id, nom, pseudo, age, description, telephone;
    `;

    const result = await db.query(query, [nom, pseudo, age, description, telephone, userId]);

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur UpdateMe" });
  }
};

const updateProfilePicture = async (req, res) => {
  try {
    const userId = req.user.id;

    if (!req.file) {
      return res.status(400).json({ status: 'error', message: "Aucune image fournie." });
    }

    // 1. Récupérer l'ancien nom de fichier
    const oldRes = await db.query('SELECT profile_picture FROM escort WHERE id = $1', [userId]);
    const oldFileName = oldRes.rows[0]?.profile_picture;

    // 2. Upload du nouveau fichier
    const newFileName = await uploadToMinio(req.file);

    // 3. Update BDD
    await db.query('UPDATE escort SET profile_picture = $1 WHERE id = $2', [newFileName, userId]);

    // 4. Suppression de l'ancien fichier sur MinIO
    if (oldFileName) {
      try {
        await minioClient.removeObject(BUCKET_NAME, oldFileName);
        console.log(`✅ Ancien fichier MinIO supprimé : ${oldFileName}`);
      } catch (err) {
        console.warn("⚠️ Erreur suppression MinIO (Fichier peut-être inexistant).");
      }
    }

    res.status(200).json({
      status: 'success',
      data: { profile_picture: newFileName }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ status: 'error', message: "Erreur UpdatePhoto" });
  }
};

module.exports = { registerEscort, loginEscort, getMe, updateMe, updateProfilePicture };