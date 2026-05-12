const db = require('../../shares/database/config');
const fs = require('fs').promises;

const createMedia = async (url, id_publication) => {
  const query = `
    INSERT INTO media (url, id_publication)
    VALUES ($1, $2)
    RETURNING *;
  `;
  const res = await db.query(query, [url, id_publication]);
  return res.rows[0];
};

const deleteMedia = async (id) => {
  // 1. On récupère le chemin pour supprimer le fichier physique
  const mediaRes = await db.query('SELECT url FROM media WHERE id = $1', [id]);
  if (mediaRes.rows.length > 0) {
    try {
      await fs.unlink(mediaRes.rows[0].url);
    } catch (err) {
      console.warn("Fichier déjà supprimé du disque");
    }
  }
  // 2. On supprime de la DB
  return await db.query('DELETE FROM media WHERE id = $1', [id]);
};

module.exports = { createMedia, deleteMedia };