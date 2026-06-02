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

        // Si l'abonnement a expiré → passer ses publications en EXPIREE
if (!abonnementActif) {
  await prisma.publication.updateMany({
    where: {
      escortId: req.escort.id,
      statut: 'ACTIVE',
    },
    data: { statut: 'EXPIREE' },
  });
}

    return res.json({ ...escort, abonnementActif });
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/me ────────────────────────────────────────
async function updateMe(req, res, next) {
  try {
    const { pseudo, telephone, email } = req.body;

    // Si l'email change, vérifier qu'il n'est pas déjà pris
    if (email) {
      const existing = await prisma.escort.findUnique({ where: { email } });
      if (existing && existing.id !== req.escort.id) {
        console.warn(`Profil update conflict: escort=${req.escort.id} tried to set email=${email} but already used by ${existing.id}`);
        return res.status(409).json({ message: 'Email déjà utilisé.' });
      }
    }

    const updated = await prisma.escort.update({
      where: { id: req.escort.id },
      data: {
        ...(pseudo    && { pseudo }),
        ...(telephone && { telephone }),
        ...(email     && { email }),
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
    console.log(`[updatePhoto] Start - escort=${req.escort.id}, file=${req.file ? req.file.originalname : 'NONE'}`);

    if (!req.file) {
      console.warn(`[updatePhoto] No file received for escort ${req.escort.id}`);
      return res.status(400).json({ message: 'Aucune image fournie.' });
    }

    // Supprimer l'ancienne photo MinIO si elle existe
    const existing = await prisma.escort.findUnique({
      where:  { id: req.escort.id },
      select: { photoKey: true },
    });
    if (existing?.photoKey) {
      console.log(`[updatePhoto] Deleting old photo - key=${existing.photoKey}`);
      await supprimerPhotoEscort(existing.photoKey);
    }

    // Upload nouvelle photo
    console.log(`[updatePhoto] Uploading new photo (${req.file.size} bytes)`);
    const { url, key } = await uploadPhotoEscort(req.file.buffer, req.escort.id);
    console.log(`[updatePhoto] Photo uploaded - key=${key}, url=${url}`);

    const updated = await prisma.escort.update({
      where: { id: req.escort.id },
      data:  { photoUrl: url, photoKey: key },
      select: { id: true, photoUrl: true },
    });

    console.log(`[updatePhoto] Success - photoUrl updated in DB`);
    return res.json({ message: 'Photo mise à jour.', photoUrl: updated.photoUrl });
  } catch (err) {
    console.error(`[updatePhoto] Error:`, err);
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

async function supprimerCompte(req, res, next) {
  try {
    await prisma.$transaction([
      prisma.publication.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.abonnement.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.transaction.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.notification.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.signalement.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.refreshToken.deleteMany({ where: { escortId: req.escort.id } }),
      prisma.escort.delete({ where: { id: req.escort.id } }),
    ]);
    return res.json({ message: 'Compte supprimé.' });
  } catch (err) { next(err); }
}



module.exports = {
  getMe, updateMe, updatePhoto, updatePassword,
  getNotifications, marquerLue, getTransactions,
  supprimerCompte
};
