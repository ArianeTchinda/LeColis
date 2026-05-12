// lib/core/data/categories_data.dart
//
// Toutes les catégories de l'industrie adulte
// Organisées par groupes pour le filtre

class CategorieGroupe {
  final String nom;
  final List<String> categories;
  const CategorieGroupe({required this.nom, required this.categories});
}

// ─────────────────────────────────────────────────────────
// LISTE PLATE — pour le filtre et la recherche
// ─────────────────────────────────────────────────────────
const List<String> toutesLesCategories = [
  'Toutes',
  // Physique / morphologie
  'BBW', 'Slim', 'Curvy', 'Petite', 'Tall', 'Busty', 'Fit', 'Muscle',
  // Origine / ethnie
  'Ebony', 'Latina', 'Asian', 'Arab', 'Indian', 'Mixed', 'White', 'Métisse',
  // Âge / expérience
  'Milf', 'Cougar', 'Teen (18+)', 'Mature', 'Older',
  // Genre / identité
  'Trans (MtF)', 'Trans (FtM)', 'Non-binaire', 'Femme', 'Homme', 'Couple',
  // Couple / groupe
  'Couple hétéro', 'Couple lesbien', 'Couple gay', 'Trio FFH', 'Trio HHF',
  'Gang Bang', 'Orgie',
  // Orientation
  'Hétéro', 'Gay', 'Lesbienne', 'Bisexuel(le)', 'Pansexuel(le)',
  // Services spéciaux
  'Escort Premium', 'GFE (Girlfriend Experience)', 'BFE (Boyfriend Experience)',
  'Dominatrice', 'Soumise', 'BDSM', 'Fetish', 'Maîtresse',
  'Strip-tease', 'Lap Dance', 'Show Webcam', 'Sexting',
  // Massage
  'Massage érotique', 'Massage tantrique', 'Massage nuru', 'Massage body-body',
  // Spécialisés
  'Anal', 'Deep Throat', 'Squirt', 'Double pénétration', 'Fisting',
  'Role play', 'Cross-dressing', 'Voyeurisme', 'Exhibitionnisme',
  'Foot Fetish', 'Domination', 'Soumission', 'Spanking', 'Humiliation',
  // Lifestyle
  'Naturiste', 'Swingers', 'Libertin(e)', 'Sugar Baby', 'Sugar Daddy',
  'Femme mariée', 'Homme marié',
  // Prestation
  'Outcall', 'Incall', 'Déplacement', 'Soirée privée', 'Week-end',
  'Voyage accompagné', 'Dîner compris',
];

// ─────────────────────────────────────────────────────────
// PAR GROUPES — pour l'affichage dans le filtre avancé
// ─────────────────────────────────────────────────────────
const List<CategorieGroupe> categoriesParGroupe = [
  CategorieGroupe(nom: 'Morphologie', categories: [
    'BBW', 'Slim', 'Curvy', 'Petite', 'Tall', 'Busty', 'Fit', 'Muscle',
  ]),
  CategorieGroupe(nom: 'Origine', categories: [
    'Ebony', 'Latina', 'Asian', 'Arab', 'Indian', 'Mixed', 'White', 'Métisse',
  ]),
  CategorieGroupe(nom: 'Âge', categories: [
    'Teen (18+)', 'Milf', 'Cougar', 'Mature', 'Older',
  ]),
  CategorieGroupe(nom: 'Genre', categories: [
    'Femme', 'Homme', 'Trans (MtF)', 'Trans (FtM)', 'Non-binaire',
  ]),
  CategorieGroupe(nom: 'Couple / Groupe', categories: [
    'Couple hétéro', 'Couple lesbien', 'Couple gay',
    'Trio FFH', 'Trio HHF', 'Gang Bang', 'Orgie',
  ]),
  CategorieGroupe(nom: 'Orientation', categories: [
    'Hétéro', 'Gay', 'Lesbienne', 'Bisexuel(le)', 'Pansexuel(le)',
  ]),
  CategorieGroupe(nom: 'Services', categories: [
    'Escort Premium', 'GFE (Girlfriend Experience)', 'BFE (Boyfriend Experience)',
    'Dominatrice', 'Soumise', 'BDSM', 'Fetish', 'Maîtresse',
    'Strip-tease', 'Lap Dance', 'Show Webcam', 'Sexting',
  ]),
  CategorieGroupe(nom: 'Massage', categories: [
    'Massage érotique', 'Massage tantrique', 'Massage nuru', 'Massage body-body',
  ]),
  CategorieGroupe(nom: 'Spécialités', categories: [
    'Anal', 'Deep Throat', 'Squirt', 'Double pénétration', 'Fisting',
    'Role play', 'Foot Fetish', 'Domination', 'Soumission',
    'Spanking', 'Humiliation', 'Voyeurisme', 'Exhibitionnisme', 'Cross-dressing',
  ]),
  CategorieGroupe(nom: 'Lifestyle', categories: [
    'Naturiste', 'Swingers', 'Libertin(e)', 'Sugar Baby', 'Sugar Daddy',
    'Femme mariée', 'Homme marié',
  ]),
  CategorieGroupe(nom: 'Prestation', categories: [
    'Outcall', 'Incall', 'Déplacement', 'Soirée privée',
    'Week-end', 'Voyage accompagné', 'Dîner compris',
  ]),
];