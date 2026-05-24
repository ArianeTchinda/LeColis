// prisma/seed.js
// Lance avec : node prisma/seed.js
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// ── CATÉGORIES (depuis categories_data.dart) ──────────────
const GROUPES_CATEGORIES = [
  { nom: 'Morphologie', ordre: 1, categories: [
    'BBW', 'Slim', 'Curvy', 'Petite', 'Tall', 'Busty', 'Fit', 'Muscle',
  ]},
  { nom: 'Origine', ordre: 2, categories: [
    'Ebony', 'Latina', 'Asian', 'Arab', 'Indian', 'Mixed', 'White', 'Métisse',
  ]},
  { nom: 'Âge', ordre: 3, categories: [
    'Teen (18+)', 'Milf', 'Cougar', 'Mature', 'Older',
  ]},
  { nom: 'Genre', ordre: 4, categories: [
    'Femme', 'Homme', 'Trans (MtF)', 'Trans (FtM)', 'Non-binaire',
  ]},
  { nom: 'Couple / Groupe', ordre: 5, categories: [
    'Couple hétéro', 'Couple lesbien', 'Couple gay',
    'Trio FFH', 'Trio HHF', 'Gang Bang', 'Orgie',
  ]},
  { nom: 'Orientation', ordre: 6, categories: [
    'Hétéro', 'Gay', 'Lesbienne', 'Bisexuel(le)', 'Pansexuel(le)',
  ]},
  { nom: 'Services', ordre: 7, categories: [
    'Escort Premium', 'GFE (Girlfriend Experience)', 'BFE (Boyfriend Experience)',
    'Dominatrice', 'Soumise', 'BDSM', 'Fetish', 'Maîtresse',
    'Strip-tease', 'Lap Dance', 'Show Webcam', 'Sexting',
  ]},
  { nom: 'Massage', ordre: 8, categories: [
    'Massage érotique', 'Massage tantrique', 'Massage nuru', 'Massage body-body',
  ]},
  { nom: 'Spécialités', ordre: 9, categories: [
    'Anal', 'Deep Throat', 'Squirt', 'Double pénétration', 'Fisting',
    'Role play', 'Foot Fetish', 'Domination', 'Soumission',
    'Spanking', 'Humiliation', 'Voyeurisme', 'Exhibitionnisme', 'Cross-dressing',
  ]},
  { nom: 'Lifestyle', ordre: 10, categories: [
    'Naturiste', 'Swingers', 'Libertin(e)', 'Sugar Baby', 'Sugar Daddy',
    'Femme mariée', 'Homme marié',
  ]},
  { nom: 'Prestation', ordre: 11, categories: [
    'Outcall', 'Incall', 'Déplacement', 'Soirée privée',
    'Week-end', 'Voyage accompagné', 'Dîner compris',
  ]},
];

