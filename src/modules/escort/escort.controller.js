const db = require('../../shares/database/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require('fs').promises; // Utilisation des promesses pour un code plus propre
const path = require('path');

const registerEscort = async (req, res) => {
  try {
    const { nom, pseudo, age, description, telephone, mail, password, pay, ville, quatiers } = req.body;
    const files = req.files || {};

    // 1. VÉRIFICATION STRICTE DES 3 IMAGES
    if (!files['profile_picture'] || !files['recto_card'] || !files['verso_card']) {
      return res.status(400).json({ 
        status: 'error', 
        message: "Inscription incomplète : La photo de profil ET les deux faces de la carte d'identité sont obligatoires." 
      });
    }

    // 2. RÉCUPÉRATION DES CHEMINS
    const profilePicture = files['profile_picture'][0].path;
    const rectoCard = files['recto_card'][0].path;
    const versoCard = files['verso_card'][0].path;

    // 3. SÉCURITÉ : HACHAGE DU MOT DE PASSE
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 4. TRANSACTION : LOCALISATION PUIS ESCORTE
    // On récupère l'ID de localisation
    const locRes = await db.query(
      'INSERT INTO localisation (pay, ville, quatiers) VALUES ($1, $2, $3) RETURNING id',
      [pay, ville, quatiers]
    );
    const idLocalisation = locRes.rows[0].id;

    // Insertion finale
    const escortQuery = `
      INSERT INTO escort (
        nom, pseudo, age, description, telephone, mail, password, 
        id_localisation, profile_picture, recto_card, verso_card, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'en_attente')
      RETURNING id, pseudo, mail;
    `;

    const values = [
      nom, pseudo, age, description, telephone, mail, hashedPassword, 
      idLocalisation, profilePicture, rectoCard, versoCard
    ];

    const result = await db.query(escortQuery, values);

    res.status(201).json({
      status: 'success',
      message: "Inscription réussie ! Votre profil est complet et en attente de validation.",
      data: result.rows[0]
    });

  } catch (error) {
    console.error("Erreur Inscription:", error);
    res.status(500).json({ status: 'error', message: "Une erreur est survenue lors de l'inscription." });
  }
};


const loginEscort = async (req, res) => {
  try {
    const { mail, password } = req.body;

    // 1. Vérification des champs
    if (!mail || !password) {
      return res.status(400).json({ status: 'error', message: "Email et mot de passe requis." });
    }

    // 2. Recherche de l'escorte en base de données
    const query = 'SELECT * FROM escort WHERE mail = $1';
    const result = await db.query(query, [mail]);

    if (result.rows.length === 0) {
      // Pour la sécurité, on reste vague : "Email ou mot de passe incorrect"
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const escort = result.rows[0];

    // 3. Comparaison des mots de passe avec Bcrypt
    // On compare le mot de passe clair reçu avec le hachage stocké ($2b$12...)
    const isMatch = await bcrypt.compare(password, escort.password);

    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    // 4. Génération du Token JWT
    // On met l'ID et le rôle dans le payload, mais JAMAIS le mot de passe.
    const token = jwt.sign(
      { id: escort.id, role: 'escort' },
      process.env.JWT_SECRET,
      { expiresIn: '168h' } // Le token expire après 1 jour
    );

    // 5. Réponse au client
    res.status(200).json({
      status: 'success',
      message: "Connexion réussie",
      token, // Le Frontend doit stocker ce token (localStorage ou Cookie)
      data: {
        id: escort.id,
        pseudo: escort.pseudo,
        mail: escort.mail
      }
    });

  } catch (error) {
    console.error("Erreur Login:", error);
    res.status(500).json({ status: 'error', message: "Une erreur est survenue lors de la connexion." });
  }
};



const getMe = async (req, res) => {
  try {
    const userId = req.user.id;

    // Ajout de profile_picture à la sélection
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

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Utilisateur non trouvé." });
    }

    const escort = result.rows[0];

    // Transformation du chemin en URL complète si nécessaire
    // Exemple : "public/uploads/profiles/img.jpg" -> "http://localhost:5000/uploads/profiles/img.jpg"
    const profileUrl = escort.profile_picture 
      ? `${req.protocol}://${req.get('host')}/${escort.profile_picture.replace('public/', '')}`
      : null;

    res.status(200).json({
      status: 'success',
      data: {
        ...escort,
        profile_picture_url: profileUrl // Le frontend utilisera ce champ pour la balise <img>
      }
    });
  } catch (error) {
    console.error("Erreur GetMe:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la récupération du profil." });
  }
};


const updateMe = async (req, res) => {
  try {
    const { nom, pseudo, age, description, telephone } = req.body;
    const userId = req.user.id;

    // 1. On construit dynamiquement la requête pour ne mettre à jour que ce qui est envoyé
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

    const values = [nom, pseudo, age, description, telephone, userId];
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Utilisateur non trouvé." });
    }

    res.status(200).json({
      status: 'success',
      message: "Profil mis à jour avec succès",
      data: result.rows[0]
    });

  } catch (error) {
    console.error("Erreur UpdateMe:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la mise à jour du profil." });
  }
};


const updateProfilePicture = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1. Vérifier si un fichier a été envoyé
    if (!req.file) {
      return res.status(400).json({ status: 'error', message: "Aucune image fournie." });
    }

    const newPath = req.file.path;

    // 2. Récupérer l'ancien chemin en base de données
    const oldPhotoQuery = 'SELECT profile_picture FROM escort WHERE id = $1';
    const oldPhotoRes = await db.query(oldPhotoQuery, [userId]);

    if (oldPhotoRes.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Utilisateur non trouvé." });
    }

    const oldPath = oldPhotoRes.rows[0].profile_picture;

    // 3. Mettre à jour la base de données avec le nouveau chemin
    await db.query('UPDATE escort SET profile_picture = $1 WHERE id = $2', [newPath, userId]);

    // 4. Supprimer l'ancien fichier du serveur (si ce n'est pas une image par défaut)
    if (oldPath) {
      try {
        // On vérifie si le fichier existe avant de tenter la suppression
        await fs.access(oldPath); 
        await fs.unlink(oldPath);
        console.log(`✅ Ancien fichier supprimé : ${oldPath}`);
      } catch (err) {
        // Si le fichier n'existe pas déjà, on ignore simplement l'erreur
        console.warn(`⚠️ Impossible de supprimer l'ancien fichier (peut-être déjà inexistant) : ${oldPath}`);
      }
    }

    res.status(200).json({
      status: 'success',
      message: "Photo de profil mise à jour avec succès.",
      data: {
        profile_picture: newPath
      }
    });

  } catch (error) {
    console.error("Erreur UpdatePhoto:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la mise à jour de la photo." });
  }
};

module.exports = { registerEscort, loginEscort, getMe ,updateMe,updateProfilePicture };