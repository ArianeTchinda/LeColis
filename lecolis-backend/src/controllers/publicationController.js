// src/controllers/publicationController.js
const prisma = require('../config/prisma');
const { uploadImagePublication, supprimerImagePublication } = require('../services/imageService');

// ── Helpers ────────────────────────────────────────────────

// Formate une publication pour la réponse publique (liste/détail)
function formatPublication(pub) {
  return {
    id:           pub.id,
    titre:        pub.titre,
    description:  pub.description,
    estDisponible: pub.estDisponible,
    tarif:        pub.tarif,
    statut:       pub.statut,
    vues:         pub.vues,
    dateExpiration: pub.dateExpiration,
    planType:     pub.planType,
    villeNom:     pub.villeNom,
    regionNom:    pub.regionNom,
    paysNom:      pub.paysNom,
    quartier:     pub.quartier ? { id: pub.quartier.id, nom: pub.quartier.nom,
                    ville: pub.quartier.ville?.nom } : null,
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
      whatsapp:   pub.escort.telephone, // même numéro côté escort
      email:      pub.escort.email,
      estVerifie: pub.escort.estVerifie,
    } : undefined,
    avis:     pub.avis || [],
    createdAt: pub.createdAt,
  };
}

const INCLUDE_FULL = {
  escort:     { select: { id: true, pseudo: true, photoUrl: true, telephone: true,
                           email: true, estVerifie: true } },
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

// ── GET /profil/publications (mes publications) ───────────
async function mesPubs(req, res, next) {
  try {
    const publications = await prisma.publication.findMany({
      where:   { escortId: req.escort.id },
      include: { images: { orderBy: { ordre: 'asc' } }, categories: { include: { categorie: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(publications.map(formatPublication));
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

    return res.status(201).json(formatPublication(pub));
  } catch (err) {
    next(err);
  }
}

// ── POST /profil/publications/:id/images ──────────────────
async function ajouterImages(req, res, next) {
  try {
    const pub = await prisma.publication.findFirst({
      where:   { id: req.params.id, escortId: req.escort.id },
      include: { images: true },
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    if (!req.files?.length) {
      return res.status(400).json({ message: 'Aucune image fournie.' });
    }

    const startOrdre = pub.images.length;

    // Upload chaque image vers MinIO
    const uploaded = await Promise.all(
      req.files.map(async (file, i) => {
        const { url, key } = await uploadImagePublication(file.buffer, pub.id, startOrdre + i);
        return { url, key, ordre: startOrdre + i };
      })
    );

    // Enregistrer en base
    await prisma.publicationImage.createMany({
      data: uploaded.map(({ url, key, ordre }) => ({
        publicationId: pub.id,
        url,
        key,
        ordre,
      })),
    });

    // Passer en ACTIVE si c'était un brouillon et qu'on a maintenant des images
    if (pub.statut === 'BROUILLON') {
      await prisma.publication.update({
        where: { id: pub.id },
        data:  { statut: 'ACTIVE' },
      });
    }

    const updated = await prisma.publication.findUnique({
      where:   { id: pub.id },
      include: INCLUDE_FULL,
    });

    return res.json(formatPublication(updated));
  } catch (err) {
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
    });
    if (!pub) return res.status(404).json({ message: 'Publication introuvable.' });

    const { titre, description, estDisponible, tarif, quartierId,
            villeNom, regionNom, paysNom, categorieIds } = req.body;

    const updated = await prisma.$transaction(async (tx) => {
      // Mise à jour des catégories si fournie
      if (categorieIds) {
        await tx.publicationCategorie.deleteMany({ where: { publicationId: pub.id } });
        if (categorieIds.length) {
          await tx.publicationCategorie.createMany({
            data: categorieIds.map((id) => ({ publicationId: pub.id, categorieId: id })),
          });
        }
      }

      return tx.publication.update({
        where: { id: pub.id },
        data: {
          ...(titre        !== undefined && { titre }),
          ...(description  !== undefined && { description }),
          ...(estDisponible!== undefined && { estDisponible: estDisponible === true || estDisponible === 'true' }),
          ...(tarif        !== undefined && { tarif: tarif ? parseFloat(tarif) : null }),
          ...(quartierId   !== undefined && { quartierId }),
          ...(villeNom     !== undefined && { villeNom }),
          ...(regionNom    !== undefined && { regionNom }),
          ...(paysNom      !== undefined && { paysNom }),
        },
        include: INCLUDE_FULL,
      });
    });

    return res.json(formatPublication(updated));
  } catch (err) {
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

module.exports = {
  lister, detail, mesPubs, creer, modifier, supprimer,
  ajouterImages, supprimerImage, ajouterAvis, signaler,
};
