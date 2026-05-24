// src/controllers/abonnementController.js
const prisma = require('../config/prisma');

// ── GET /plans (liste publique des plans) ─────────────────
async function listerPlans(req, res, next) {
  try {
    const plans = await prisma.planAbonnement.findMany({
      where:   { actif: true },
      orderBy: { ordre: 'asc' },
    });
    return res.json(plans);
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/abonnement (abonnement actif de l'escort) ─
async function monAbonnement(req, res, next) {
  try {
    const abonnement = await prisma.abonnement.findFirst({
      where: {
        escortId: req.escort.id,
        statut:   'ACTIF',
        dateFin:  { gt: new Date() },
      },
      include:  { plan: true },
      orderBy:  { createdAt: 'desc' },
    });

    if (!abonnement) {
      return res.json({ abonnement: null });
    }

    const quota    = abonnement.nbPublicationsAdm ?? abonnement.plan.nbPublications;
    const pubsUsed = await prisma.publication.count({
      where: { escortId: req.escort.id, statut: 'ACTIVE', dateExpiration: { gt: new Date() } },
    });

    return res.json({
      abonnement: {
        ...abonnement,
        quotaTotal:   quota,
        quotaUtilise: pubsUsed,
        quotaRestant: Math.max(0, quota - pubsUsed),
      },
    });
  } catch (err) {
    next(err);
  }
}

// ── POST /abonnements/souscrire ───────────────────────────
// Simule la souscription (en prod : appel API Mobile Money d'abord)
async function souscrire(req, res, next) {
  try {
    const { planId, methodePaiement } = req.body;

    const plan = await prisma.planAbonnement.findUnique({ where: { id: planId } });
    if (!plan || !plan.actif) {
      return res.status(404).json({ message: 'Plan introuvable.' });
    }

    const dateFin = new Date();
    dateFin.setDate(dateFin.getDate() + plan.dureeJours);

    // Créer transaction + abonnement en une transaction DB
    const { abonnement, transaction } = await prisma.$transaction(async (tx) => {
      // Créer la transaction de paiement (EN_ATTENTE par défaut)
      const tr = await tx.transaction.create({
        data: {
          escortId:       req.escort.id,
          planNom:        plan.nom,
          montant:        plan.prix,
          methodePaiement,
          statut:         plan.prix === 0 ? 'SUCCES' : 'EN_ATTENTE',
        },
      });

      // Si plan gratuit → créer abonnement direct
      // Si plan payant → créer abonnement EN ATTENTE de confirmation paiement
      // (En prod : le webhook Mobile Money confirmera et passera à ACTIF)
      const ab = await tx.abonnement.create({
        data: {
          escortId:     req.escort.id,
          planId:       plan.id,
          dateFin,
          statut:       plan.prix === 0 ? 'ACTIF' : 'ACTIF', // simplifié pour la démo
          transactionId: tr.id, // sera connecté après
        },
      });

      // Lier la transaction à l'abonnement
      await tx.transaction.update({
        where: { id: tr.id },
        data:  { abonnementId: ab.id, statut: 'SUCCES' },
      });

      // Notification
      await tx.notification.create({
        data: {
          escortId: req.escort.id,
          type:     'ABONNEMENT',
          titre:    `Plan ${plan.nom} activé`,
          message:  `Votre abonnement ${plan.nom} est actif jusqu'au ${dateFin.toLocaleDateString('fr-FR')}.`,
        },
      });

      return { abonnement: ab, transaction: tr };
    });

    return res.status(201).json({
      message:     `Abonnement ${plan.nom} souscrit avec succès.`,
      abonnement,
      transaction,
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/historique-abonnements ────────────────────
async function historique(req, res, next) {
  try {
    const abonnements = await prisma.abonnement.findMany({
      where:   { escortId: req.escort.id },
      include: { plan: true, transaction: true },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(abonnements);
  } catch (err) {
    next(err);
  }
}

module.exports = { listerPlans, monAbonnement, souscrire, historique };
