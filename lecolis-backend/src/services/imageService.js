// src/services/imageService.js
const sharp  = require('sharp');
const { v4: uuidv4 } = require('uuid');
const { uploadBuffer, deleteObject, BUCKETS } = require('../config/minio');

/**
 * Compresse et upload une photo de profil escort
 * @param {Buffer} buffer - buffer du fichier uploadé
 * @param {string} escortId
 * @returns {{ url: string, key: string }}
 */
async function uploadPhotoEscort(buffer, escortId) {
  const optimized = await sharp(buffer)
    .resize(400, 400, { fit: 'cover', position: 'center' })
    .jpeg({ quality: 85 })
    .toBuffer();

  const key = `escorts/${escortId}/profil_${uuidv4()}.jpg`;
  return uploadBuffer(BUCKETS.ESCORTS, key, optimized, 'image/jpeg');
}

/**
 * Compresse et upload une image de publication
 * @param {Buffer} buffer
 * @param {string} publicationId
 * @param {number} ordre - index de l'image dans la liste
 * @returns {{ url: string, key: string }}
 */
async function uploadImagePublication(buffer, publicationId, ordre = 0) {
  try {
    console.log(`[imageService] uploadImagePublication start - pubId=${publicationId}, ordre=${ordre}, bufferSize=${buffer.length}`);
    
    const optimized = await sharp(buffer)
      .resize(1200, 900, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 82 })
      .toBuffer();

    console.log(`[imageService] Image optimized - originalSize=${buffer.length}, optimizedSize=${optimized.length}`);

    const key = `publications/${publicationId}/img_${ordre}_${uuidv4()}.jpg`;
    console.log(`[imageService] Uploading to MinIO - bucket=PUBLICATIONS, key=${key}`);
    
    const result = await uploadBuffer(BUCKETS.PUBLICATIONS, key, optimized, 'image/jpeg');
    
    console.log(`[imageService] Upload success - url=${result.url}`);
    return result;
  } catch (err) {
    console.error(`[imageService] uploadImagePublication error:`, err);
    throw err;
  }
}

/**
 * Supprime une photo de profil
 */
async function supprimerPhotoEscort(key) {
  await deleteObject(BUCKETS.ESCORTS, key);
}

/**
 * Supprime une image de publication
 */
async function supprimerImagePublication(key) {
  await deleteObject(BUCKETS.PUBLICATIONS, key);
}

module.exports = {
  uploadPhotoEscort,
  uploadImagePublication,
  supprimerPhotoEscort,
  supprimerImagePublication,
};
