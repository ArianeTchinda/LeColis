// src/config/minio.js
const Minio = require('minio');

const minioClient = new Minio.Client({
  endPoint:  process.env.MINIO_ENDPOINT  || 'localhost',
  port:      parseInt(process.env.MINIO_PORT || '9000'),
  useSSL:    process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});

const BUCKETS = {
  ESCORTS:      process.env.MINIO_BUCKET_ESCORTS       || 'escorts-photos',
  PUBLICATIONS: process.env.MINIO_BUCKET_PUBLICATIONS  || 'publications-images',
};

/**
 * Construit l'URL publique d'un objet MinIO
 */
function buildPublicUrl(bucket, key) {
  const base = process.env.MINIO_PUBLIC_URL || 'http://localhost:9000';
  return `${base}/${bucket}/${key}`;
}

/**
 * Upload un buffer vers MinIO
 * @returns {{ url: string, key: string }}
 */
async function uploadBuffer(bucket, key, buffer, mimetype) {
  await minioClient.putObject(bucket, key, buffer, buffer.length, {
    'Content-Type': mimetype,
  });
  return {
    key,
    url: buildPublicUrl(bucket, key),
  };
}

/**
 * Supprime un objet MinIO
 */
async function deleteObject(bucket, key) {
  try {
    await minioClient.removeObject(bucket, key);
  } catch (err) {
    console.error(`[MinIO] Erreur suppression ${bucket}/${key}:`, err.message);
  }
}

module.exports = { minioClient, BUCKETS, uploadBuffer, deleteObject, buildPublicUrl };
