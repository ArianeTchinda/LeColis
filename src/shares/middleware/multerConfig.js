const multer = require('multer');

// On stocke temporairement en mémoire vive pour l'envoyer au cloud
const storage = multer.memoryStorage();

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 } // Limite 5MB
});

module.exports = upload;