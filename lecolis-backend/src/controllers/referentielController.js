// src/controllers/referentielController.js
const prisma = require('../config/prisma');

// ── GET /localisation/pays ────────────────────────────────
async function getPays(req, res, next) {
  try {
    const pays = await prisma.pays.findMany({
      orderBy: { nom: 'asc' },
      include: { regions: { orderBy: { nom: 'asc' } } },
    });
    return res.json(pays);
  } catch (err) { next(err); }
}

// ── GET /localisation/regions?pays=:paysId ────────────────
async function getRegions(req, res, next) {
  try {
    const { paysId, paysNom } = req.query;
    const regions = await prisma.region.findMany({
      where: paysId   ? { paysId }
           : paysNom  ? { pays: { nom: paysNom } }
           : {},
      orderBy: { nom: 'asc' },
    });
    return res.json(regions);
  } catch (err) { next(err); }
}

// ── GET /localisation/villes?regionId=:id ─────────────────
async function getVilles(req, res, next) {
  try {
    const { regionId, regionNom } = req.query;
    const villes = await prisma.ville.findMany({
      where: regionId  ? { regionId }
           : regionNom ? { region: { nom: regionNom } }
           : {},
      orderBy: { nom: 'asc' },
    });
    return res.json(villes);
  } catch (err) { next(err); }
}

// ── GET /localisation/quartiers?villeId=:id ───────────────
async function getQuartiers(req, res, next) {
  try {
    const { villeId, villeNom } = req.query;
    const quartiers = await prisma.quartier.findMany({
      where: villeId  ? { villeId }
           : villeNom ? { ville: { nom: villeNom } }
           : {},
      orderBy: { nom: 'asc' },
    });
    return res.json(quartiers);
  } catch (err) { next(err); }
}

// ── GET /categories ───────────────────────────────────────
async function getCategories(req, res, next) {
  try {
    const groupes = await prisma.groupeCategorie.findMany({
      orderBy: { ordre: 'asc' },
      include: {
        categories: { orderBy: { nom: 'asc' } },
      },
    });
    return res.json(groupes);
  } catch (err) { next(err); }
}

// ── GET /categories/flat (liste plate pour le filtre) ─────
async function getCategoriesFlat(req, res, next) {
  try {
    const categories = await prisma.categorie.findMany({ orderBy: { nom: 'asc' } });
    return res.json(categories);
  } catch (err) { next(err); }
}

// ═══════════════════════════════════════════════════════════
// HELPERS INTERNES
// ═══════════════════════════════════════════════════════════

/**
 * Normalise un nom pour la comparaison anti-doublon :
 *   - trim des espaces
 *   - minuscules
 *   - suppression des accents (NFD + retrait des diacritiques)
 * Exemples : "Côte d'Ivoire" → "cote d'ivoire"
 *            "CAMEROUN"      → "cameroun"
 *            "Yaoùndé"       → "yaounde"
 */
