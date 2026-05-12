const db = require('../../shares/config/config');
const minio = require('../../shares/utils/minio');

const createMedia = async (url, publication_id) => {
  const query = `
    INSERT INTO publication_media (url, publication_id)
    VALUES ($1, $2)
    RETURNING *;
  `;
  const res = await db.query(query, [url, publication_id]);
  return res.rows[0];
};

const deleteMedia = async (id) => {
  const mediaRes = await db.query('SELECT url FROM publication_media WHERE id = $1', [id]);
  if (mediaRes.rows.length > 0) {
    await minio.deleteFile(mediaRes.rows[0].url);
  }
  return await db.query('DELETE FROM publication_media WHERE id = $1', [id]);
};

module.exports = { createMedia, deleteMedia };