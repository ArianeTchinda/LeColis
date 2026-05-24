// src/middlewares/upload.js
const multer = require('multer');

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE_MB  = 5;

const storage = multer.memoryStorage(); // on garde en RAM, on envoie vers MinIO

const fileFilter = (req, file, cb) => {
  if (ALLOWED_MIME.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format non supporté. Utilisez JPG, PNG ou WebP.'), false);
  }
};

// Upload photo de profil (1 fichier)
const uploadPhoto = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 },
}).single('photo');

// Upload images publication (jusqu'à 10 fichiers)
const uploadImages = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 },
}).array('images', 10);

// Wrapper pour gérer les erreurs multer proprement
function wrapMulter(multerFn) {
  return (req, res, next) => {
    multerFn(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        return res.status(400).json({ message: `Erreur upload : ${err.message}` });
      }
      if (err) {
        return res.status(400).json({ message: err.message });
      }
      next();
    });
  };
}

module.exports = {
  uploadPhoto:  wrapMulter(uploadPhoto),
  uploadImages: wrapMulter(uploadImages),
};
