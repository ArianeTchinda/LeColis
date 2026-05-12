const Minio = require('minio');

// 1. On définit BUCKET_NAME en dehors pour qu'il soit accessible partout
const BUCKET_NAME = process.env.MINIO_BUCKET_NAME || 'lecolis-bucket';

const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || '127.0.0.1',
  port: parseInt(process.env.MINIO_PORT) || 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});

const initBucket = async () => {
  try {
    const exists = await minioClient.bucketExists(BUCKET_NAME);
    if (!exists) {
      await minioClient.makeBucket(BUCKET_NAME, 'us-east-1');
      console.log(`🪣 Bucket "${BUCKET_NAME}" créé avec succès !`);
      
      // Politique d'accès public (lecture seule) pour voir les images via URL
      const policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Principal: { AWS: ["*"] },
          Action: ["s3:GetObject"],
          Resource: [`arn:aws:s3:::${BUCKET_NAME}/*`]
        }]
      };
      await minioClient.setBucketPolicy(BUCKET_NAME, JSON.stringify(policy));
    }
  } catch (err) {
    console.error("Erreur lors de l'initialisation du Bucket:", err);
  }
};

// 2. Maintenant l'export fonctionnera correctement
module.exports = { minioClient, initBucket, BUCKET_NAME };