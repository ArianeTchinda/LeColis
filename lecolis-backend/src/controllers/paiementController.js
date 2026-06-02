// src/controllers/paiementController.js
const prisma = require('../config/prisma');
const {
  calculerComportement,
  expirerAbonnementActif,
  activerAbonnementEnAttente,
  niveauPlan,
  NIVEAUX,
} = require('./abonnementController');

const TARA_API_KEY     = process.env.TARA_API_KEY;
const TARA_BUSINESS_ID = 'WactdEfWtT';

const TARA_URL         = 'https://www.dklo.co/api/tara/paymentlinks';

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/paiement/creer-lien
// 🔐 Token escort requis — Body : { planId }
//
// Flux :
// 1. Nettoyer les ATTENTE_ACTIVATION orphelins (sans paiement confirmé)
// 2. Calculer dateDebut/dateFin via le helper partagé
// 3. Créer Transaction EN_ATTENTE + Abonnement ATTENTE_ACTIVATION en DB
// 4. Appeler TaraMoney et retourner les liens de paiement
// ═══════════════════════════════════════════════════════════════════════════════
async function creerLien(req, res, next) {
  try {
    const { planId } = req.body;
    const escortId   = req.escort.id;

    if (!planId) return res.status(400).json({ message: 'planId requis.' });

    if (!TARA_API_KEY) {
      console.error('[TaraMoney] TARA_API_KEY manquant dans .env');
      return res.status(500).json({ message: 'Configuration paiement incomplète.' });
    }

    

    const plan = await prisma.planAbonnement.findUnique({ where: { id: planId } });
    if (!plan || !plan.actif) {
      return res.status(404).json({ message: 'Plan introuvable ou inactif.' });
    }

    // ── Nettoyage des orphelins ──────────────────────────────────────────────
    // Annule les ATTENTE_ACTIVATION dont la transaction n'est PAS SUCCES.
    // Cela couvre : paiements abandonnés (EN_ATTENTE), erreurs TaraMoney (ECHEC).
    // Les cadeaux admin et plans gratuits en file d'attente ont une transaction SUCCES
    // → ils sont préservés.
    const orphelins = await prisma.abonnement.findMany({
      where:   { escortId, statut: 'ATTENTE_ACTIVATION' },
      include: { transaction: true },
    });

    for (const ab of orphelins) {
      const trConfirmee = ab.transaction?.statut === 'SUCCES';
      if (!trConfirmee) {
        await prisma.$transaction(async (tx) => {
          await tx.abonnement.update({
            where: { id: ab.id },
            data:  { statut: 'ANNULE' },
          });
          if (ab.transaction) {
            await tx.transaction.update({
              where: { id: ab.transaction.id },
              data:  { statut: 'ECHEC' },
            });
          }
        });
      }
    }

    // ── Abonnement actif en cours (après nettoyage) ──────────────────────────
    const abActif = await prisma.abonnement.findFirst({
      where:   { escortId, statut: 'ACTIF', dateFin: { gt: new Date() } },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    // ── Calcul du comportement ───────────────────────────────────────────────
    const { expirerActif, nouveauStatut, dateDebut, dateFin } =
      await calculerComportement(escortId, plan, abActif);

    // ── Création Transaction EN_ATTENTE + Abonnement ATTENTE_ACTIVATION ──────
    // L'abonnement est toujours créé en ATTENTE_ACTIVATION ici.
    // Il sera activé (ou expiré/remplacé) dans le webhook après confirmation TaraMoney.
    const { transaction, abonnement } = await prisma.$transaction(async (tx) => {
      const tr = await tx.transaction.create({
        data: {
          escortId,
          planNom:         plan.nom,
          montant:         plan.prix,
          methodePaiement: 'TaraMoney',
          statut:          'EN_ATTENTE',
        },
      });

      const ab = await tx.abonnement.create({
        data: {
          escortId,
          planId:        plan.id,
          dateDebut,
          dateFin,
          statut:        'ATTENTE_ACTIVATION',
          transactionId: tr.id,
        },
      });

      await tx.transaction.update({
        where: { id: tr.id },
        data:  { abonnement: { connect: { id: ab.id } } },
      });

      return { transaction: tr, abonnement: ab };
    });

    // ── Appel TaraMoney ──────────────────────────────────────────────────────
    const webhookUrl = `${process.env.APP_URL}/api/paiement/webhook`;
    const returnUrl  = process.env.FRONTEND_URL
      ? `${process.env.FRONTEND_URL}/paiement-retour?transactionId=${transaction.id}`
      : `${process.env.APP_URL}/api/paiement/retour?transactionId=${transaction.id}`;

    const taraBody = {
      apiKey:             TARA_API_KEY,
      businessId:         TARA_BUSINESS_ID,
      productId:          transaction.id, 
      productName:        `Abonnement ${plan.nom}`,
      productPrice:       plan.prix,
      productDescription: plan.description || `Plan ${plan.nom} — ${plan.dureeJours} jours`,
      returnUrl,
      webHookUrl:         webhookUrl,
    };
    if (process.env.APP_LOGO_URL) taraBody.productPictureUrl = process.env.APP_LOGO_URL;

    console.log('[TaraMoney] Envoi requête creer-lien:', JSON.stringify(taraBody));

    console.log('[DEBUG] TARA_API_KEY:', TARA_API_KEY ? 'présent' : 'ABSENT');
  
    console.log('[DEBUG] TARA_BUSINESS_ID:', TARA_BUSINESS_ID);
    console.log('[DEBUG] taraBody complet:', JSON.stringify(taraBody));

    const taraRes = await fetch(TARA_URL, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(taraBody),
    });

    if (!taraRes.ok) {
      const errBody = await taraRes.text();
      console.error('[TaraMoney] Erreur HTTP:', taraRes.status, errBody);
      // Rollback : annuler l'abonnement et la transaction créés
      await prisma.$transaction([
        prisma.abonnement.update({
          where: { id: abonnement.id },
          data:  { statut: 'ANNULE' },
        }),
        prisma.transaction.update({
          where: { id: transaction.id },
          data:  { statut: 'ECHEC' },
        }),
      ]);
      return res.status(502).json({ message: 'Erreur TaraMoney. Réessayez dans quelques instants.' });
    }

    const liens = await taraRes.json();
    console.log('[TaraMoney] Réponse creer-lien:', JSON.stringify(liens));

    // Sauvegarder le generalLink pour le matching dans le webhook
    await prisma.transaction.update({
      where: { id: transaction.id },
      data:  { taraRef: transaction.id },   // TaraMoney nous renvoie ce même ID dans paymentId
    });

    return res.json({
      transactionId: transaction.id,
      abonnementId:  abonnement.id,
      expirerActif,                       // Info pour l'UI (l'actuel sera remplacé)
      dateDebut:     dateDebut.toISOString(),
      dateFin:       dateFin.toISOString(),
      liens: {
        whatsappLink: liens.whatsappLink ?? null,
        telegramLink: liens.telegramLink ?? null,
        dikaloLink:   liens.dikaloLink   ?? null,
        generalLink:  liens.generalLink  ?? liens.paymentLink ?? null,
        cardLink:     liens.cardLink     ?? null,
        smsLink:      liens.smsLink      ?? null,
      },
    });
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/paiement/webhook
// Appelé par TaraMoney — sans authentification escort
//
// Flux après confirmation de paiement :
// 1. Retrouver la transaction EN_ATTENTE via generalLink ou transactionId
// 2. Retrouver l'abonnement ATTENTE_ACTIVATION lié
// 3. Appliquer la logique plan sup/inf/égal vis-à-vis de l'abonnement actif
// 4. Marquer la transaction SUCCES
// 5. Envoyer une notification adaptée
// ═══════════════════════════════════════════════════════════════════════════════
async function webhook(req, res, next) {
  try {
    console.log('[Webhook TaraMoney] Body reçu:', JSON.stringify(req.body));

    const body   = req.body;

    console.log('[Webhook DEBUG] Headers:', JSON.stringify(req.headers));
    console.log('[Webhook DEBUG] Body complet:', JSON.stringify(req.body));
    console.log('[Webhook DEBUG] Body type:', typeof req.body);


    const statut = (body.status || body.statut || '').toLowerCase();

    // Ignorer tout ce qui n'est pas un succès
    if (!['success', 'succes', 'paid', 'completed', 'confirmed', '1', 'true'].includes(statut)) {
      console.log('[Webhook] Statut non-succès reçu:', statut, '→ ignoré');
      return res.json({ received: true });
    }

    const generalLink = body.generalLink   || body.paymentLink || null;
    const taraTransId = body.transactionId || body.orderId || body.paymentId || null;
    const collectionId = body.collectionId || null;  // identifiant unique TaraMoney

    console.log('[Webhook] Champs disponibles:', Object.keys(body));
    console.log('[Webhook] generalLink:', generalLink, '| taraTransId:', taraTransId);
    console.log('[Webhook] taraRef cherché dans DB:', generalLink);


    if (!generalLink && !taraTransId && !collectionId) {
      console.warn('[Webhook] Aucun identifiant reçu dans le body → ignoré');
      return res.json({ received: true });
    }

    // ── Retrouver la transaction EN_ATTENTE ──────────────────────────────────
    const orClause = [
      ...(generalLink ? [{ taraRef: generalLink }] : []),
      ...(taraTransId ? [{ id: taraTransId }]      : []),
      ...(collectionId ? [{ taraRef: collectionId }]  : []), 
    ];

    const transaction = await prisma.transaction.findFirst({
      where: { OR: orClause, statut: 'EN_ATTENTE' },
    });

    if (!transaction) {
      console.warn('[Webhook] Aucune transaction EN_ATTENTE trouvée.',
        '| generalLink:', generalLink, '| taraTransId:', taraTransId);
      return res.json({ received: true });
    }

    // ── Retrouver l'abonnement ATTENTE_ACTIVATION lié ───────────────────────
    const abAttente = await prisma.abonnement.findFirst({
      where: { transactionId: transaction.id, statut: 'ATTENTE_ACTIVATION' },
    });

    if (!abAttente) {
      console.warn('[Webhook] Abonnement ATTENTE_ACTIVATION introuvable pour transaction:', transaction.id);
      // Marquer quand même la transaction SUCCES pour éviter une boucle de retry
      await prisma.transaction.update({
        where: { id: transaction.id },
        data:  { statut: 'SUCCES' },
      });
      return res.json({ received: true });
    }

    // ── Traitement dans une transaction atomique ──────────────────────────────
    await prisma.$transaction(async (tx) => {
      // Charger l'abonnement actif en cours (différent de celui en attente)
      const abActifEnCours = await tx.abonnement.findFirst({
        where: {
          escortId: transaction.escortId,
          statut:   'ACTIF',
          dateFin:  { gt: new Date() },
          id:       { not: abAttente.id },
        },
        include: { plan: { select: { id: true, nom: true, ordre: true } } },
        orderBy: { createdAt: 'desc' },
      });

      // Charger le plan du nouvel abonnement (avec ordre pour les plans custom)
      const planNouv = await tx.planAbonnement.findUnique({
        where:  { id: abAttente.planId },
        select: { id: true, nom: true, ordre: true },
      });

      // Déterminer si l'abonnement doit être activé immédiatement ou rester en attente
      let activerImmediatement = false;

      if (!abActifEnCours) {
        // Pas d'abonnement actif → activer si dateDebut est atteinte
        const debutPasse = new Date(abAttente.dateDebut) <= new Date();
        activerImmediatement = debutPasse;

        if (!debutPasse) {
          console.log('[Webhook] Abonnement sans actif mais dateDebut future → reste ATTENTE_ACTIVATION');
        }
      } else if (planNouv) {
        // Il y a un abonnement actif → comparer les niveaux
        const nActif   = niveauPlan(abActifEnCours.plan);
        const nNouveau = niveauPlan(planNouv);

        if (nNouveau >= nActif) {
          // Plan supérieur ou égal → expirer l'actif, activer immédiatement
          console.log(`[Webhook] Plan ${planNouv.nom} (niv.${nNouveau}) ≥ actif ${abActifEnCours.plan.nom} (niv.${nActif}) → activation immédiate`);
          await expirerAbonnementActif(tx, transaction.escortId, abActifEnCours.id);
          activerImmediatement = true;
        } else {
          // Plan inférieur → paiement confirmé mais démarrage différé
          console.log(`[Webhook] Plan ${planNouv.nom} (niv.${nNouveau}) < actif ${abActifEnCours.plan.nom} (niv.${nActif}) → démarrage différé le ${new Date(abAttente.dateDebut).toLocaleDateString('fr-FR')}`);
          activerImmediatement = false;
        }
      }

      // Activer si nécessaire
      if (activerImmediatement) {
        await activerAbonnementEnAttente(tx, transaction.escortId, abAttente);
      }

      // Toujours marquer la transaction SUCCES
      await tx.transaction.update({
        where: { id: transaction.id },
        data:  { statut: 'SUCCES' },
      });

      // ── Notification adaptée ─────────────────────────────────────────────
      const dateFin      = new Date(abAttente.dateFin).toLocaleDateString('fr-FR');
      const dateDebutStr = new Date(abAttente.dateDebut).toLocaleDateString('fr-FR');
      const planNom      = planNouv?.nom ?? transaction.planNom;

      await tx.notification.create({
        data: {
          escortId: transaction.escortId,
          type:     'ABONNEMENT',
          titre:    `Plan ${planNom} — paiement confirmé ✅`,
          message:  activerImmediatement
            ? `Votre abonnement ${planNom} est actif jusqu'au ${dateFin}.`
            : `Paiement reçu ✓. Votre plan ${planNom} démarrera le ${dateDebutStr} et expirera le ${dateFin}.`,
        },
      });
    });

    console.log('[Webhook] Transaction', transaction.id, 'traitée avec succès.');
    return res.json({ received: true });
  } catch (err) {
    console.error('[Webhook] Erreur non gérée:', err);
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /api/paiement/retour — page de retour post-paiement (fallback sans FRONTEND_URL)
// ═══════════════════════════════════════════════════════════════════════════════
async function retour(req, res, next) {
  try {
    const { transactionId } = req.query;
    console.log('[Retour TaraMoney] transactionId:', transactionId);
    return res.send(`
      <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
        </head>
        <body style="font-family:sans-serif;text-align:center;padding:40px;
                     background:#0a0a0f;color:#f0f0ff">
          <h2 style="color:#9B5FFF">Paiement en cours de vérification…</h2>
          <p style="color:#9090b0">Retournez dans l'application LeColis pour voir votre abonnement.</p>
          <p style="color:#555570;font-size:12px">Référence : ${transactionId ?? '—'}</p>
        </body>
      </html>
    `);
  } catch (err) {
    next(err);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /api/paiement/statut/:transactionId
// 🔐 Token escort requis — Utilisé par Flutter pour poller le statut (toutes les 5s)
// ═══════════════════════════════════════════════════════════════════════════════
async function statutPaiement(req, res, next) {
  try {
    const { transactionId } = req.params;

    const transaction = await prisma.transaction.findFirst({
      where: { id: transactionId, escortId: req.escort.id },
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Transaction introuvable.' });
    }

    const abonnement = await prisma.abonnement.findFirst({
      where:   { transactionId: transaction.id },
      include: { plan: { select: { nom: true, nbPublications: true, dureeJours: true } } },
    });

    return res.json({
      statut:           transaction.statut,          // EN_ATTENTE | SUCCES | ECHEC
      planNom:          transaction.planNom,
      abonnementStatut: abonnement?.statut ?? null,  // ACTIF | ATTENTE_ACTIVATION | ANNULE | EXPIRE
      dateDebut:        abonnement?.dateDebut ?? null,
      dateFin:          abonnement?.dateFin   ?? null,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { creerLien, webhook, retour, statutPaiement };