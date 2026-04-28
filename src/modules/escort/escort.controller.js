const db = require('../../shares/database/config');
const bcrypt = require('bcrypt');

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

module.exports = { registerEscort };