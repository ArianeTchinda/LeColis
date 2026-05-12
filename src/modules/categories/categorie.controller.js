const pool = require('../../shares/database/config');

// Récupérer toutes les catégories (Public)
exports.getAllCategories = async (req, res) => {
    try {
        const categories = await pool.query('SELECT * FROM categorie ORDER BY nom ASC');
        res.status(200).json({
            status: 'success',
            data: categories.rows
        });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
};

// Créer une catégorie (Admin uniquement)
exports.createCategorie = async (req, res) => {
    try {
        const { nom, description } = req.body;
        const newCat = await pool.query(
            'INSERT INTO categorie (nom, description) VALUES ($1, $2) RETURNING *',
            [nom, description]
        );
        res.status(201).json({ status: 'success', data: newCat.rows[0] });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
};

// Supprimer une catégorie
exports.deleteCategorie = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query('DELETE FROM categorie WHERE id = $1', [id]);
        res.status(204).json({ status: 'success', data: null });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
};