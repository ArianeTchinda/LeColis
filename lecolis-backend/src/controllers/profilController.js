// src/controllers/profilController.js
const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const { uploadPhotoEscort, supprimerPhotoEscort } = require('../services/imageService');

// ── GET /profil/me ────────────────────────────────────────
async function getMe(req, res, next) {
  try {
    const escort = await prisma.escort.findUnique({
      where: { id: req.escort.id },
      select: {
        id: true, pseudo: true, email: true, telephone: true,
        photoUrl: true, estVerifie: true, estBloque: true,
        createdAt: true,
        abonnements: {
          where:   { statut: 'ACTIF' },
          orderBy: { createdAt: 'desc' },
          take: 1,
          include: { plan: true },
        },
      },
    });

    // Abonnement actif (vérifie aussi la date)
    const abonnementActif = escort.abonnements.find(
      (a) => new Date(a.dateFin) > new Date()
    ) || null;

    return res.json({ ...escort, abonnementActif });
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/me ────────────────────────────────────────
async function updateMe(req, res, next) {
  try {
    const { pseudo, telephone } = req.body;

    const updated = await prisma.escort.update({
      where: { id: req.escort.id },
      data: {
        ...(pseudo    && { pseudo }),
        ...(telephone && { telephone }),
      },
      select: { id: true, pseudo: true, email: true, telephone: true, photoUrl: true },
    });

    return res.json(updated);
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/photo ─────────────────────────────────────
async function updatePhoto(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Aucune image fournie.' });
    }

    // Supprimer l'ancienne photo MinIO si elle existe
    const existing = await prisma.escort.findUnique({
      where:  { id: req.escort.id },
      select: { photoKey: true },
    });
    if (existing?.photoKey) {
      await supprimerPhotoEscort(existing.photoKey);
    }

    // Upload nouvelle photo
    const { url, key } = await uploadPhotoEscort(req.file.buffer, req.escort.id);

    const updated = await prisma.escort.update({
      where: { id: req.escort.id },
      data:  { photoUrl: url, photoKey: key },
      select: { id: true, photoUrl: true },
    });

    return res.json({ message: 'Photo mise à jour.', photoUrl: updated.photoUrl });
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/mot-de-passe ──────────────────────────────
async function updatePassword(req, res, next) {
  try {
    const { ancienMotDePasse, nouveauMotDePasse } = req.body;

    const escort = await prisma.escort.findUnique({
      where:  { id: req.escort.id },
      select: { motDePasseHash: true },
    });

    const valide = await bcrypt.compare(ancienMotDePasse, escort.motDePasseHash);
    if (!valide) {
      return res.status(400).json({ message: 'Ancien mot de passe incorrect.' });
    }

    const hash = await bcrypt.hash(nouveauMotDePasse, 12);
    await prisma.escort.update({
      where: { id: req.escort.id },
      data:  { motDePasseHash: hash },
    });

    // Invalider tous les refresh tokens
    await prisma.refreshToken.deleteMany({ where: { escortId: req.escort.id } });

    return res.json({ message: 'Mot de passe mis à jour. Reconnectez-vous.' });
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/notifications ─────────────────────────────
async function getNotifications(req, res, next) {
  try {
    const notifications = await prisma.notification.findMany({
      where:   { escortId: req.escort.id },
      orderBy: { createdAt: 'desc' },
      take:    50,
    });
    return res.json(notifications);
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/notifications/:id/lue ────────────────────
async function marquerLue(req, res, next) {
  try {
    await prisma.notification.updateMany({
      where: { id: req.params.id, escortId: req.escort.id },
      data:  { lue: true },
    });
    return res.json({ message: 'Notification marquée comme lue.' });
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/transactions ──────────────────────────────
async function getTransactions(req, res, next) {
  try {
    const transactions = await prisma.transaction.findMany({
      where:   { escortId: req.escort.id },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(transactions);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMe, updateMe, updatePhoto, updatePassword,
  getNotifications, marquerLue, getTransactions,
};
