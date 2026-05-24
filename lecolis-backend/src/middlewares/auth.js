// src/middlewares/auth.js
const { verifyAccess } = require('../config/jwt');
const prisma = require('../config/prisma');

/**
 * Middleware : vérifie le JWT escort
 * Attache req.escort = { id, pseudo, email, estVerifie, estBloque, estBanni }
 */
async function authEscort(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token manquant.' });
    }
    const token = header.split(' ')[1];
    const payload = verifyAccess(token);

    if (payload.role !== 'escort') {
      return res.status(403).json({ message: 'Accès refusé.' });
    }

    const escort = await prisma.escort.findUnique({
      where: { id: payload.sub },
      select: { id: true, pseudo: true, email: true, telephone: true,
                photoUrl: true, estVerifie: true, estBloque: true, estBanni: true },
    });

    if (!escort) return res.status(401).json({ message: 'Compte introuvable.' });
    if (escort.estBanni) return res.status(403).json({ message: 'Compte banni.' });
    if (escort.estBloque) return res.status(403).json({ message: 'Compte bloqué temporairement.' });

    req.escort = escort;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token invalide ou expiré.' });
  }
}

/**
 * Middleware : vérifie le JWT admin
 */
async function authAdmin(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token manquant.' });
    }
    const token = header.split(' ')[1];
    const payload = verifyAccess(token);

    if (payload.role !== 'admin') {
      return res.status(403).json({ message: 'Accès réservé aux administrateurs.' });
    }

    const admin = await prisma.admin.findUnique({ where: { id: payload.sub } });
    if (!admin) return res.status(401).json({ message: 'Admin introuvable.' });

    req.admin = admin;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token invalide ou expiré.' });
  }
}

module.exports = { authEscort, authAdmin };
