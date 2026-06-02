// src/controllers/abonnementController.js
const prisma = require('../config/prisma');

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTES & HELPERS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════════════════

// Hiérarchie des plans nommés. Les plans custom utilisent leur champ `ordre`.
// basique=1 | standard=2 | premium=3 | custom=plan.ordre (défaut 99)
const NIVEAUX = { basique: 1, standard: 2, premium: 3 };

/**
 * Retourne le niveau numérique d'un plan.
 * Les plans nommés (basique/standard/premium) ont une priorité fixe.
 * Les plans custom créés par l'admin utilisent leur champ `ordre`.
 */
function niveauPlan(plan) {
  const nomNormalise = plan.nom.toLowerCase();
  if (NIVEAUX[nomNormalise] !== undefined) return NIVEAUX[nomNormalise];
  return plan.ordre ?? 99;
}

/**
 * Calcule le comportement lors d'une nouvelle souscription.
 *
 * Règles métier :
 * - Pas d'abonnement actif            → activer immédiatement (ACTIF)
 * - Nouveau plan ≥ plan actuel        → expirer l'actif, activer immédiatement (ACTIF)
 * - Nouveau plan < plan actuel        → mettre en file d'attente (ATTENTE_ACTIVATION),
 *                                       démarrage après la fin du dernier en attente
 *                                       (ou après la fin de l'actif si file vide)
 *
 * @returns {{ expirerActif: boolean, nouveauStatut: string, dateDebut: Date, dateFin: Date }}
 */
async function calculerComportement(escortId, plan, abActif) {
  const now = new Date();

  if (!abActif) {
    // Aucun abonnement actif → activation immédiate
    const dateFin = new Date(now);
    dateFin.setDate(dateFin.getDate() + plan.dureeJours);
    return { expirerActif: false, nouveauStatut: 'ACTIF', dateDebut: now, dateFin };
  }

  const nActif   = niveauPlan(abActif.plan);
  const nNouveau = niveauPlan(plan);

  if (nNouveau >= nActif) {
    // Plan supérieur ou égal → remplace immédiatement
    const dateFin = new Date(now);
    dateFin.setDate(dateFin.getDate() + plan.dureeJours);
    return { expirerActif: true, nouveauStatut: 'ACTIF', dateDebut: now, dateFin };
  }

  // Plan inférieur → file d'attente, s'enchaîne après le dernier en attente confirmé
  // On ne considère que les ATTENTE_ACTIVATION avec transaction SUCCES (cadeaux + paiements confirmés)
  const dernierEnAttente = await prisma.abonnement.findFirst({
    where: {
      escortId,
      statut: 'ATTENTE_ACTIVATION',
      transaction: { statut: 'SUCCES' },
    },
    orderBy: { dateFin: 'desc' },
  });

  const reference = dernierEnAttente
    ? new Date(dernierEnAttente.dateFin)
    : new Date(abActif.dateFin);

  const dateFin = new Date(reference);
  dateFin.setDate(dateFin.getDate() + plan.dureeJours);

  return {
    expirerActif:  false,
    nouveauStatut: 'ATTENTE_ACTIVATION',
    dateDebut:     reference,
    dateFin,
  };
}

/**
 * Expire un abonnement actif et remet toutes ses publications en BROUILLON.
 * Utilise une transaction Prisma fournie en paramètre (tx).
 *
 * IMPORTANT : On ne cible que les pubs ACTIVE de cet escort pour éviter
 * de toucher des pubs déjà EXPIREE d'anciens cycles.
 */
async function expirerAbonnementActif(tx, escortId, abActifId) {
  // 1. Expirer l'abonnement
  await tx.abonnement.update({
    where: { id: abActifId },
    data:  { statut: 'EXPIRE' },
  });

  // 2. Passer les publications ACTIVE → BROUILLON directement
  //    (on évite le double update ACTIVE→EXPIREE→BROUILLON qui touchait
  //     des publications EXPIREE d'anciens cycles sans rapport)
  await tx.publication.updateMany({
    where: { escortId, statut: 'ACTIVE' },
    data:  { statut: 'BROUILLON' },
  });
}

/**
 * Active un abonnement en attente : le passe ACTIF et met à jour
 * les dateExpiration de toutes les publications ACTIVE et BROUILLON.
 * Remet aussi les publications EXPIREE en BROUILLON pour que l'escort
 * puisse les republier avec le nouvel abonnement.
 */
