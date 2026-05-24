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

module.exports = { getPays, getRegions, getVilles, getQuartiers, getCategories, getCategoriesFlat };