function normaliser(str) {
  return str
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

/**
 * Cherche parmi une liste d'enregistrements Prisma si un nom
 * normalisé existe déjà. Retourne l'enregistrement trouvé ou null.
 */
function trouverDoublon(liste, nomCible) {
  const cible = normaliser(nomCible);
  return liste.find(item => normaliser(item.nom) === cible) ?? null;
}

// ═══════════════════════════════════════════════════════════
// UPSERT LOCALISATION
// Principe : "créer si absent, retourner si existant"
// La comparaison est insensible à la casse ET aux accents
// pour éviter les doublons ("cameroun" == "Cameroun" == "CAMEROUN")
// ═══════════════════════════════════════════════════════════

// ── POST /localisation/pays ───────────────────────────────
// Body : { nom, drapeau? }
// Retourne le pays existant ou le pays nouvellement créé
async function upsertPays(req, res, next) {
  try {
    const { nom, drapeau = '🌍' } = req.body;

    if (!nom || !nom.trim()) {
      return res.status(400).json({ message: 'Le nom du pays est requis.' });
    }

    // Charger tous les pays pour comparer avec normalisation
    const tousPays = await prisma.pays.findMany({ select: { id: true, nom: true } });
    const doublon  = trouverDoublon(tousPays, nom);

    if (doublon) {
      // Retourner l'existant tel quel (pas d'erreur, transparent côté Flutter)
      const paysExistant = await prisma.pays.findUnique({
        where:   { id: doublon.id },
        include: { regions: { orderBy: { nom: 'asc' } } },
      });
      return res.status(200).json({ nouveau: false, pays: paysExistant });
    }

    // Créer le nouveau pays avec le nom tel que saisi (casse conservée)
    const nomPropre = nom.trim();
    const nouveau   = await prisma.pays.create({
      data:    { nom: nomPropre, drapeau },
      include: { regions: { orderBy: { nom: 'asc' } } },
    });
    return res.status(201).json({ nouveau: true, pays: nouveau });

  } catch (err) { next(err); }
}

// ── POST /localisation/regions ────────────────────────────
// Body : { nom, paysNom }
// Retourne la région existante ou la région nouvellement créée
async function upsertRegion(req, res, next) {
  try {
    const { nom, paysNom } = req.body;

    if (!nom || !nom.trim())      return res.status(400).json({ message: 'Le nom de la région est requis.' });
    if (!paysNom || !paysNom.trim()) return res.status(400).json({ message: 'Le nom du pays est requis.' });

    // 1. Résoudre le pays (insensible casse+accents)
    const tousPays   = await prisma.pays.findMany({ select: { id: true, nom: true } });
    const paysRecord = trouverDoublon(tousPays, paysNom);

    if (!paysRecord) {
      return res.status(404).json({
        message: `Pays "${paysNom}" introuvable. Créez-le d'abord via POST /localisation/pays.`,
      });
    }

    // 2. Charger les régions du pays et chercher un doublon
    const toutesRegions = await prisma.region.findMany({
      where:  { paysId: paysRecord.id },
      select: { id: true, nom: true },
    });
    const doublon = trouverDoublon(toutesRegions, nom);

    if (doublon) {
      const regionExistante = await prisma.region.findUnique({ where: { id: doublon.id } });
      return res.status(200).json({ nouveau: false, region: regionExistante });
    }

    const nouvelle = await prisma.region.create({
      data: { nom: nom.trim(), paysId: paysRecord.id },
    });
    return res.status(201).json({ nouveau: true, region: nouvelle });

  } catch (err) { next(err); }
}

// ── POST /localisation/villes ─────────────────────────────
// Body : { nom, regionNom, paysNom }
// Retourne la ville existante ou la ville nouvellement créée
async function upsertVille(req, res, next) {
  try {
    const { nom, regionNom, paysNom } = req.body;

    if (!nom || !nom.trim())         return res.status(400).json({ message: 'Le nom de la ville est requis.' });
    if (!regionNom || !regionNom.trim()) return res.status(400).json({ message: 'Le nom de la région est requis.' });
    if (!paysNom   || !paysNom.trim())   return res.status(400).json({ message: 'Le nom du pays est requis.' });

    // 1. Résoudre le pays
    const tousPays   = await prisma.pays.findMany({ select: { id: true, nom: true } });
    const paysRecord = trouverDoublon(tousPays, paysNom);
    if (!paysRecord) {
      return res.status(404).json({ message: `Pays "${paysNom}" introuvable.` });
    }

    // 2. Résoudre la région dans ce pays
    const toutesRegions  = await prisma.region.findMany({
      where:  { paysId: paysRecord.id },
      select: { id: true, nom: true },
    });
    const regionRecord = trouverDoublon(toutesRegions, regionNom);
    if (!regionRecord) {
      return res.status(404).json({ message: `Région "${regionNom}" introuvable dans "${paysNom}".` });
    }

    // 3. Chercher un doublon dans les villes de cette région
    const toutesVilles = await prisma.ville.findMany({
      where:  { regionId: regionRecord.id },
      select: { id: true, nom: true },
    });
    const doublon = trouverDoublon(toutesVilles, nom);

    if (doublon) {
      const villeExistante = await prisma.ville.findUnique({ where: { id: doublon.id } });
      return res.status(200).json({ nouveau: false, ville: villeExistante });
    }

    const nouvelle = await prisma.ville.create({
      data: { nom: nom.trim(), regionId: regionRecord.id },
    });
    return res.status(201).json({ nouveau: true, ville: nouvelle });

  } catch (err) { next(err); }
}

// ── POST /localisation/quartiers ──────────────────────────
// Body : { nom, villeNom, regionNom, paysNom }
// Retourne le quartier existant ou le quartier nouvellement créé
async function upsertQuartier(req, res, next) {
  try {
    const { nom, villeNom, regionNom, paysNom } = req.body;

    if (!nom      || !nom.trim())      return res.status(400).json({ message: 'Le nom du quartier est requis.' });
    if (!villeNom || !villeNom.trim()) return res.status(400).json({ message: 'Le nom de la ville est requis.' });
    if (!regionNom || !regionNom.trim()) return res.status(400).json({ message: 'Le nom de la région est requis.' });
    if (!paysNom  || !paysNom.trim())  return res.status(400).json({ message: 'Le nom du pays est requis.' });

    // 1. Résoudre le pays
    const tousPays   = await prisma.pays.findMany({ select: { id: true, nom: true } });
    const paysRecord = trouverDoublon(tousPays, paysNom);
    if (!paysRecord) {
      return res.status(404).json({ message: `Pays "${paysNom}" introuvable.` });
    }

    // 2. Résoudre la région
    const toutesRegions = await prisma.region.findMany({
      where:  { paysId: paysRecord.id },
      select: { id: true, nom: true },
    });
    const regionRecord = trouverDoublon(toutesRegions, regionNom);
    if (!regionRecord) {
      return res.status(404).json({ message: `Région "${regionNom}" introuvable dans "${paysNom}".` });
    }

    // 3. Résoudre la ville
    const toutesVilles = await prisma.ville.findMany({
      where:  { regionId: regionRecord.id },
      select: { id: true, nom: true },
    });
    const villeRecord = trouverDoublon(toutesVilles, villeNom);
    if (!villeRecord) {
      return res.status(404).json({ message: `Ville "${villeNom}" introuvable dans "${regionNom}".` });
    }

    // 4. Chercher un doublon dans les quartiers de cette ville
    const tousQuartiers = await prisma.quartier.findMany({
      where:  { villeId: villeRecord.id },
      select: { id: true, nom: true },
    });
    const doublon = trouverDoublon(tousQuartiers, nom);

    if (doublon) {
      const quartierExistant = await prisma.quartier.findUnique({ where: { id: doublon.id } });
      return res.status(200).json({ nouveau: false, quartier: quartierExistant });
    }

    const nouveau = await prisma.quartier.create({
      data: { nom: nom.trim(), villeId: villeRecord.id },
    });
    return res.status(201).json({ nouveau: true, quartier: nouveau });

  } catch (err) { next(err); }
}

module.exports = {
  // GET
  getPays, getRegions, getVilles, getQuartiers, getCategories, getCategoriesFlat,
  // UPSERT
  upsertPays, upsertRegion, upsertVille, upsertQuartier,
};