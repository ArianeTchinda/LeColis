const db = require('../../shares/database/config');

const addAvis = async (req, res) => {
  try {
    const { id_escort, note, commentaire } = req.body;

    // 1. Validation stricte
    if (!id_escort || !note) {
      return res.status(400).json({ 
        status: 'error', 
        message: "L'ID de l'escorte et une note (1-5) sont obligatoires." 
      });
    }

    if (note < 1 || note > 5) {
      return res.status(400).json({ status: 'error', message: "La note doit être comprise entre 1 et 5." });
    }

    // 2. Insertion en base de données
    const query = `
      INSERT INTO avis (id_escort, note, commentaire)
      VALUES ($1, $2, $3)
      RETURNING id, id_escort, note, commentaire, date_publication;
    `;
    
    const result = await db.query(query, [id_escort, note, commentaire]);

    res.status(201).json({
      status: 'success',
      message: "Merci ! Votre avis a été publié.",
      data: result.rows[0]
    });

  } catch (error) {
    console.error("Erreur addAvis:", error);
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
        AVG(note) OVER() as note_moyenne
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