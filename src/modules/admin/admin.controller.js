const db = require('../../shares/database/config');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// 1. Création d'un nouvel Admin
const registerAdmin = async (req, res) => {
  try {
    const { nom, prenom, email, password } = req.body;

    if (!nom || !email || !password) {
      return res.status(400).json({ status: 'error', message: "Nom, email et mot de passe requis." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const query = `
      INSERT INTO admin (nom, prenom, email, password)
      VALUES ($1, $2, $3, $4)
      RETURNING id, nom, prenom, email;
    `;
    
    const result = await db.query(query, [nom, prenom, email, hashedPassword]);
    res.status(201).json({ status: 'success', data: result.rows[0] });

  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ status: 'error', message: "Cet email est déjà utilisé." });
    }
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// 2. Login Admin
const loginAdmin = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await db.query('SELECT * FROM admin WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const admin = result.rows[0];
    const isMatch = await bcrypt.compare(password, admin.password);
    
    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: "Identifiants incorrects." });
    }

    const token = jwt.sign(
      { id: admin.id, type: 'admin' }, 
      process.env.JWT_SECRET, 
      { expiresIn: '24h' }
    );

    res.status(200).json({
      status: 'success',
      token,
      admin: { id: admin.id, nom: admin.nom, email: admin.email }
    });

  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur lors de la connexion." });
  }
};

// 3. Récupérer les signalements en attente (Logique Premier arrivé)
const getPendingReports = async (req, res) => {
  try {
    // On ne montre que ceux où id_admin est NULL
    const query = `
      SELECT s.id, s.raison, e.pseudo as escort_nom, e.id as escort_id
      FROM signalisation s
      JOIN escort e ON s.id_escort = e.id
      WHERE s.id_admin IS NULL
      ORDER BY s.id ASC;
    `;
    const result = await db.query(query);
    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// 4. Prendre en charge un signalement (Claim)
const claimReport = async (req, res) => {
  try {
    const { id_signalement } = req.params;
    const id_admin = req.user.id;

    const query = `
      UPDATE signalisation 
      SET id_admin = $1 
      WHERE id = $2 AND id_admin IS NULL 
      RETURNING *;
    `;
    
    const result = await db.query(query, [id_admin, id_signalement]);

    if (result.rows.length === 0) {
       return res.status(400).json({ status: 'error', message: "Déjà pris !" });
    }

    // --- LOGIQUE TEMPS RÉEL ---
    // On prévient tous les admins que ce signalement n'est plus disponible
    req.io.to('admins').emit('report_claimed', {
      id_signalement: id_signalement,
      par_admin: req.user.nom
    });
    // --------------------------

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur claim" });
  }
};
module.exports = { registerAdmin, loginAdmin, getPendingReports, claimReport };