const jwt = require('jsonwebtoken');
const db = require('../config/config');

const generateTokens = async (user) => {
  const accessToken = jwt.sign(
    { id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );

  const refreshToken = jwt.sign(
    { id: user.id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  // Stocker le refresh token en base pour pouvoir le révoquer
  await db.query('UPDATE utilisateur SET refresh_token = $1 WHERE id = $2', [refreshToken, user.id]);

  return { accessToken, refreshToken };
};

module.exports = { generateTokens };
