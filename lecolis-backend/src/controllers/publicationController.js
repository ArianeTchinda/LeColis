// src/controllers/publicationController.js
const prisma = require('../config/prisma');

// ── Helper notification ───────────────────────────────────
// Crée une notification pour l'escort de manière non-bloquante.
// On ne throw pas en cas d'échec — la notif est un bonus, pas critique.
async function _notifier(escortId, type, titre, message) {
  try {
    await prisma.notification.create({ data: { escortId, type, titre, message } });
  } catch (e) {
    console.error('[notifier]', e.message);
  }
}
const { uploadImagePublication, supprimerImagePublication } = require('../services/imageService');

// ── Helpers ────────────────────────────────────────────────

// Formate une publication pour la réponse publique (liste/détail)
function formatPublication(pub) {
  // Récupérer l'abonnement actif le plus récent
  const abonnementActif = pub.escort?.abonnements?.[0];

  // Déterminer le nom du plan
  let planNom = 'Basique';
  if (abonnementActif?.plan?.nom) {
    planNom = abonnementActif.plan.nom;
  } else if (pub.planType) {
    planNom = pub.planType.charAt(0).toUpperCase() + pub.planType.slice(1);
  }

  const planTypeLower = planNom.toLowerCase();

  // Couleur du plan
  const defaultColors = { 
    premium: '#FFD700', 
    standard: '#FF5DA8', 
    basique: '#8A8A9A' 
  };
  
  const accentColor = abonnementActif?.plan?.accentColor 
    || defaultColors[planTypeLower] 
    || '#8A8A9A';

  return {
    id:           pub.id,
    titre:        pub.titre,
    description:  pub.description,
    estDisponible: pub.estDisponible,
    tarif:        pub.tarif,
    statut:       pub.statut,
    vues:         pub.vues,
    dateExpiration: pub.dateExpiration,
    
    // ── PLAN INFO ──
    planType:     planTypeLower,        // "premium", "standard", "basique"
    planNom:      planNom,              // "Premium", "Standard", "Basique"
    accentColor,                        // Couleur réelle

    villeNom:     pub.villeNom,
    regionNom:    pub.regionNom,
    paysNom:      pub.paysNom,
    
    quartier:     pub.quartier ? { 
      id: pub.quartier.id, 
      nom: pub.quartier.nom 
    } : null,

    images:       (pub.images || [])
                    .sort((a, b) => a.ordre - b.ordre)
                    .map(img => ({ id: img.id, url: img.url, ordre: img.ordre })),

    categories:   (pub.categories || []).map(pc => ({
      id:  pc.categorie.id,
      nom: pc.categorie.nom,
    })),

    escort: pub.escort ? {
      id:         pub.escort.id,
      pseudo:     pub.escort.pseudo,
      photoUrl:   pub.escort.photoUrl,
      telephone:  pub.escort.telephone,
      whatsapp:   pub.escort.telephone,
      email:      pub.escort.email,
      estVerifie: pub.escort.estVerifie,
    } : undefined,

    avis:         pub.avis || [],
    nbAvis:       pub.nbAvis ?? 0,
    noteMoyenne:  pub.noteMoyenne ?? 0.0,
    createdAt:    pub.createdAt,
  };
}

const INCLUDE_FULL = {
  escort: {
    include: {
      abonnements: {
        where:   { statut: 'ACTIF', dateFin: { gt: new Date() } },
        include: { 
          plan: { 
            select: { nom: true, accentColor: true } 
          } 
        },
        orderBy: { createdAt: 'desc' },
        take: 1,
      },
    },
  },
  images:     { orderBy: { ordre: 'asc' } },
  categories: { include: { categorie: true } },
  quartier:   { include: { ville: { include: { region: true } } } },
  avis:       { orderBy: { createdAt: 'desc' }, take: 20 },
};

