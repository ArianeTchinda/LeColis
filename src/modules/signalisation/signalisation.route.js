const db = require('../../shares/database/config');

const createSignalement = async (req, res) => {
  try {
    const { raison, id_escort } = req.body;

    // Validation
    if (!raison || !id_escort) {
      return res.status(400).json({ 
        status: 'error', 
        message: "La raison et l'ID de l'escorte sont obligatoires." 
      });
    }

    // On insère uniquement raison et id_escort. 
    // id_admin reste NULL par défaut (attente de traitement).
    const query = `
      INSERT INTO signalisation (raison, id_escort)
      VALUES ($1, $2)
      RETURNING *;
    `;
    
    const result = await db.query(query, [raison, id_escort]);

    res.status(201).json({
      status: 'success',
      message: "Signalement enregistré avec succès.",
      data: result.rows[0]
    });

  } catch (error) {
    console.error("Erreur Signalement:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la création du signalement." });
  }
};

// Route pour l'Admin : Assigner un admin à un signalement (Traiter le signalement)
const assignAdminToSignalement = async (req, res) => {
  try {
    const { id } = req.params; // ID du signalement
    const { id_admin } = req.body;

    const query = `
      UPDATE signalisation 
      SET id_admin = $1 
      WHERE id = $2 
      RETURNING *;
    `;
    
    const result = await db.query(query, [id_admin, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: "Signalement non trouvé." });
    }

    res.status(200).json({
      status: 'success',
      message: "Signalement pris en charge par l'administrateur.",
      data: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: "Erreur lors de l'assignation." });
  }
};

module.exports = { createSignalement, assignAdminToSignalement };