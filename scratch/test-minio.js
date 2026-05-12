const minio = require('../src/shares/utils/minio');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function testMinio() {
  console.log('--- TEST MINIO START ---');
  console.log('Endpoint:', process.env.MINIO_ENDPOINT);
  console.log('Bucket:', process.env.MINIO_BUCKET);

  try {
    // 1. Créer un fichier de test temporaire
    const testFilePath = path.join(__dirname, 'test-upload.txt');
    fs.writeFileSync(testFilePath, 'Ceci est un test de Minio pour LeColis v2.0');

    const mockFile = {
      buffer: fs.readFileSync(testFilePath),
      originalname: 'test-upload.txt',
      mimetype: 'text/plain'
    };

    // 2. Tester l'upload
    console.log('Tentative d\'upload...');
    const url = await minio.uploadFile(mockFile, 'tests');
    console.log('Upload réussi ! URL relative:', url);

    // 3. Tester la génération d'URL
    console.log('Génération de l\'URL complète...');
    const fullUrl = await minio.getFileUrl(url);
    console.log('URL complète (presignée):', fullUrl);

    // 4. Nettoyage local
    fs.unlinkSync(testFilePath);
    console.log('--- TEST MINIO SUCCESS ---');
  } catch (error) {
    console.error('--- TEST MINIO FAILED ---');
    console.error(error);
  }
}

testMinio();
