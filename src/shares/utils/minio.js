const Minio = require('minio');
require('dotenv').config();

const minioClient = new Minio.Client({
    endPoint: process.env.MINIO_ENDPOINT || 'localhost',
    port: parseInt(process.env.MINIO_PORT) || 9000,
    useSSL: process.env.MINIO_USE_SSL === 'true',
    accessKey: process.env.MINIO_ACCESS_KEY,
    secretKey: process.env.MINIO_SECRET_KEY,
});

const bucketName = process.env.MINIO_BUCKET || 'lecolis';

// Assure que le bucket existe
const ensureBucketExists = async () => {
    try {
        const exists = await minioClient.bucketExists(bucketName);
        if (!exists) {
            await minioClient.makeBucket(bucketName, 'us-east-1');
            console.log(`Bucket '${bucketName}' cree avec succes.`);
        }
    } catch (err) {
        console.error(`Erreur lors de la verification du bucket Minio:`, err.message);
    }
};

// Lancer la verification au demarrage
ensureBucketExists();

/**
 * Upload un fichier vers Minio
 * @param {Object} file Objet fichier (multer)
 * @param {String} folder Dossier de destination dans le bucket
 * @returns {String} Le nom du fichier enregistre
 */
const uploadFile = async (file, folder = 'others') => {
    const fileName = `${folder}/${Date.now()}-${file.originalname}`;
    
    await minioClient.putObject(bucketName, fileName, file.buffer || file.path, {
        'Content-Type': file.mimetype,
    });
    
    return fileName;
};

/**
 * Recupere l'URL d'un fichier (Presigned URL ou URL publique)
 * @param {String} fileName Nom du fichier dans le bucket
 * @returns {Promise<String>}
 */
const getFileUrl = async (fileName) => {
    if (!fileName) return null;
    return await minioClient.presignedGetObject(bucketName, fileName, 24 * 60 * 60);
};

/**
 * Supprime un fichier du bucket
 * @param {String} fileName Nom du fichier
 */
const deleteFile = async (fileName) => {
    if (!fileName) return;
    try {
        await minioClient.removeObject(bucketName, fileName);
    } catch (err) {
        console.warn(`Impossible de supprimer le fichier Minio: ${fileName}`, err.message);
    }
};

module.exports = {
    uploadFile,
    getFileUrl,
    deleteFile,
    minioClient
};
