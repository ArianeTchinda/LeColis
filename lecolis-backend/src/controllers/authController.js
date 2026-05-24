// src/controllers/authController.js
const bcrypt  = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const prisma  = require('../config/prisma');
const { signAccess, signRefresh, verifyRefresh } = require('../config/jwt');

// ── Inscription escort ────────────────────────────────────
async function register(req, res, next) {
  try {
    const { pseudo, email, telephone, motDePasse } = req.body;

    // Hash mot de passe
    const hash = await bcrypt.hash(motDePasse, 12);

    // Récupérer le plan basique (offert à l'inscription)
    const planBasique = await prisma.planAbonnement.findFirst({
      where: { estBasique: true },
    });

    // Créer l'escort + abonnement basique en transaction
    const escort = await prisma.$transaction(async (tx) => {
      const newEscort = await tx.escort.create({
        data: { pseudo, email, telephone, motDePasseHash: hash },
      });

      // Attribuer le plan basique
      if (planBasique) {
        const dateFin = new Date();
        dateFin.setDate(dateFin.getDate() + planBasique.dureeJours);

        await tx.abonnement.create({
          data: {
            escortId:  newEscort.id,
            planId:    planBasique.id,
            dateFin,
            statut:    'ACTIF',
          },
        });
      }

      // Notification de bienvenue
      await tx.notification.create({
        data: {
          escortId: newEscort.id,
          type:     'ADMIN',
          titre:    'Bienvenue sur LeColis !',
          message:  'Votre compte a été créé. Vous pouvez maintenant publier avec votre plan Basique.',
        },
      });

      return newEscort;
    });

    // Générer tokens
    const accessToken  = signAccess({ sub: escort.id, role: 'escort' });
    const refreshToken = signRefresh({ sub: escort.id, role: 'escort' });

    // Sauvegarder le refresh token
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    await prisma.refreshToken.create({
      data: { token: refreshToken, escortId: escort.id, expiresAt },
    });

    return res.status(201).json({
      message:      'Compte créé avec succès.',
      accessToken,
      refreshToken,
      escort: {
        id:         escort.id,
        pseudo:     escort.pseudo,
        email:      escort.email,
        telephone:  escort.telephone,
        photoUrl:   escort.photoUrl,
        estVerifie: escort.estVerifie,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ── Connexion escort ──────────────────────────────────────
async function login(req, res, next) {
  try {
    const { email, motDePasse } = req.body;

    const escort = await prisma.escort.findUnique({ where: { email } });
    if (!escort) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
    }
    if (escort.estBanni) {
      return res.status(403).json({ message: 'Compte banni. Contactez le support.' });
    }

    const valide = await bcrypt.compare(motDePasse, escort.motDePasseHash);
    if (!valide) {
      return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
    }

    const accessToken  = signAccess({ sub: escort.id, role: 'escort' });
    const refreshToken = signRefresh({ sub: escort.id, role: 'escort' });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    await prisma.refreshToken.create({
      data: { token: refreshToken, escortId: escort.id, expiresAt },
    });

    return res.json({
      accessToken,
      refreshToken,
      escort: {
        id:         escort.id,
        pseudo:     escort.pseudo,
        email:      escort.email,
        telephone:  escort.telephone,
        photoUrl:   escort.photoUrl,
        estVerifie: escort.estVerifie,
        estBloque:  escort.estBloque,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ── Refresh token ─────────────────────────────────────────
async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ message: 'refreshToken requis.' });
    }

    // Vérifier le token JWT
    let payload;
    try {
      payload = verifyRefresh(refreshToken);
    } catch {
      return res.status(401).json({ message: 'Refresh token invalide ou expiré.' });
    }

    // Vérifier qu'il existe en base et n'est pas expiré
    const stored = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });
    if (!stored || stored.expiresAt < new Date()) {
      return res.status(401).json({ message: 'Session expirée. Reconnectez-vous.' });
    }

    // Rotation : supprimer l'ancien, créer un nouveau
    await prisma.refreshToken.delete({ where: { id: stored.id } });

    const newAccess  = signAccess({ sub: payload.sub, role: payload.role });
    const newRefresh = signRefresh({ sub: payload.sub, role: payload.role });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    await prisma.refreshToken.create({
      data: { token: newRefresh, escortId: payload.sub, expiresAt },
    });

    return res.json({ accessToken: newAccess, refreshToken: newRefresh });
  } catch (err) {
    next(err);
  }
}

// ── Déconnexion ───────────────────────────────────────────
async function logout(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
    }
    return res.json({ message: 'Déconnecté.' });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, refresh, logout };