// ── LOCALISATION (extrait de location_data.dart) ──────────
const LOCATION_DATA = [
  {
    id: 'cm', nom: 'Cameroun', drapeau: '🇨🇲',
    regions: [
      { id: 'cm_centre', nom: 'Centre', villes: [
        { id: 'cm_yaounde', nom: 'Yaoundé', quartiers: [
          'Bastos', 'Nlongkak', 'Omnisport', 'Mvan', 'Biyem-Assi', 'Nsimeyong',
          'Mvog-Mbi', 'Tsinga', 'Mfandena', 'Ekounou', 'Djoungolo', 'Emana',
          'Mendong', 'Nkomo', 'Essos', 'Obili', 'Elig-Edzoa', 'Carrière',
          'Simbok', 'Simbock', 'Messa', 'Etoug-Ebe', 'Mballa II',
        ]},
        { id: 'cm_mbalmayo', nom: 'Mbalmayo', quartiers: ['Centre', 'Angalé', 'Nkolmesseng'] },
        { id: 'cm_sa_centre', nom: "Sa'a", quartiers: ['Centre'] },
      ]},
      { id: 'cm_littoral', nom: 'Littoral', villes: [
        { id: 'cm_douala', nom: 'Douala', quartiers: [
          'Bonanjo', 'Akwa', 'Deido', 'Bali', 'Makepe', 'Bonapriso',
          'Bonamoussadi', 'Logbessou', 'Ndokotti', 'Ndog-Bong', 'Bonabéri',
          'Kotto', 'Sodiko', 'Nyalla', 'Pk8', 'Pk10', 'Pk14',
        ]},
        { id: 'cm_nkongsamba', nom: 'Nkongsamba', quartiers: ['Centre', 'Bare', 'Nguélémendouka'] },
      ]},
      { id: 'cm_ouest', nom: 'Ouest', villes: [
        { id: 'cm_bafoussam', nom: 'Bafoussam', quartiers: [
          'Centre', 'Tamdja', 'Djeleng', 'Kamkop', 'Banengo',
        ]},
        { id: 'cm_bangangte', nom: 'Bangangté', quartiers: ['Centre'] },
        { id: 'cm_mbouda', nom: 'Mbouda', quartiers: ['Centre'] },
      ]},
      { id: 'cm_nord', nom: 'Nord', villes: [
        { id: 'cm_garoua', nom: 'Garoua', quartiers: [
          'Centre', 'Poumpoumré', 'Roumdé Adjia', 'Bocklé',
        ]},
        { id: 'cm_guider', nom: 'Guider', quartiers: ['Centre'] },
      ]},
      { id: 'cm_extreme_nord', nom: 'Extrême-Nord', villes: [
        { id: 'cm_maroua', nom: 'Maroua', quartiers: [
          'Centre', 'Djarengol', 'Domayo', 'Kakataré',
        ]},
        { id: 'cm_kousseri', nom: 'Kousseri', quartiers: ['Centre'] },
      ]},
      { id: 'cm_adamaoua', nom: 'Adamaoua', villes: [
        { id: 'cm_ngaoundere', nom: 'Ngaoundéré', quartiers: [
          'Centre', 'Burkina', 'Joli Soir', 'Mardock',
        ]},
      ]},
      { id: 'cm_est', nom: 'Est', villes: [
        { id: 'cm_bertoua', nom: 'Bertoua', quartiers: ['Centre', 'Mokolo', 'Nkolbikon'] },
      ]},
      { id: 'cm_sud', nom: 'Sud', villes: [
        { id: 'cm_ebolowa', nom: 'Ebolowa', quartiers: ['Centre', 'Angalé'] },
        { id: 'cm_kribi', nom: 'Kribi', quartiers: ['Centre', 'Plage'] },
      ]},
      { id: 'cm_sw', nom: 'Sud-Ouest', villes: [
        { id: 'cm_buea', nom: 'Buea', quartiers: ['Molyko', 'Mile 16', 'Great Soppo'] },
        { id: 'cm_limbe', nom: 'Limbé', quartiers: ['Town', 'New Town', 'Bota'] },
      ]},
      { id: 'cm_nw', nom: 'Nord-Ouest', villes: [
        { id: 'cm_bamenda', nom: 'Bamenda', quartiers: ['Commercial Avenue', 'Nkwen', 'Mile 4'] },
      ]},
    ],
  },
  {
    id: 'fr', nom: 'France', drapeau: '🇫🇷',
    regions: [
      { id: 'fr_idf', nom: 'Île-de-France', villes: [
        { id: 'fr_paris', nom: 'Paris', quartiers: [] },
        { id: 'fr_versailles', nom: 'Versailles', quartiers: [] },
      ]},
      { id: 'fr_paca', nom: "Provence-Alpes-Côte d'Azur", villes: [
        { id: 'fr_marseille', nom: 'Marseille', quartiers: [] },
        { id: 'fr_nice', nom: 'Nice', quartiers: [] },
      ]},
    ],
  },
  {
    id: 'ci', nom: "Côte d'Ivoire", drapeau: '🇨🇮',
    regions: [
      { id: 'ci_lagunes', nom: 'District Autonome d\'Abidjan', villes: [
        { id: 'ci_abidjan', nom: 'Abidjan', quartiers: ['Plateau', 'Cocody', 'Yopougon', 'Adjamé'] },
      ]},
    ],
  },
  {
    id: 'ga', nom: 'Gabon', drapeau: '🇬🇦',
    regions: [
      { id: 'ga_estuaire', nom: 'Estuaire', villes: [
        { id: 'ga_libreville', nom: 'Libreville', quartiers: ['Centre', 'Nkembo', 'Akanda'] },
      ]},
    ],
  },
  {
    id: 'sn', nom: 'Sénégal', drapeau: '🇸🇳',
    regions: [
      { id: 'sn_dakar', nom: 'Dakar', villes: [
        { id: 'sn_dakar_ville', nom: 'Dakar', quartiers: ['Plateau', 'Médina', 'Ouakam', 'Almadies'] },
      ]},
    ],
  },
];

