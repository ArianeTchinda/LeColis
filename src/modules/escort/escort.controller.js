const db = require('../../shares/database/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const registerEscort = async (req, res) => {
  // Utilisation d'un client spécifique pour la transaction
  const client = await db.connect(); 
  
  try {
    const { nom, pseudo, age, description, telephone, mail, password, pay, ville, quatiers } = req.body;

    // Nettoyage des chemins de fichiers pour le web
    const recto_card = req.files['recto_card'] ? req.files['recto_card'][0].path.replace(/\\/g, '/') : null;
    const verso_card = req.files['verso_card'] ? req.files['verso_card'][0].path.replace(/\\/g, '/') : null;

    if (!recto_card || !verso_card) {
      return res.status(400).json({ message: "Les documents d'identité sont obligatoires." });
    }

    await client.query('BEGIN'); // Début de la transaction

    // 1. Gestion Localisation
    let locResult = await client.query(
      'SELECT id FROM localisation WHERE LOWER(pay)=LOWER($1) AND LOWER(ville)=LOWER($2) AND LOWER(quatiers)=LOWER($3)',
      [pay, ville, quatiers]
    );

    let id_localisation;
    if (locResult.rows.length > 0) {
      id_localisation = locResult.rows[0].id;
    } else {
      const newLoc = await client.query(
        'INSERT INTO localisation (pay, ville, quatiers) VALUES ($1, $2, $3) RETURNING id',
        [pay, ville, quatiers]
      );
      id_localisation = newLoc.rows[0].id;
    }

    // 2. Sécurité
    const hashedPassword = await bcrypt.hash(password, 12);

    // 3. Insertion Escorte
    const query = `
      INSERT INTO escort (
        nom, pseudo, age, description, telephone, mail, 
        password, status, recto_card, verso_card, id_localisation
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'en_attente', $8, $9, $10)
      RETURNING id, pseudo, mail;
    `;

    const values = [nom, pseudo, age, description, telephone, mail, hashedPassword, recto_card, verso_card, id_localisation];
    const result = await client.query(query, values);

    await client.query('COMMIT'); // On valide tout en base de données

    res.status(201).json({
      status: 'success',
      message: 'Inscription réussie !',
      data: result.rows[0]
    });

  } catch (error) {
    await client.query('ROLLBACK'); // En cas d'erreur, on annule tout
    console.error("Erreur Inscription:", error);
    
    // Gestion spécifique des doublons (Email ou Pseudo)
    if (error.code === '23505') {
      return res.status(400).json({ message: "Cet email ou ce pseudo est déjà utilisé." });
    }
    
    res.status(500).json({ status: 'error', message: "Une erreur interne est survenue." });
  } finally {
    client.release(); // On libère la connexion
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

module.exports = { registerEscort, loginEscort };