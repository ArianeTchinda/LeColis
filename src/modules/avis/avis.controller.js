const db = require('../../shares/database/config');

const addAvis = async (req, res) => {
  try {
    // 1. On récupère les noms exacts de ton schéma
    const { id_escort, rate, message } = req.body;

    // 2. Validation
    if (!id_escort || rate === undefined) {
      return res.status(400).json({ 
        status: 'error', 
        message: "L'ID de l'escorte et une note (rate) sont obligatoires." 
      });
    }

    // 3. Requête SQL avec tes noms de colonnes : message, rate, id_escort
    const query = `
      INSERT INTO avis (id_escort, rate, message)
      VALUES ($1, $2, $3)
      RETURNING *;
    `;
    
    const result = await db.query(query, [id_escort, rate, message]);

    res.status(201).json({
      status: 'success',
      data: result.rows[0]
    });

  } catch (error) {
    console.error("❌ Erreur addAvis:", error.message);
    res.status(500).json({ status: 'error', message: "Erreur lors de l'ajout de l'avis." });
  }
};

const getAvisByEscort = async (req, res) => {
  try {
    const { id_escort } = req.params;

    // 1. On récupère tous les avis + on calcule la moyenne et le compte en une seule requête SQL
    const query = `
      SELECT 
        *, 
        COUNT(*) OVER() as total_avis,
        AVG(rate) OVER() as note_moyenne
      FROM avis 
      WHERE id_escort = $1
      ORDER BY date_publication DESC;
    `;
    
    const result = await db.query(query, [id_escort]);

    if (result.rows.length === 0) {
      return res.status(200).json({
        status: 'success',
        message: "Aucun avis pour cette escorte.",
        stats: { total: 0, moyenne: 0 },
        data: []
      });
    }

    // 2. On extrait les stats de la première ligne (elles sont identiques partout grâce à OVER())
    const stats = {
      total: parseInt(result.rows[0].total_avis),
      moyenne: parseFloat(result.rows[0].note_moyenne).toFixed(1)
    };

    // 3. On nettoie les objets pour ne pas renvoyer les colonnes de calcul à chaque ligne
    const cleanAvis = result.rows.map(({ total_avis, note_moyenne, ...rest }) => rest);

    res.status(200).json({
      status: 'success',
      stats: stats,
      data: cleanAvis
    });

  } catch (error) {
    console.error("Erreur getAvisByEscort:", error);
    res.status(500).json({ status: 'error', message: "Erreur lors de la récupération des avis." });
  }
};

module.exports = { addAvis, getAvisByEscort };