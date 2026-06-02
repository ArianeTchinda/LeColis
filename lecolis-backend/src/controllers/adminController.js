// src/controllers/adminController.js
const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const { signAccess, signRefresh } = require('../config/jwt');
const {
  calculerComportement,
  expirerAbonnementActif,
  activerAbonnementEnAttente,
  niveauPlan,
} = require('./abonnementController');

// ═══════════════════════════════════════════════════════════════════════════════
// POST /admin/login
// ═══════════════════════════════════════════════════════════════════════════════
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
      accessToken,
      refreshToken,
      admin: { id: admin.id, email: admin.email, nom: admin.nom },
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/dashboard
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/escorts
// ═══════════════════════════════════════════════════════════════════════════════
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
            where:   { statut: 'ACTIF', dateFin: { gt: new Date() } },
            include: { plan: true },
            orderBy: { createdAt: 'desc' },
            take:    1,
          },
          publications: { select: { vues: true } },
          _count: { select: { publications: true, transactions: true, signalements: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
    ]);

    return res.json({
      data: escorts.map((e) => ({
        id:        e.id,
        pseudo:    e.pseudo,
        email:     e.email,
        telephone: e.telephone,
        photoUrl:  e.photoUrl,
        estVerifie: e.estVerifie,
        estBloque:  e.estBloque,
        estBanni:   e.estBanni,
        createdAt:  e.createdAt,
        abonnementActif: e.abonnements[0] ?? null,
        stats: {
          ...e._count,
          vues: e.publications.reduce((sum, p) => sum + (p.vues || 0), 0),
        },
      })),
      total,
      page:   parseInt(page),
      limite: take,
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/escorts/:id
// ═══════════════════════════════════════════════════════════════════════════════
async function detailEscort(req, res, next) {
  try {
    const escort = await prisma.escort.findUnique({
      where:   { id: req.params.id },
      include: {
        abonnements:     { include: { plan: true, transaction: true }, orderBy: { createdAt: 'desc' } },
        transactions:    { orderBy: { createdAt: 'desc' }, take: 20 },
        publications:    {
          include: { images: { take: 1, orderBy: { ordre: 'asc' } } },
          orderBy: { createdAt: 'desc' },
        },
        signalements:    { orderBy: { createdAt: 'desc' } },
        sanctionsRecues: { orderBy: { createdAt: 'desc' } },
      },
    });

    if (!escort) return res.status(404).json({ message: 'Escort introuvable.' });
    return res.json(escort);
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/escorts/:id/verifier
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// POST /admin/escorts/:id/sanctionner
// ═══════════════════════════════════════════════════════════════════════════════
async function sanctionner(req, res, next) {
  try {
    const { type, motif, dureeJours } = req.body;
    const escortId = req.params.id;

    const dateFin = dureeJours
      ? new Date(Date.now() + dureeJours * 86_400_000)
      : null;

    await prisma.$transaction(async (tx) => {
      await tx.sanction.create({
        data: { escortId, type, motif, dateFin, adminId: req.admin.id },
      });

      if (type === 'BLOCAGE_TEMPORAIRE') {
        await tx.escort.update({ where: { id: escortId }, data: { estBloque: true } });
      }
      if (type === 'BANNISSEMENT') {
        await tx.escort.update({ where: { id: escortId }, data: { estBanni: true } });
      }

      const labels = {
        AVERTISSEMENT:      'Avertissement reçu',
        BLOCAGE_TEMPORAIRE: 'Compte temporairement bloqué',
        BANNISSEMENT:       'Compte banni',
      };
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

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/escorts/:id/debloquer
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/signalements
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/signalements/:id
// ═══════════════════════════════════════════════════════════════════════════════
async function traiterSignalement(req, res, next) {
  try {
    const { statut } = req.body;
    await prisma.signalement.update({
      where: { id: req.params.id },
      data:  { statut },
    });
    return res.json({ message: 'Signalement mis à jour.' });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/plans
// ═══════════════════════════════════════════════════════════════════════════════
async function listerPlans(req, res, next) {
  try {
    const plans = await prisma.planAbonnement.findMany({ orderBy: { ordre: 'asc' } });
    return res.json(plans);
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST /admin/plans
// ═══════════════════════════════════════════════════════════════════════════════
async function creerPlan(req, res, next) {
  try {
    const { nom, description, prix, nbPublications, dureeJours, avantages, accentColor } = req.body;

    if (!nom || !nom.trim()) {
      return res.status(400).json({ message: 'Le nom du plan est requis.' });
    }

    const existant = await prisma.planAbonnement.findUnique({ where: { nom: nom.trim() } });
    if (existant) {
      return res.status(409).json({ message: `Un plan "${nom}" existe déjà.` });
    }

    const dernierPlan = await prisma.planAbonnement.findFirst({
      orderBy: { ordre: 'desc' },
      select:  { ordre: true },
    });
    const ordre = (dernierPlan?.ordre ?? 0) + 1;

    const plan = await prisma.planAbonnement.create({
      data: {
        nom:            nom.trim(),
        description:    description   ?? '',
        prix:           parseFloat(prix) || 0,
        nbPublications: parseInt(nbPublications) || 1,
        dureeJours:     parseInt(dureeJours)     || 30,
        avantages:      avantages ?? [],
        accentColor:    accentColor ?? '#B68DFF',
        icone:          'star_rounded',
        estBasique:     false,
        estBase:        false,
        actif:          true,
        ordre,
      },
    });

    return res.status(201).json(plan);
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/plans/:id
// ═══════════════════════════════════════════════════════════════════════════════
async function modifierPlan(req, res, next) {
  try {
    const { prix, nbPublications, dureeJours, avantages, description, actif, accentColor } = req.body;

    const plan = await prisma.planAbonnement.findUnique({ where: { id: req.params.id } });
    if (!plan) return res.status(404).json({ message: 'Plan introuvable.' });

    const updated = await prisma.planAbonnement.update({
      where: { id: req.params.id },
      data: {
        ...(prix           !== undefined && { prix:           parseFloat(prix) }),
        ...(nbPublications !== undefined && { nbPublications: parseInt(nbPublications) }),
        ...(dureeJours     !== undefined && { dureeJours:     parseInt(dureeJours) }),
        ...(avantages      !== undefined && { avantages }),
        ...(description    !== undefined && { description }),
        ...(actif          !== undefined && { actif: Boolean(actif) }),
        ...(accentColor    !== undefined && { accentColor }),
      },
    });

    return res.json(updated);
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE /admin/plans/:id
// ═══════════════════════════════════════════════════════════════════════════════
async function supprimerPlan(req, res, next) {
  try {
    const plan = await prisma.planAbonnement.findUnique({ where: { id: req.params.id } });
    if (!plan) return res.status(404).json({ message: 'Plan introuvable.' });

    if (plan.estBase) {
      return res.status(403).json({
        message: 'Les plans de base (Basique, Standard, Premium) ne peuvent pas être supprimés.',
      });
    }

    const abonnementsActifs = await prisma.abonnement.count({
      where: {
        planId: plan.id,
        statut: { in: ['ACTIF', 'ATTENTE_ACTIVATION'] },
        dateFin: { gt: new Date() },
      },
    });

    if (abonnementsActifs > 0) {
      return res.status(409).json({
        message: `Impossible de supprimer : ${abonnementsActifs} abonnement(s) actif(s) ou en attente utilisent ce plan.`,
      });
    }

    await prisma.planAbonnement.delete({ where: { id: req.params.id } });
    return res.json({ message: `Plan "${plan.nom}" supprimé avec succès.` });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/abonnements/:id/ajuster
//
// Permet à l'admin de modifier :
// - deltaJours     : ajouter ou retirer des jours à l'abonnement (et aux publications ACTIVE)
// - nbPublicationsAdm : override du quota de publications du plan
//
// Si l'abonnement est en ATTENTE_ACTIVATION, on ajuste aussi sans toucher aux publications
// (elles ne sont pas encore actives).
// ═══════════════════════════════════════════════════════════════════════════════
async function ajusterAbonnement(req, res, next) {
  try {
    const { deltaJours, nbPublicationsAdm } = req.body;

    const ab = await prisma.abonnement.findUnique({
      where:   { id: req.params.id },
      include: { plan: true },
    });
    if (!ab) return res.status(404).json({ message: 'Abonnement introuvable.' });

    if (!['ACTIF', 'ATTENTE_ACTIVATION'].includes(ab.statut)) {
      return res.status(400).json({
        message: `Impossible d'ajuster un abonnement en statut "${ab.statut}".`,
      });
    }

    let nouvelleDateFin = new Date(ab.dateFin);

    if (deltaJours !== undefined) {
      const delta = parseInt(deltaJours);
      nouvelleDateFin = new Date(nouvelleDateFin.getTime() + delta * 86_400_000);

      // Vérifier qu'il restera au moins 1 jour
      const joursRestants = Math.floor((nouvelleDateFin.getTime() - Date.now()) / 86_400_000);
      if (joursRestants < 1) {
        return res.status(400).json({
          message: 'Impossible : il doit rester au moins 1 jour à l\'abonnement après ajustement.',
        });
      }
    }

    await prisma.$transaction(async (tx) => {
      await tx.abonnement.update({
        where: { id: req.params.id },
        data: {
          dateFin: nouvelleDateFin,
          ...(nbPublicationsAdm !== undefined && {
            nbPublicationsAdm: parseInt(nbPublicationsAdm),
          }),
        },
      });

      // Mettre à jour la dateExpiration des publications ACTIVE uniquement
      // (les BROUILLON recevront la bonne date lors de leur prochaine activation)
      if (deltaJours !== undefined && ab.statut === 'ACTIF') {
        const delta = parseInt(deltaJours);
        const pubs  = await tx.publication.findMany({
          where:  { escortId: ab.escortId, statut: 'ACTIVE' },
          select: { id: true, dateExpiration: true },
        });

        for (const pub of pubs) {
          const nouvelleExp = new Date(
            new Date(pub.dateExpiration).getTime() + delta * 86_400_000
          );
          await tx.publication.update({
            where: { id: pub.id },
            data:  { dateExpiration: nouvelleExp },
          });
        }
      }

      // Notification à l'escort
      const parties = [];
      if (deltaJours !== undefined) {
        const d = parseInt(deltaJours);
        parties.push(d > 0
          ? `+${d} jour${d > 1 ? 's' : ''} ajouté${d > 1 ? 's' : ''} à votre abonnement`
          : `${Math.abs(d)} jour${Math.abs(d) > 1 ? 's' : ''} retiré${Math.abs(d) > 1 ? 's' : ''} de votre abonnement`);
      }
      if (nbPublicationsAdm !== undefined) {
        parties.push(`quota de publications ajusté à ${parseInt(nbPublicationsAdm)}`);
      }

      if (parties.length > 0) {
        await tx.notification.create({
          data: {
            escortId: ab.escortId,
            type:     'ABONNEMENT',
            titre:    'Abonnement ajusté par l\'administrateur ✏️',
            message:  `Votre abonnement a été modifié : ${parties.join(', ')}. `
                    + `Nouvelle expiration : ${nouvelleDateFin.toLocaleDateString('fr-FR')}.`,
          },
        });
      }
    });

    return res.json({
      message: 'Abonnement ajusté avec succès.',
      dateFin: nouvelleDateFin.toISOString(),
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST /admin/escorts/:id/cadeau
//
// Offre un plan cadeau à un ou plusieurs escorts sans paiement.
// Utilise les mêmes helpers que abonnementController pour garantir
// une logique identique (plan sup/inf, file d'attente, publications).
//
// Body : { planId, escortIds?: string[] }
// - Si escortIds est fourni, on offre à tous (+ l'escort du param :id)
// - Maximum 50 comptes par requête
// ═══════════════════════════════════════════════════════════════════════════════
async function offrirCadeau(req, res, next) {
  try {
    const escortIdParam = req.params.id;
    const { planId, escortIds: ids } = req.body;

    if (!planId) return res.status(400).json({ message: 'planId est requis.' });

    const plan = await prisma.planAbonnement.findUnique({ where: { id: planId } });
    if (!plan || !plan.actif) {
      return res.status(404).json({ message: 'Plan introuvable ou inactif.' });
    }

    // Dédupliquer les cibles
    const cibles = ids && ids.length > 0
      ? [...new Set([escortIdParam, ...ids])]
      : [escortIdParam];

    if (cibles.length > 50) {
      return res.status(400).json({ message: 'Maximum 50 comptes par cadeau groupé.' });
    }

    const resultats = [];

    for (const escortId of cibles) {
      try {
        const escort = await prisma.escort.findUnique({ where: { id: escortId } });
        if (!escort) {
          resultats.push({ escortId, statut: 'introuvable' });
          continue;
        }

        const abActif = await prisma.abonnement.findFirst({
          where:   { escortId, statut: 'ACTIF', dateFin: { gt: new Date() } },
          include: { plan: true },
          orderBy: { createdAt: 'desc' },
        });

        const { expirerActif, nouveauStatut, dateDebut, dateFin } =
          await calculerComportement(escortId, plan, abActif);

        await prisma.$transaction(async (tx) => {
          // Expirer l'abonnement actif si le cadeau le remplace
          if (expirerActif && abActif) {
            await expirerAbonnementActif(tx, escortId, abActif.id);
          }

          // Créer la transaction (cadeau = montant 0, statut SUCCES immédiat)
          const tr = await tx.transaction.create({
            data: {
              escortId,
              planNom:         plan.nom,
              montant:         0,
              methodePaiement: 'Cadeau administrateur',
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

          // Lier transaction ↔ abonnement
          await tx.transaction.update({
            where: { id: tr.id },
            data:  { abonnement: { connect: { id: ab.id } } },
          });

          // Mettre à jour les publications si activation immédiate
          if (nouveauStatut === 'ACTIF') {
            await activerAbonnementEnAttente(tx, escortId, ab);
          }

          // Notification à l'escort
          await tx.notification.create({
            data: {
              escortId,
              type:    'ABONNEMENT',
              titre:   `🎁 Plan ${plan.nom} offert par l'administrateur`,
              message: nouveauStatut === 'ACTIF'
                ? `L'administrateur vous a offert le plan ${plan.nom}, actif jusqu'au ${dateFin.toLocaleDateString('fr-FR')}.`
                : `L'administrateur vous a offert le plan ${plan.nom}. Il démarrera le ${dateDebut.toLocaleDateString('fr-FR')} et expirera le ${dateFin.toLocaleDateString('fr-FR')}.`,
            },
          });
        });

        resultats.push({
          escortId,
          pseudo:       escort.pseudo,
          statut:       'ok',
          plan:         plan.nom,
          nouveauStatut,
          dateDebut:    dateDebut.toISOString(),
          dateFin:      dateFin.toISOString(),
        });
      } catch (errEscort) {
        console.error(`[offrirCadeau] Erreur pour escortId ${escortId}:`, errEscort);
        resultats.push({ escortId, statut: 'erreur', detail: errEscort.message });
      }
    }

    const nbOk = resultats.filter(r => r.statut === 'ok').length;
    return res.status(201).json({
      message:   `Plan "${plan.nom}" offert à ${nbOk} compte(s).`,
      resultats,
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST /admin/notifications/envoyer
// ═══════════════════════════════════════════════════════════════════════════════
async function envoyerNotification(req, res, next) {
  try {
    const { titre, message, type, cible, escortIds } = req.body;

    await prisma.notificationAdmin.create({
      data: { adminId: req.admin.id, titre, message, type, cible, escortIds: escortIds || [] },
    });

    let targets = [];
    if (cible === 'TOUS') {
      targets = await prisma.escort.findMany({ select: { id: true } });
    } else if (escortIds?.length) {
      targets = escortIds.map((id) => ({ id }));
    }

    if (targets.length) {
      await prisma.notification.createMany({
        data: targets.map(({ id }) => ({ escortId: id, type, titre, message })),
      });
    }

    return res.json({ message: `Notification envoyée à ${targets.length} escort(s).` });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/notifications/historique
// ═══════════════════════════════════════════════════════════════════════════════
async function historiqueNotifications(req, res, next) {
  try {
    const { page = '1', limite = '20', cible, escortId } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limite);
    const take = Math.min(parseInt(limite), 100);

    const where = {
      ...(cible    && { cible }),
      ...(escortId && {
        OR: [
          { escortIds: { has: escortId } },
          { cible: 'TOUS' },
        ],
      }),
    };

    const [total, notifications] = await Promise.all([
      prisma.notificationAdmin.count({ where }),
      prisma.notificationAdmin.findMany({
        where,
        include: { admin: { select: { id: true, nom: true, email: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
    ]);

    const notifEnrichies = await Promise.all(
      notifications.map(async (n) => {
        let escortsCibles = [];
        if (n.escortIds.length > 0) {
          escortsCibles = await prisma.escort.findMany({
            where:  { id: { in: n.escortIds } },
            select: { id: true, pseudo: true, photoUrl: true },
          });
        }
        return { ...n, escortsCibles };
      })
    );

    return res.json({ data: notifEnrichies, total, page: parseInt(page), limite: take });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/transactions
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/publications
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /admin/publications/:id/statut
// ═══════════════════════════════════════════════════════════════════════════════
async function changerStatutPublication(req, res, next) {
  try {
    const { statut } = req.body;

    const statutsValides = ['ACTIVE', 'EXPIREE', 'BROUILLON', 'SUSPENDUE'];
    if (!statutsValides.includes(statut)) {
      return res.status(400).json({ message: `Statut invalide. Valeurs : ${statutsValides.join(', ')}.` });
    }

    const pub = await prisma.publication.findUnique({ where: { id: req.params.id } });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    await prisma.publication.update({
      where: { id: req.params.id },
      data:  { statut },
    });

    return res.json({ message: 'Statut de la publication mis à jour.' });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /admin/analytics
// ═══════════════════════════════════════════════════════════════════════════════
async function analytics(req, res, next) {
  try {
    const now       = new Date();
    const il_y_a_12 = new Date(now);
    il_y_a_12.setMonth(il_y_a_12.getMonth() - 11);
    il_y_a_12.setDate(1);
    il_y_a_12.setHours(0, 0, 0, 0);

    const il_y_a_8sem = new Date(now);
    il_y_a_8sem.setDate(il_y_a_8sem.getDate() - 7 * 7);

    const [
      inscriptionsParSemaine,
      plansActifs,
      revenusParMois,
      pubsParStatut,
      topVilles,
      signalementsParMotif,
      methodesParement,
      totalEscorts,
      escortsVerifies,
      escortsBloques,
      escortsBannis,
      transactionsMois,
      sanctionsParType,
      abonnementsStatut,
      noteMoyenne,
      totalAvis,
    ] = await Promise.all([
      prisma.$queryRaw`
        SELECT DATE_TRUNC('week', "createdAt") AS semaine, COUNT(*)::int AS total
        FROM escorts WHERE "createdAt" >= ${il_y_a_8sem}
        GROUP BY semaine ORDER BY semaine ASC
      `,
      prisma.abonnement.groupBy({
        by:    ['planId'],
        where: { statut: 'ACTIF', dateFin: { gt: now } },
        _count: { id: true },
      }),
      prisma.$queryRaw`
        SELECT DATE_TRUNC('month', "createdAt") AS mois,
               SUM(montant)::float AS total, COUNT(*)::int AS nb
        FROM transactions
        WHERE statut = 'SUCCES' AND "createdAt" >= ${il_y_a_12}
        GROUP BY mois ORDER BY mois ASC
      `,
      prisma.publication.groupBy({ by: ['statut'], _count: { id: true } }),
      prisma.$queryRaw`
        SELECT "villeNom" AS ville, COUNT(*)::int AS total
        FROM publications GROUP BY "villeNom" ORDER BY total DESC LIMIT 8
      `,
      prisma.$queryRaw`
        SELECT motif, COUNT(*)::int AS total
        FROM signalements GROUP BY motif ORDER BY total DESC LIMIT 8
      `,
      prisma.$queryRaw`
        SELECT "methodePaiement" AS methode, COUNT(*)::int AS total
        FROM transactions WHERE statut = 'SUCCES'
        GROUP BY "methodePaiement" ORDER BY total DESC
      `,
      prisma.escort.count(),
      prisma.escort.count({ where: { estVerifie: true } }),
      prisma.escort.count({ where: { estBloque: true } }),
      prisma.escort.count({ where: { estBanni: true } }),
      prisma.$queryRaw`
        SELECT DATE_TRUNC('month', "createdAt") AS mois, statut, COUNT(*)::int AS total
        FROM transactions WHERE "createdAt" >= ${il_y_a_12}
        GROUP BY mois, statut ORDER BY mois ASC
      `,
      prisma.sanction.groupBy({ by: ['type'], _count: { id: true } }),
      prisma.abonnement.groupBy({ by: ['statut'], _count: { id: true } }),
      prisma.avis.aggregate({ _avg: { note: true } }),
      prisma.avis.count(),
    ]);

    const plans   = await prisma.planAbonnement.findMany({
      select: { id: true, nom: true, accentColor: true },
    });
    const planMap = Object.fromEntries(plans.map(p => [p.id, p]));

    const plansActifsEnriched = plansActifs.map(pa => ({
      planId:  pa.planId,
      nom:     planMap[pa.planId]?.nom        || pa.planId,
      couleur: planMap[pa.planId]?.accentColor || '#8A8A9A',
      total:   pa._count.id,
    }));

    const fmt  = (d) => new Date(d).toISOString().slice(0, 7);
    const fmtW = (d) => new Date(d).toISOString().slice(0, 10);

    return res.json({
      inscriptionsParSemaine: inscriptionsParSemaine.map(r => ({
        semaine: fmtW(r.semaine), total: r.total,
      })),
      plansActifs: plansActifsEnriched,
      revenusParMois: revenusParMois.map(r => ({
        mois: fmt(r.mois), total: r.total, nb: r.nb,
      })),
      pubsParStatut: pubsParStatut.map(r => ({
        statut: r.statut, total: r._count.id,
      })),
      topVilles: topVilles.map(r => ({ ville: r.ville, total: r.total })),
      signalementsParMotif: signalementsParMotif.map(r => ({
        motif: r.motif, total: r.total,
      })),
      methodesPaiement: methodesParement.map(r => ({
        methode: r.methode, total: r.total,
      })),
      escortsStats: {
        total:    totalEscorts,
        verifies: escortsVerifies,
        bloques:  escortsBloques,
        bannis:   escortsBannis,
        normaux:  totalEscorts - escortsBloques - escortsBannis,
      },
      transactionsMois: transactionsMois.map(r => ({
        mois: fmt(r.mois), statut: r.statut, total: r.total,
      })),
      sanctionsParType: sanctionsParType.map(r => ({
        type: r.type, total: r._count.id,
      })),
      abonnementsStatut: abonnementsStatut.map(r => ({
        statut: r.statut, total: r._count.id,
      })),
      avisStats: {
        noteMoyenne: noteMoyenne._avg.note
          ? Math.round(noteMoyenne._avg.note * 10) / 10
          : 0,
        total: totalAvis,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════════
module.exports = {
  login,
  dashboard,
  listerEscorts,
  detailEscort,
  verifierEscort,
  sanctionner,
  debloquer,
  listerSignalements,
  traiterSignalement,
  listerPlans,
  creerPlan,
  modifierPlan,
  supprimerPlan,
  ajusterAbonnement,
  offrirCadeau,
  envoyerNotification,
  historiqueNotifications,
  listerTransactions,
  listerPublications,
  changerStatutPublication,
  analytics,
};