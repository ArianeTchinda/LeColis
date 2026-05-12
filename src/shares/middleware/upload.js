const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.memoryStorage();

// Filtre pour n'accepter que des images (Sécurité importante !)
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (extname && mimetype) {
    return cb(null, true);
  } else {
    cb(new Error("Seules les images (jpg, png, webp) sont autorisées !"));
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB c'est bien pour des IDs
});

module.exports = upload;