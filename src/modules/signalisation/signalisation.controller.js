// src/modules/signalisation/signalisation.controller.js
const db = require('../../shares/database/config');

const createSignalement = async (req, res) => {
  try {
    const { raison, id_escort } = req.body;

    if (!raison || !id_escort) {
      return res.status(400).json({ status: 'error', message: "Données manquantes." });
    }

    const query = `
      INSERT INTO signalisation (raison, id_escort)
      VALUES ($1, $2)
      RETURNING *;
    `;
    
    const result = await db.query(query, [raison, id_escort]);
    const newSignalement = result.rows[0];

    // --- LOGIQUE TEMPS RÉEL ---
    if (req.io) {
      req.io.to('admins').emit('new_signalement', {
        message: "🚨 Nouveau signalement reçu !",
        data: newSignalement
      });
    }

    res.status(201).json({ status: 'success', data: newSignalement });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

const assignAdminToSignalement = async (req, res) => {
  try {
    const { id } = req.params;
    const { id_admin } = req.body;

    const query = 'UPDATE signalisation SET id_admin = $1 WHERE id = $2 RETURNING *';
    const result = await db.query(query, [id_admin, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Signalement non trouvé." });
    }

    res.status(200).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur lors de l'assignation." });
  }
};

// UN SEUL EXPORT À LA FIN
module.exports = { createSignalement, assignAdminToSignalement };