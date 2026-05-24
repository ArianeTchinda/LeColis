// src/controllers/adminController.js
const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const { signAccess, signRefresh } = require('../config/jwt');

// ── POST /admin/login ─────────────────────────────────────
async function login(req, res, next) {
  try {
    const { email, motDePasse } = req.body;

    const admin = await prisma.admin.findUnique({ where: { email } });
    if (!admin) return res.status(401).json({ message: 'Identifiants incorrects.' });

    const valide = await bcrypt.compare(motDePasse, admin.motDePasseHash);
    if (!valide) return res.status(401).json({ message: 'Identifiants incorrects.' });

    const accessToken  = signAccess({ sub: admin.id, role: 'admin' });
    const refreshToken = signRefresh({ sub: admin.id, role: 'admin' });

    return res.json({
      accessToken, refreshToken,
      admin: { id: admin.id, email: admin.email, nom: admin.nom },
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/dashboard ──────────────────────────────────
async function dashboard(req, res, next) {
  try {
    const [
      totalEscorts,
      escortsVerifies,
      escortsBloques,
      totalPublications,
      pubsActives,
      totalTransactions,
      revenuTotal,
      signalements,
    ] = await Promise.all([
      prisma.escort.count(),
      prisma.escort.count({ where: { estVerifie: true } }),
      prisma.escort.count({ where: { estBloque: true } }),
      prisma.publication.count(),
      prisma.publication.count({ where: { statut: 'ACTIVE', dateExpiration: { gt: new Date() } } }),
      prisma.transaction.count({ where: { statut: 'SUCCES' } }),
      prisma.transaction.aggregate({ where: { statut: 'SUCCES' }, _sum: { montant: true } }),
      prisma.signalement.count({ where: { statut: 'EN_ATTENTE' } }),
    ]);

    return res.json({
      totalEscorts,
      escortsVerifies,
      escortsBloques,
      totalPublications,
      pubsActives,
      totalTransactions,
      revenuTotal: revenuTotal._sum.montant || 0,
      signalements,
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/escorts ────────────────────────────────────
async function listerEscorts(req, res, next) {
  try {
    const { search, estBloque, estBanni, estVerifie, page = '1', limite = '20' } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limite);
    const take = Math.min(parseInt(limite), 100);

    const where = {
      ...(search     && { OR: [
        { pseudo:    { contains: search, mode: 'insensitive' } },
        { email:     { contains: search, mode: 'insensitive' } },
        { telephone: { contains: search } },
      ]}),
      ...(estBloque  !== undefined && { estBloque:  estBloque  === 'true' }),
      ...(estBanni   !== undefined && { estBanni:   estBanni   === 'true' }),
      ...(estVerifie !== undefined && { estVerifie: estVerifie === 'true' }),
    };

    const [total, escorts] = await Promise.all([
      prisma.escort.count({ where }),
      prisma.escort.findMany({
        where,
        include: {
          abonnements: {
            where: { statut: 'ACTIF', dateFin: { gt: new Date() } },
            include: { plan: true },
            orderBy: { createdAt: 'desc' },
            take: 1,
          },
          _count: { select: { publications: true, transactions: true, signalements: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
    ]);

    return res.json({
      data: escorts.map((e) => ({
        id: e.id, pseudo: e.pseudo, email: e.email, telephone: e.telephone,
        photoUrl: e.photoUrl, estVerifie: e.estVerifie, estBloque: e.estBloque,
        estBanni: e.estBanni, createdAt: e.createdAt,
        abonnementActif: e.abonnements[0] || null,
        stats: e._count,
      })),
      total, page: parseInt(page), limite: take,
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/escorts/:id ────────────────────────────────
async function detailEscort(req, res, next) {
  try {
    const escort = await prisma.escort.findUnique({
      where:   { id: req.params.id },
      include: {
        abonnements:  { include: { plan: true }, orderBy: { createdAt: 'desc' } },
        transactions: { orderBy: { createdAt: 'desc' }, take: 20 },
        publications: { include: { images: { take: 1, orderBy: { ordre: 'asc' } } },
                        orderBy: { createdAt: 'desc' } },
        signalements: { orderBy: { createdAt: 'desc' } },
        sanctionsRecues: { orderBy: { createdAt: 'desc' } },
      },
    });

    if (!escort) return res.status(404).json({ message: 'Escort introuvable.' });
    return res.json(escort);
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/escorts/:id/verifier ──────────────────────
async function verifierEscort(req, res, next) {
  try {
    const { estVerifie } = req.body;
    await prisma.escort.update({
      where: { id: req.params.id },
      data:  { estVerifie: Boolean(estVerifie) },
    });
    return res.json({ message: `Escort ${estVerifie ? 'vérifiée' : 'non vérifiée'}.` });
  } catch (err) {
    next(err);
  }
}

// ── POST /admin/escorts/:id/sanctionner ──────────────────
async function sanctionner(req, res, next) {
  try {
    const { type, motif, dureeJours } = req.body;
    const escortId = req.params.id;

    const dateFin = dureeJours
      ? new Date(Date.now() + dureeJours * 86_400_000)
      : null;

    await prisma.$transaction(async (tx) => {
      await tx.sanction.create({
        data: {
          escortId,
          type,   // AVERTISSEMENT | BLOCAGE_TEMPORAIRE | BANNISSEMENT
          motif,
          dateFin,
          adminId: req.admin.id,
        },
      });

      if (type === 'BLOCAGE_TEMPORAIRE') {
        await tx.escort.update({ where: { id: escortId }, data: { estBloque: true } });
      }
      if (type === 'BANNISSEMENT') {
        await tx.escort.update({ where: { id: escortId }, data: { estBanni: true } });
      }

      // Notification à l'escort
      const labels = { AVERTISSEMENT: 'Avertissement', BLOCAGE_TEMPORAIRE: 'Blocage', BANNISSEMENT: 'Bannissement' };
      await tx.notification.create({
        data: {
          escortId,
          type:    'ADMIN',
          titre:   labels[type] || 'Sanction',
          message: motif,
        },
      });
    });

    return res.json({ message: 'Sanction appliquée.' });
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/escorts/:id/debloquer ─────────────────────
async function debloquer(req, res, next) {
  try {
    await prisma.$transaction([
      prisma.escort.update({
        where: { id: req.params.id },
        data:  { estBloque: false, estBanni: false },
      }),
      prisma.sanction.updateMany({
        where: { escortId: req.params.id, active: true },
        data:  { active: false },
      }),
    ]);
    return res.json({ message: 'Compte débloqué.' });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/signalements ───────────────────────────────
async function listerSignalements(req, res, next) {
  try {
    const { statut, page = '1', limite = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limite);

    const where = statut ? { statut } : {};

    const [total, signalements] = await Promise.all([
      prisma.signalement.count({ where }),
      prisma.signalement.findMany({
        where,
        include: {
          escortSignalee: { select: { id: true, pseudo: true, photoUrl: true } },
          publication:    { select: { id: true, titre: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Math.min(parseInt(limite), 100),
      }),
    ]);

    return res.json({ data: signalements, total });
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/signalements/:id ───────────────────────────
async function traiterSignalement(req, res, next) {
  try {
    const { statut } = req.body; // TRAITE | IGNORE
    await prisma.signalement.update({
      where: { id: req.params.id },
      data:  { statut },
    });
    return res.json({ message: 'Signalement mis à jour.' });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/plans ──────────────────────────────────────
async function listerPlans(req, res, next) {
  try {
    const plans = await prisma.planAbonnement.findMany({ orderBy: { ordre: 'asc' } });
    return res.json(plans);
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/plans/:id ──────────────────────────────────
async function modifierPlan(req, res, next) {
  try {
    const { prix, nbPublications, dureeJours, avantages, description, actif } = req.body;

    const plan = await prisma.planAbonnement.findUnique({ where: { id: req.params.id } });
    if (!plan) return res.status(404).json({ message: 'Plan introuvable.' });

    const updated = await prisma.planAbonnement.update({
      where: { id: req.params.id },
      data: {
        ...(prix           !== undefined && { prix: parseFloat(prix) }),
        ...(nbPublications !== undefined && { nbPublications: parseInt(nbPublications) }),
        ...(dureeJours     !== undefined && { dureeJours: parseInt(dureeJours) }),
        ...(avantages      !== undefined && { avantages }),
        ...(description    !== undefined && { description }),
        ...(actif          !== undefined && { actif: Boolean(actif) }),
      },
    });

    return res.json(updated);
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/abonnements/:id/ajuster ───────────────────
async function ajusterAbonnement(req, res, next) {
  try {
    const { nbPublicationsAdm, dateFin } = req.body;

    const ab = await prisma.abonnement.findUnique({ where: { id: req.params.id } });
    if (!ab) return res.status(404).json({ message: 'Abonnement introuvable.' });

    await prisma.abonnement.update({
      where: { id: req.params.id },
      data: {
        ...(nbPublicationsAdm !== undefined && { nbPublicationsAdm: parseInt(nbPublicationsAdm) }),
        ...(dateFin           !== undefined && { dateFin: new Date(dateFin) }),
      },
    });

    return res.json({ message: 'Abonnement ajusté.' });
  } catch (err) {
    next(err);
  }
}

// ── POST /admin/notifications/envoyer ────────────────────
async function envoyerNotification(req, res, next) {
  try {
    const { titre, message, type, cible, escortIds } = req.body;

    // Enregistrer la notification admin
    await prisma.notificationAdmin.create({
      data: { adminId: req.admin.id, titre, message, type, cible, escortIds: escortIds || [] },
    });

    // Créer les notifications escort
    let targets = [];
    if (cible === 'TOUS') {
      targets = await prisma.escort.findMany({ select: { id: true } });
    } else if (escortIds?.length) {
      targets = escortIds.map((id) => ({ id }));
    }

    if (targets.length) {
      await prisma.notification.createMany({
        data: targets.map(({ id }) => ({
          escortId: id, type, titre, message,
        })),
      });
    }

    return res.json({ message: `Notification envoyée à ${targets.length} escort(s).` });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/transactions ───────────────────────────────
async function listerTransactions(req, res, next) {
  try {
    const { statut, page = '1', limite = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limite);

    const where = statut ? { statut } : {};

    const [total, transactions] = await Promise.all([
      prisma.transaction.count({ where }),
      prisma.transaction.findMany({
        where,
        include: { escort: { select: { id: true, pseudo: true, email: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Math.min(parseInt(limite), 100),
      }),
    ]);

    return res.json({ data: transactions, total });
  } catch (err) {
    next(err);
  }
}

// ── GET /admin/publications ───────────────────────────────
async function listerPublications(req, res, next) {
  try {
    const { statut, escortId, page = '1', limite = '20' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limite);

    const where = {
      ...(statut   && { statut }),
      ...(escortId && { escortId }),
    };

    const [total, publications] = await Promise.all([
      prisma.publication.count({ where }),
      prisma.publication.findMany({
        where,
        include: {
          escort: { select: { id: true, pseudo: true } },
          images: { take: 1, orderBy: { ordre: 'asc' } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Math.min(parseInt(limite), 100),
      }),
    ]);

    return res.json({ data: publications, total });
  } catch (err) {
    next(err);
  }
}

// ── PUT /admin/publications/:id/statut ────────────────────
async function changerStatutPublication(req, res, next) {
  try {
    const { statut } = req.body; // ACTIVE | SUSPENDUE | BROUILLON
    await prisma.publication.update({
      where: { id: req.params.id },
      data:  { statut },
    });
    return res.json({ message: 'Statut mis à jour.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  login, dashboard,
  listerEscorts, detailEscort, verifierEscort, sanctionner, debloquer,
  listerSignalements, traiterSignalement,
  listerPlans, modifierPlan,
  ajusterAbonnement,
  envoyerNotification,
  listerTransactions,
  listerPublications, changerStatutPublication,
};