// ── PLANS ─────────────────────────────────────────────────
const PLANS = [
  {
    nom: 'Basique', description: "Plan offert à l'inscription.",
    prix: 0, nbPublications: 1, dureeJours: 7,
    accentColor: '#8A8A9A', icone: 'star_outline',
    avantages: ['1 publication active', 'Visible 7 jours', 'Gratuit'],
    estBasique: true, estBase: true, ordre: 1,
  },
  {
    nom: 'Standard', description: 'Plus de visibilité.',
    prix: 5000, nbPublications: 3, dureeJours: 30,
    accentColor: '#FF5DA8', icone: 'verified_outlined',
    avantages: ['3 publications actives', 'Visible 30 jours', 'Badge Standard', 'Support prioritaire'],
    estBasique: false, estBase: true, ordre: 2,
  },
  {
    nom: 'Premium', description: 'Mise en avant maximale.',
    prix: 15000, nbPublications: 10, dureeJours: 30,
    accentColor: '#FFB800', icone: 'workspace_premium',
    avantages: ['10 publications actives', 'Priorité maximale', 'Badge Premium doré', 'Statistiques avancées'],
    estBasique: false, estBase: true, ordre: 3,
  },
];

// ── SEED ──────────────────────────────────────────────────
async function main() {
  console.log('🌱 Démarrage du seed...\n');

  // 1. Plans d'abonnement
  console.log('📦 Plans d\'abonnement...');
  for (const plan of PLANS) {
    await prisma.planAbonnement.upsert({
      where:  { nom: plan.nom },
      update: plan,
      create: plan,
    });
  }
  console.log(`   ✓ ${PLANS.length} plans créés/mis à jour`);

  // 2. Catégories
  console.log('\n🏷️  Catégories...');
  let totalCats = 0;
  for (const groupe of GROUPES_CATEGORIES) {
    const g = await prisma.groupeCategorie.upsert({
      where:  { nom: groupe.nom },
      update: { ordre: groupe.ordre },
      create: { nom: groupe.nom, ordre: groupe.ordre },
    });

    for (const nomCat of groupe.categories) {
      await prisma.categorie.upsert({
        where:  { nom: nomCat },
        update: { groupeId: g.id },
        create: { nom: nomCat, groupeId: g.id },
      });
      totalCats++;
    }
  }
  console.log(`   ✓ ${GROUPES_CATEGORIES.length} groupes, ${totalCats} catégories`);

  // 3. Localisation
  console.log('\n🌍 Localisation...');
  let totalVilles = 0, totalQuartiers = 0;
  for (const paysData of LOCATION_DATA) {
    const pays = await prisma.pays.upsert({
      where:  { nom: paysData.nom },
      update: { drapeau: paysData.drapeau },
      create: { nom: paysData.nom, drapeau: paysData.drapeau },
    });

    for (const regionData of paysData.regions) {
      const region = await prisma.region.upsert({
        where:  { nom_paysId: { nom: regionData.nom, paysId: pays.id } },
        update: {},
        create: { nom: regionData.nom, paysId: pays.id },
      });

      for (const villeData of regionData.villes) {
        const ville = await prisma.ville.upsert({
          where:  { nom_regionId: { nom: villeData.nom, regionId: region.id } },
          update: {},
          create: { nom: villeData.nom, regionId: region.id },
        });
        totalVilles++;

        for (const quartierNom of villeData.quartiers) {
          await prisma.quartier.upsert({
            where:  { nom_villeId: { nom: quartierNom, villeId: ville.id } },
            update: {},
            create: { nom: quartierNom, villeId: ville.id },
          });
          totalQuartiers++;
        }
      }
    }
  }
  console.log(`   ✓ ${LOCATION_DATA.length} pays, ${totalVilles} villes, ${totalQuartiers} quartiers`);

  // 4. Admin par défaut
  console.log('\n👤 Admin...');
  const adminEmail = process.env.ADMIN_EMAIL || 'admin@lecolis.com';
  const adminPass  = process.env.ADMIN_PASSWORD || 'Admin@2025!';
  const hash       = await bcrypt.hash(adminPass, 12);

  await prisma.admin.upsert({
    where:  { email: adminEmail },
    update: {},
    create: { email: adminEmail, motDePasseHash: hash, nom: 'Super Admin' },
  });
  console.log(`   ✓ Admin créé : ${adminEmail}`);

  console.log('\n✅ Seed terminé avec succès !\n');
}

main()
  .catch((e) => { console.error('❌ Erreur seed :', e); process.exit(1); })
  .finally(() => prisma.$disconnect());