async function activerAbonnementEnAttente(tx, escortId, abAttente) {
  await tx.abonnement.update({
    where: { id: abAttente.id },
    data:  { statut: 'ACTIF' },
  });

  // Remettre les EXPIREE en BROUILLON (pubs de l'escort qui ont expiré
  // mais qu'elle pourra republier maintenant qu'un abonnement redémarre)
  await tx.publication.updateMany({
    where: { escortId, statut: 'EXPIREE' },
    data:  { statut: 'BROUILLON' },
  });

  // Mettre à jour la dateExpiration des pubs ACTIVE et BROUILLON
  await tx.publication.updateMany({
    where: { escortId, statut: { in: ['ACTIVE', 'BROUILLON'] } },
    data:  { dateExpiration: abAttente.dateFin },
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /abonnements/plans — liste publique des plans actifs
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// GET /profil/abonnement — abonnement actif de l'escort + maintenance auto
// ═══════════════════════════════════════════════════════════════════════════════
async function monAbonnement(req, res, next) {
  try {
    const escortId = req.escort.id;

    // ── Étape 1 : Expirer les abonnements ACTIF dont la dateFin est dépassée ──
    const expiresActifs = await prisma.abonnement.findMany({
      where: { escortId, statut: 'ACTIF', dateFin: { lte: new Date() } },
      select: { id: true },
    });

    for (const ab of expiresActifs) {
      await prisma.$transaction(async (tx) => {
        await tx.abonnement.update({ where: { id: ab.id }, data: { statut: 'EXPIRE' } });
        // Les pubs ACTIVE deviennent EXPIREE (pas BROUILLON directement,
        // on attend le prochain abonnement pour les remettre disponibles)
        await tx.publication.updateMany({
          where: { escortId, statut: 'ACTIVE' },
          data:  { statut: 'EXPIREE' },
        });
      });
    }

    // ── Étape 2 : Annuler les ATTENTE_ACTIVATION orphelins (> 48h sans paiement) ──
    // On conserve ceux dont la transaction est SUCCES (cadeaux + paiements confirmés)
    const enAttenteAnciens = await prisma.abonnement.findMany({
      where: {
        escortId,
        statut:    'ATTENTE_ACTIVATION',
        createdAt: { lt: new Date(Date.now() - 48 * 60 * 60 * 1000) },
      },
      include: { transaction: true },
    });

    for (const ab of enAttenteAnciens) {
      const trConfirmee = ab.transaction?.statut === 'SUCCES';
      if (!trConfirmee) {
        await prisma.$transaction(async (tx) => {
          await tx.abonnement.update({ where: { id: ab.id }, data: { statut: 'ANNULE' } });
          if (ab.transaction && ab.transaction.statut === 'EN_ATTENTE') {
            await tx.transaction.update({
              where: { id: ab.transaction.id },
              data:  { statut: 'ECHEC' },
            });
          }
        });
      }
    }

    // ── Étape 3 : Activer le prochain ATTENTE_ACTIVATION si plus d'abonnement actif ──
    const abActifEnCours = await prisma.abonnement.findFirst({
      where: { escortId, statut: 'ACTIF', dateFin: { gt: new Date() } },
    });

    if (!abActifEnCours) {
      const prochainEnAttente = await prisma.abonnement.findFirst({
        where: {
          escortId,
          statut:    'ATTENTE_ACTIVATION',
          dateDebut: { lte: new Date() },
          // Seulement les abonnements dont le paiement est confirmé
          transaction: { statut: 'SUCCES' },
        },
        orderBy: { dateDebut: 'asc' },
      });

      if (prochainEnAttente) {
        await prisma.$transaction(async (tx) => {
          await activerAbonnementEnAttente(tx, escortId, prochainEnAttente);
          await tx.notification.create({
            data: {
              escortId,
              type:    'ABONNEMENT',
              titre:   'Abonnement activé 🎉',
              message: `Votre plan en attente est maintenant actif jusqu'au `
                     + `${new Date(prochainEnAttente.dateFin).toLocaleDateString('fr-FR')}.`,
            },
          });
        });
      }
    }

    // ── Étape 4 : Charger l'abonnement ACTIF après maintenance ──
    const abonnement = await prisma.abonnement.findFirst({
      where:   { escortId, statut: 'ACTIF', dateFin: { gt: new Date() } },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!abonnement) {
      return res.json({ abonnement: null });
    }

    // Quota : nbPublicationsAdm si défini par l'admin, sinon valeur du plan
    const quota    = abonnement.nbPublicationsAdm ?? abonnement.plan.nbPublications;
    const pubsUsed = await prisma.publication.count({
      where: { escortId, statut: 'ACTIVE', dateExpiration: { gt: new Date() } },
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

// ═══════════════════════════════════════════════════════════════════════════════
// POST /abonnements/souscrire
// Réservé aux plans GRATUITS (prix === 0).
// Les plans payants passent par POST /paiement/creer-lien → webhook TaraMoney.
// ═══════════════════════════════════════════════════════════════════════════════
async function souscrire(req, res, next) {
  try {
    const { planId } = req.body;
    const escortId   = req.escort.id;

    const plan = await prisma.planAbonnement.findUnique({ where: { id: planId } });
    if (!plan || !plan.actif) {
      return res.status(404).json({ message: 'Plan introuvable.' });
    }

    if (plan.prix > 0) {
      return res.status(400).json({
        message: 'Ce plan est payant. Utilisez /paiement/creer-lien.',
      });
    }

    const abActif = await prisma.abonnement.findFirst({
      where:   { escortId, statut: 'ACTIF', dateFin: { gt: new Date() } },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    const { expirerActif, nouveauStatut, dateDebut, dateFin } =
      await calculerComportement(escortId, plan, abActif);

    const { abonnement, transaction } = await prisma.$transaction(async (tx) => {
      // Expirer l'abonnement actif si nécessaire
      if (expirerActif && abActif) {
        await expirerAbonnementActif(tx, escortId, abActif.id);
      }

      // Créer la transaction (montant 0, statut SUCCES immédiat)
      const tr = await tx.transaction.create({
        data: {
          escortId,
          planNom:         plan.nom,
          montant:         0,
          methodePaiement: 'Gratuit',
          statut:          'SUCCES',
        },
      });

      // Créer l'abonnement
      const ab = await tx.abonnement.create({
        data: {
          escortId,
          planId:        plan.id,
          dateDebut,
          dateFin,
          statut:        nouveauStatut,
          transactionId: tr.id,
        },
      });

      // Lier la transaction à l'abonnement
      await tx.transaction.update({
        where: { id: tr.id },
        data:  { abonnement: { connect: { id: ab.id } } },
      });

      // Si activation immédiate → mettre à jour les publications
      if (nouveauStatut === 'ACTIF') {
        // Remettre les EXPIREE en BROUILLON
        await tx.publication.updateMany({
          where: { escortId, statut: 'EXPIREE' },
          data:  { statut: 'BROUILLON' },
        });
        // Mettre à jour la date d'expiration
        await tx.publication.updateMany({
          where: { escortId, statut: { in: ['ACTIVE', 'BROUILLON'] } },
          data:  { dateExpiration: dateFin },
        });
      }

      await tx.notification.create({
        data: {
          escortId,
          type:    'ABONNEMENT',
          titre:   nouveauStatut === 'ACTIF'
            ? `Plan ${plan.nom} activé ✅`
            : `Plan ${plan.nom} en attente ⏳`,
          message: nouveauStatut === 'ACTIF'
            ? `Votre abonnement ${plan.nom} est actif jusqu'au ${dateFin.toLocaleDateString('fr-FR')}.`
            : `Votre abonnement ${plan.nom} démarrera le ${dateDebut.toLocaleDateString('fr-FR')} `
            + `et expirera le ${dateFin.toLocaleDateString('fr-FR')}.`,
        },
      });

      return { abonnement: ab, transaction: tr };
    });

    return res.status(201).json({
      message:     `Abonnement ${plan.nom} souscrit avec succès.`,
      abonnement,
      transaction,
      statut:      nouveauStatut,
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /profil/historique-abonnements
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// EXPORTS
// Helpers partagés exportés pour adminController et paiementController
// ═══════════════════════════════════════════════════════════════════════════════
module.exports = {
  // Routes
  listerPlans,
  monAbonnement,
  souscrire,
  historique,
  // Helpers internes partagés
  calculerComportement,
  expirerAbonnementActif,
  activerAbonnementEnAttente,
  niveauPlan,
  NIVEAUX,
};