// ── GET /publications (liste publique filtrée) ────────────
async function lister(req, res, next) {
  try {
    const {
      categorie,   // ID ou nom
      ville,       // nom de ville
      region,      // nom de région
      pays,        // nom de pays
      quartier,    // ID quartier
      planType,    // "premium" | "standard" | "basique"
      disponible,  // "true" | "false"
      tarifMin, tarifMax,
      page = '1',
      limite = '20',
    } = req.query;

    const skip  = (parseInt(page) - 1) * parseInt(limite);
    const take  = Math.min(parseInt(limite), 50);

    const where = {
      statut:         'ACTIVE',
      dateExpiration: { gt: new Date() },
      ...(planType    && { planType }),
      ...(ville       && { villeNom: ville }),
      ...(region      && { regionNom: region }),
      ...(pays        && { paysNom: pays }),
      ...(quartier    && { quartierId: quartier }),
      ...(disponible  && { estDisponible: disponible === 'true' }),
      ...(tarifMin    && { tarif: { gte: parseFloat(tarifMin) } }),
      ...(tarifMax    && { tarif: { lte: parseFloat(tarifMax) } }),
      ...(categorie   && {
        categories: { some: { categorie: { nom: { contains: categorie, mode: 'insensitive' } } } },
      }),
    };

    const [total, publications] = await Promise.all([
      prisma.publication.count({ where }),
      prisma.publication.findMany({
        where,
        include: INCLUDE_FULL,
        orderBy: [
          // Priorité par plan (premium > standard > basique)
          { planType: 'asc' },
          { createdAt: 'desc' },
        ],
        skip,
        take,
      }),
    ]);

    // Tri personnalisé : premium d'abord
    const ordre = { premium: 3, standard: 2, basique: 1 };
    const sorted = publications.sort(
      (a, b) => (ordre[b.planType] || 0) - (ordre[a.planType] || 0)
    );

    return res.json({
      data:    sorted.map(formatPublication),
      total,
      page:    parseInt(page),
      limite:  take,
      pages:   Math.ceil(total / take),
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /publications/:id (détail public) ─────────────────
async function detail(req, res, next) {
  try {
    const pub = await prisma.publication.findUnique({
      where:   { id: req.params.id },
      include: INCLUDE_FULL,
    });

    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    // Incrémenter les vues
    await prisma.publication.update({
      where: { id: pub.id },
      data:  { vues: { increment: 1 } },
    });

    return res.json(formatPublication({ ...pub, vues: pub.vues + 1 }));
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/publications/:id (une pub de l'escort) ───
async function getOne(req, res, next) {
  try {
    const pub = await prisma.publication.findFirst({
      where: {
        id:       req.params.id,
        escortId: req.escort.id,  // sécurité : l'escort ne peut voir que ses propres pubs
      },
      include: {
        images:     { orderBy: { ordre: 'asc' } },
        categories: { include: { categorie: true } },
        quartier:   { include: { ville: { include: { region: { include: { pays: true } } } } } },
        escort:     { select: { id: true, pseudo: true, photoUrl: true,
                                telephone: true, email: true, estVerifie: true } },
        avis:       { orderBy: { createdAt: 'desc' }, take: 20 },
      },
    });

    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    // Enrichir avec les noms de localisation depuis la relation
    const enriched = {
      ...pub,
      villeNom:   pub.quartier?.ville?.nom    ?? pub.villeNom   ?? '',
      regionNom:  pub.quartier?.ville?.region?.nom ?? pub.regionNom ?? '',
      paysNom:    pub.quartier?.ville?.region?.pays?.nom ?? pub.paysNom ?? 'Cameroun',
    };

    return res.json(formatPublication(enriched));
  } catch (err) {
    next(err);
  }
}
async function mesPubs(req, res, next) {
  try {
    const publications = await prisma.publication.findMany({
      where:   { escortId: req.escort.id },
      include: { 
        images: { orderBy: { ordre: 'asc' } }, 
        categories: { include: { categorie: true } },
        avis: { select: { note: true } } // On charge les notes pour le calcul
      },
      orderBy: { createdAt: 'desc' },
    });

    const dataFormatee = publications.map(pub => {
      // 1. Calcul des statistiques locales
      const countAvis = pub.avis ? pub.avis.length : 0;
      const sommeNotes = countAvis > 0 ? pub.avis.reduce((sum, a) => sum + a.note, 0) : 0;
      const moyenne = countAvis > 0 ? parseFloat((sommeNotes / countAvis).toFixed(2)) : 0.0;

      // 2. On injecte temporairement dans l'objet pour formatPublication
      pub.nbAvis = countAvis;
      pub.noteMoyenne = moyenne;

      // 3. On formate proprement pour le rendu JSON final
      return formatPublication(pub);
    });

    return res.json(dataFormatee);
  } catch (err) {
    next(err);
  }
}

// ── POST /profil/publications ─────────────────────────────
async function creer(req, res, next) {
  try {
    const {
      titre, description, estDisponible, tarif,
      quartierId, villeNom, regionNom, paysNom,
      categorieIds, // tableau d'IDs
    } = req.body;

    // Vérifier l'abonnement actif et le quota de publications
    const abonnement = await prisma.abonnement.findFirst({
      where: {
        escortId: req.escort.id,
        statut:   'ACTIF',
        dateFin:  { gt: new Date() },
      },
      include: { plan: true },
    });

    if (!abonnement) {
      return res.status(403).json({
        message: 'Aucun abonnement actif. Souscrivez un plan pour publier.',
      });
    }

    const quota = abonnement.nbPublicationsAdm ?? abonnement.plan.nbPublications;

    // Compter les pubs actives de l'escort
    const pubsActives = await prisma.publication.count({
      where: { escortId: req.escort.id, statut: 'ACTIVE', dateExpiration: { gt: new Date() } },
    });

    if (pubsActives >= quota) {
      return res.status(403).json({
        message: `Quota atteint (${quota} publication${quota > 1 ? 's' : ''} max avec votre plan).`,
      });
    }

    // Déterminer le planType à partir du plan
    const planNom = abonnement.plan.nom.toLowerCase();
    const planType = ['premium', 'standard', 'basique'].includes(planNom) ? planNom : 'basique';

    // Date d'expiration = fin de l'abonnement
    const dateExpiration = abonnement.dateFin;

    // Créer la publication (sans images pour l'instant)
    const pub = await prisma.publication.create({
      data: {
        escortId: req.escort.id,
        titre,
        description,
        estDisponible: estDisponible === true || estDisponible === 'true',
        tarif:   tarif ? parseFloat(tarif) : null,
        statut:  'BROUILLON',
        planType,
        dateExpiration,
        quartierId: quartierId || null,
        villeNom:   villeNom  || '',
        regionNom:  regionNom || '',
        paysNom:    paysNom   || 'Cameroun',
        ...(categorieIds?.length && {
          categories: {
            create: categorieIds.map((id) => ({ categorieId: id })),
          },
        }),
      },
      include: INCLUDE_FULL,
    });

    // Notification création
    await _notifier(
      req.escort.id, 'PUBLICATION',
      'Publication créée ✓',
      `Votre publication "${pub.titre}" a été créée et est maintenant visible.`
    );

    return res.status(201).json(formatPublication(pub));
  } catch (err) {
    next(err);
  }
}

// ── POST /profil/publications/:id/images ──────────────────
async function ajouterImages(req, res, next) {
  try {
    console.log(`[ajouterImages] Start - pubId=${req.params.id}, escort=${req.escort.id}, files count=${req.files?.length || 0}`);

    const pub = await prisma.publication.findFirst({
      where:   { id: req.params.id, escortId: req.escort.id },
      include: { images: true },
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    if (!req.files?.length) {
      console.warn(`[ajouterImages] No files received for pub ${req.params.id}`);
      return res.status(400).json({ message: 'Aucune image fournie.' });
    }

    const startOrdre = pub.images.length;
    console.log(`[ajouterImages] Starting upload - ${req.files.length} files, startOrdre=${startOrdre}`);

    // Upload chaque image vers MinIO
    const uploaded = await Promise.all(
      req.files.map(async (file, i) => {
        console.log(`[ajouterImages] Uploading file ${i}: ${file.originalname} (${file.size} bytes)`);
        const { url, key } = await uploadImagePublication(file.buffer, pub.id, startOrdre + i);
        console.log(`[ajouterImages] File ${i} uploaded - key=${key}, url=${url}`);
        return { url, key, ordre: startOrdre + i };
      })
    );

    console.log(`[ajouterImages] All files uploaded to MinIO, now saving to DB`);

    // Enregistrer en base
    await prisma.publicationImage.createMany({
      data: uploaded.map(({ url, key, ordre }) => ({
        publicationId: pub.id,
        url,
        key,
        ordre,
      })),
    });

    console.log(`[ajouterImages] ${uploaded.length} images saved to DB`);

    // Passer en ACTIVE si c'était un brouillon et qu'on a maintenant des images
    if (pub.statut === 'BROUILLON') {
      console.log(`[ajouterImages] Changing publication status from BROUILLON to ACTIVE`);
      await prisma.publication.update({
        where: { id: pub.id },
        data:  { statut: 'ACTIVE' },
      });
    }

    const updated = await prisma.publication.findUnique({
      where:   { id: pub.id },
      include: INCLUDE_FULL,
    });

    console.log(`[ajouterImages] Success - returning publication with ${updated.images.length} images`);

    // Notification ajout images
    await _notifier(
      req.escort.id, 'PUBLICATION',
      'Images ajoutées à votre publication',
      `${uploaded.length} image(s) ajoutée(s) à "${updated.titre}".`
    );

    return res.json(formatPublication(updated));
  } catch (err) {
    console.error(`[ajouterImages] Error:`, err);
    next(err);
  }
}

// ── DELETE /profil/publications/:id/images/:imageId ───────
async function supprimerImage(req, res, next) {
  try {
    const img = await prisma.publicationImage.findFirst({
      where: {
        id:           req.params.imageId,
        publicationId: req.params.id,
        publication:  { escortId: req.escort.id },
      },
    });
    if (!img) return res.status(404).json({ message: 'Image introuvable.' });

    await supprimerImagePublication(img.key);
    await prisma.publicationImage.delete({ where: { id: img.id } });

    // Notification suppression image
    const pubData = await prisma.publication.findUnique({
      where: { id: req.params.id }, select: { titre: true, escortId: true }
    });
    if (pubData) {
      await _notifier(
        pubData.escortId, 'PUBLICATION',
        'Image supprimée',
        `Une image a été retirée de votre publication "${pubData.titre}".`
      );
    }

    return res.json({ message: 'Image supprimée.' });
  } catch (err) {
    next(err);
  }
}

// ── PUT /profil/publications/:id ──────────────────────────
async function modifier(req, res, next) {
  try {
    const pub = await prisma.publication.findFirst({
      where: { id: req.params.id, escortId: req.escort.id },
      include: { images: true }   // Important pour pouvoir supprimer
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    const { titre, description, estDisponible, statut, tarif, quartierId,
            villeNom, regionNom, paysNom, categorieIds, imagesToDelete } = req.body;

    const updated = await prisma.$transaction(async (tx) => {
      // ==================== SUPPRESSION DES IMAGES ====================
      if (imagesToDelete && Array.isArray(imagesToDelete) && imagesToDelete.length > 0) {
        console.log(`[modifier] Suppression de ${imagesToDelete.length} images...`);

        // Récupérer les images à supprimer
        const imagesASupprimer = await tx.publicationImage.findMany({
          where: {
            id: { in: imagesToDelete },
            publicationId: pub.id
          }
        });

        // Supprimer physiquement dans MinIO
        for (const img of imagesASupprimer) {
          try {
            await supprimerImagePublication(img.key);
            console.log(`[modifier] Image supprimée MinIO → key: ${img.key}`);
          } catch (err) {
            console.error(`[modifier] Erreur suppression MinIO:`, err);
          }
        }

        // Supprimer les enregistrements en base
        await tx.publicationImage.deleteMany({
          where: { id: { in: imagesToDelete }, publicationId: pub.id }
        });
      }

      // ==================== MISE À JOUR CATÉGORIES ====================
      if (categorieIds && Array.isArray(categorieIds)) {
        await tx.publicationCategorie.deleteMany({ 
          where: { publicationId: pub.id } 
        });

        if (categorieIds.length > 0) {
          const validCategories = await tx.categorie.findMany({
            where: { id: { in: categorieIds } },
            select: { id: true }
          });

          const validIds = validCategories.map(c => c.id);

          if (validIds.length > 0) {
            await tx.publicationCategorie.createMany({
              data: validIds.map(id => ({
                publicationId: pub.id,
                categorieId: id,
              })),
            });
          }
        }
      }

      // ==================== MISE À JOUR PUBLICATION ====================

      // Vérification quota si on active une publication
      if (statut === 'ACTIVE') {
        const ab = await tx.abonnement.findFirst({
          where: { escortId: req.escort.id, statut: 'ACTIF', dateFin: { gt: new Date() } },
          include: { plan: true },
        });
        if (!ab) throw { status: 403, message: 'Aucun abonnement actif.' };

        const quota   = ab.nbPublicationsAdm ?? ab.plan.nbPublications;
        const actives = await tx.publication.count({
          where: {
            escortId: req.escort.id,
            statut:   'ACTIVE',
            id:       { not: pub.id },   // exclure la pub courante
          },
        });
        if (actives >= quota) {
          throw {
            status:  409,
            message: `Quota atteint : votre plan autorise ${quota} publication(s) active(s).`,
          };
        }
      }

      return tx.publication.update({
        where: { id: pub.id },
        data: {
          ...(titre        !== undefined && { titre }),
          ...(description  !== undefined && { description }),
          ...(estDisponible !== undefined && { estDisponible: estDisponible === true || estDisponible === 'true',}),
          ...(statut !== undefined && { statut }),
          ...(tarif        !== undefined && { tarif: tarif ? parseFloat(tarif) : null }),
          ...(quartierId   !== undefined && { quartierId }),
          ...(villeNom     !== undefined && { villeNom }),
          ...(regionNom    !== undefined && { regionNom }),
          ...(paysNom      !== undefined && { paysNom }),
        },
        include: INCLUDE_FULL,
      });
    });

    // Notification modification
    const parties = [];
    if (statut !== undefined) {
      parties.push(statut === 'ACTIVE' ? 'activée' : 'mise en brouillon');
    }
    if (estDisponible !== undefined) {
      parties.push(estDisponible === true || estDisponible === 'true'
        ? 'marquée disponible' : 'marquée indisponible');
    }
    if (titre !== undefined)       parties.push('titre mis à jour');
    if (description !== undefined) parties.push('description mise à jour');
    if (categorieIds !== undefined) parties.push('catégories mises à jour');
    if (imagesToDelete && imagesToDelete.length > 0)
      parties.push(`${imagesToDelete.length} image(s) supprimée(s)`);

    if (parties.length > 0) {
      await _notifier(
        req.escort.id, 'PUBLICATION',
        'Publication mise à jour',
        `Votre publication "${updated.titre}" a été modifiée : ${parties.join(', ')}.`
      );
    }

    return res.json(formatPublication(updated));
  } catch (err) {
    console.error('[modifier] Erreur:', err);
    // Erreur métier avec status HTTP personnalisé (quota, abonnement…)
    if (err.status) return res.status(err.status).json({ message: err.message });
    next(err);
  }
}

// ── DELETE /profil/publications/:id ───────────────────────
async function supprimer(req, res, next) {
  try {
    const pub = await prisma.publication.findFirst({
      where:   { id: req.params.id, escortId: req.escort.id },
      include: { images: true },
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    // Supprimer toutes les images MinIO
    await Promise.all(pub.images.map((img) => supprimerImagePublication(img.key)));

    await prisma.publication.delete({ where: { id: pub.id } });

    // Notification suppression
    await _notifier(
      pub.escortId, 'PUBLICATION',
      'Publication supprimée',
      `Votre publication "${pub.titre}" a été supprimée.`
    );

    return res.json({ message: 'Publication supprimée.' });
  } catch (err) {
    next(err);
  }
}

// ── POST /publications/:id/avis ───────────────────────────
async function ajouterAvis(req, res, next) {
  try {
    const { note, message } = req.body;
    if (!note || note < 1 || note > 5) {
      return res.status(400).json({ message: 'Note entre 1 et 5 requise.' });
    }

    const pub = await prisma.publication.findUnique({ where: { id: req.params.id } });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    const avis = await prisma.avis.create({
      data: { publicationId: pub.id, note: parseInt(note), message },
    });

    return res.status(201).json(avis);
  } catch (err) {
    next(err);
  }
}

// ── POST /publications/:id/signaler ───────────────────────
async function signaler(req, res, next) {
  try {
    const { motif, description } = req.body;

    const pub = await prisma.publication.findUnique({
      where: { id: req.params.id },
      select: { escortId: true },
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    await prisma.signalement.create({
      data: {
        escortId:      pub.escortId,
        publicationId: req.params.id,
        motif,
        description,
      },
    });

    return res.status(201).json({ message: 'Signalement enregistré. Merci.' });
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/publications/:id (détail d'une seule publication de l'escort connectée) ──
async function getPublicationById(req, res, next) {
  try {
    const pub = await prisma.publication.findFirst({
      where: { 
        id: req.params.id,
        escortId: req.escort.id   // Sécurité : on vérifie que c'est bien sa publication
      },
      include: INCLUDE_FULL,
    });

    if (!pub) {
      return res.status(404).json({ message: 'Publication introuvable.' });
    }

    return res.json(formatPublication(pub));
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/publications/:id/stats ────────────────────
async function statsPublication(req, res, next) {
  try {
    const { id } = req.params;

    // 1. Récupérer la publication avec ses stats globales basiques
    const pub = await prisma.publication.findFirst({
      where: { id, escortId: req.escort.id },
      select: {
        id: true,
        vues: true,
        _count: {
          select: { avis: true }
        }
      }
    });
    

    if (!pub) {
      return res.status(404).json({ message: 'Publication introuvable.' });
    }

    // 2. Calculer la note moyenne globale de cette publication
    const agregatAvis = await prisma.avis.aggregate({
      where: { publicationId: id },
      _avg: { note: true }
    });
    const noteMoyenne = agregatAvis._avg.note ? parseFloat(agregatAvis._avg.note.toFixed(1)) : 0.0;

    // 3. Calculer l'évolution des avis (Périodes : 24h, 7j, 30j, 1an)
    const maintenant = new Date();
    const unJourAgo = new Date(maintenant.getTime() - 24 * 60 * 60 * 1000);
    const septJoursAgo = new Date(maintenant.getTime() - 7 * 24 * 60 * 60 * 1000);
    const trenteJoursAgo = new Date(maintenant.getTime() - 30 * 24 * 60 * 60 * 1000);
    const unAnAgo = new Date(maintenant.getTime() - 365 * 24 * 60 * 60 * 1000);

    const [avisJour, avisSemaine, avisMois, avisAnnee] = await prisma.$transaction([
      prisma.avis.count({ where: { publicationId: id, createdAt: { gte: unJourAgo } } }),
      prisma.avis.count({ where: { publicationId: id, createdAt: { gte: septJoursAgo } } }),
      prisma.avis.count({ where: { publicationId: id, createdAt: { gte: trenteJoursAgo } } }),
      prisma.avis.count({ where: { publicationId: id, createdAt: { gte: unAnAgo } } }),
    ]);

    // Retourner la nouvelle structure épurée axée sur les avis
    return res.json({
      vuesTotal: pub.vues,            // Corrigé (plus de faute de frappe)
      totalAvis: pub._count.avis,     // Aligné avec le front
      noteMoyenne: noteMoyenne,
      evolutionAvis: {
        parJour: avisJour,
        parSemaine: avisSemaine,
        parMois: avisMois,
        parAn: avisAnnee
      }
    });
  } catch (err) {
    next(err);
  }
}

// ── GET /profil/publications/:id/avis ─────────────────────
async function avisPublication(req, res, next) {
  try {
    // Sécurité : Vérifier l'accès à la publication avant de donner les avis
    const pub = await prisma.publication.findFirst({
      where: {
        id: req.params.id,
        escortId: req.escort.id,
      },
      select: { id: true }
    });

    if (!pub) {
      return res.status(404).json({ message: 'Publication introuvable.' });
    }

    // Récupérer tous les avis liés à cette publication spécifique
    const tousLesAvis = await prisma.avis.findMany({
      where: {
        publicationId: req.params.id,
      },
      orderBy: {
        createdAt: 'desc', // Du plus récent au plus ancien
      },
    });

    return res.json(tousLesAvis);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  lister, detail, mesPubs, getOne, creer, modifier, supprimer,
  ajouterImages, supprimerImage, ajouterAvis, signaler, getPublicationById, statsPublication, avisPublication
};