const jwt = require('jsonwebtoken');

const protect = async (req, res, next) => {
  try {
    let token;

    // 1. On vérifie si le token est présent dans les headers
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: "Accès refusé. Vous devez être connecté." });
    }

    // 2. On vérifie la validité du token avec ta clé secrète
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 3. On ajoute les infos de l'utilisateur à l'objet 'req' 
    // pour que les prochains contrôleurs sachent qui fait la demande.
    req.user = decoded; 
    
    next(); // On laisse passer au contrôleur suivant
  } catch (error) {
    return res.status(401).json({ message: "Token invalide ou expiré." });
  }
};

module.exports = { protect };