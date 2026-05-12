const db = require('../../shares/config/config');

/**
 * @swagger
 * /api/v1/transactions:
 *   post:
 *     summary: Enregistrer une nouvelle transaction (Paiement)
 *     tags: [Transactions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [montant, reference_paiement]
 *             properties:
 *               montant: { type: number }
 *               reference_paiement: { type: string }
 *     responses:
 *       201:
 *         description: Transaction enregistrée
 */
const createTransaction = async (req, res) => {
  try {
    const { montant, reference_paiement } = req.body;
    const escort_id = req.user.id; // Assumé que l'utilisateur est un escort

    // On vérifie d'abord l'ID de l'escort lié à cet utilisateur
    const escortRes = await db.query('SELECT id FROM escort WHERE utilisateur_id = $1', [escort_id]);
    if (escortRes.rows.length === 0) {
      return res.status(403).json({ status: 'error', message: "Seuls les escorts peuvent effectuer des transactions." });
    }

    const query = `
      INSERT INTO transaction (escort_id, montant, statut, reference_paiement)
      VALUES ($1, $2, 'en_attente', $3)
      RETURNING *;
    `;
    const result = await db.query(query, [escortRes.rows[0].id, montant, reference_paiement]);
    
    res.status(201).json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/transactions/me:
 *   get:
 *     summary: Récupérer mes transactions (Escort)
 *     tags: [Transactions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des transactions
 */
const getMyTransactions = async (req, res) => {
  try {
    const userId = req.user.id;
    const query = `
      SELECT t.* 
      FROM transaction t
      JOIN escort e ON t.escort_id = e.id
      WHERE e.utilisateur_id = $1
      ORDER BY t.created_at DESC;
    `;
    const result = await db.query(query, [userId]);
    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

/**
 * @swagger
 * /api/v1/admin/transactions:
 *   get:
 *     summary: Récupérer toutes les transactions (Admin)
 *     tags: [Transactions]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste complète des transactions
 */
const getAllTransactions = async (req, res) => {
  try {
    const query = `
      SELECT t.*, u.pseudonyme as escort_nom
      FROM transaction t
      JOIN escort e ON t.escort_id = e.id
      JOIN utilisateur u ON e.utilisateur_id = u.id
      ORDER BY t.created_at DESC;
    `;
    const result = await db.query(query);
    res.status(200).json({ status: 'success', data: result.rows });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

module.exports = { createTransaction, getMyTransactions, getAllTransactions };
