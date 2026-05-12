const db = require('../../shares/database/config');
const { minioClient, BUCKET_NAME } = require('../services/minio.service');

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
  // 1. On récupère le nom du fichier en DB
  const mediaRes = await db.query('SELECT url FROM media WHERE id = $1', [id]);
  
  if (mediaRes.rows.length > 0) {
    const fileName = mediaRes.rows[0].url; // Ex: "1715432-photo.jpg"

    try {
      // ✅ On supprime de MinIO et non du disque dur local
      await minioClient.removeObject(BUCKET_NAME, fileName);
      console.log(`🗑️ Fichier ${fileName} supprimé de MinIO`);
    } catch (err) {
      console.warn("⚠️ Impossible de supprimer sur MinIO:", err.message);
    }
  }

  // 2. On supprime l'entrée en base de données
  return await db.query('DELETE FROM media WHERE id = $1', [id]);
};

module.exports = { createMedia, deleteMedia };