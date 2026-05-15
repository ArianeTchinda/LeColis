// lib/core/models/publication_model.dart

import 'package:flutter/material.dart';

enum PlanType { premium, standard, basique }

extension PlanTypeExt on PlanType {
  String get label {
    switch (this) {
      case PlanType.premium:  return 'Premium';
      case PlanType.standard: return 'Standard';
      case PlanType.basique:  return 'Basique';
    }
  }

  Color get color {
    switch (this) {
      case PlanType.premium:  return const Color(0xFFFFD700);
      case PlanType.standard: return const Color(0xFFFF5DA8);
      case PlanType.basique:  return const Color(0xFF8A8A9A);
    }
  }

  Color get bgColor {
    switch (this) {
      case PlanType.premium:  return const Color(0x22FFD700);
      case PlanType.standard: return const Color(0x22FF5DA8);
      case PlanType.basique:  return const Color(0x228A8A9A);
    }
  }
}

class PublicationModel {
  final int    id;
  final String escortPseudo;
  final String escortImageProfil;
  final List<String> imageUrls;
  final String titre;
  final String description;
  final String categorie;

  // ── Localisation hiérarchique ──
  final String pays;
  final String region;
  final String ville;
  final String quartier;

  // ── Contacts ──
  final String  telephone;
  final String  whatsapp;
  final String? email;        // ← NOUVEAU (optionnel)

  final PlanType planType;
  final bool     estVerifie;

  /// [estDisponible] indique si l'escort se déclare disponible pour des RDV.
  /// Ce champ est INDÉPENDANT de la visibilité de la publication.
  /// La visibilité est dictée uniquement par [dateExpiration] (abonnement actif).
  final bool estDisponible;

  final double?  tarif;
  final DateTime dateExpiration; // Fin de l'abonnement lié à cette publication
  final int      vues;

  const PublicationModel({
    required this.id,
    required this.escortPseudo,
    required this.escortImageProfil,
    required this.imageUrls,
    required this.titre,
    required this.description,
    required this.categorie,
    this.pays    = 'Cameroun',
    this.region  = '',
    required this.ville,
    required this.quartier,
    required this.telephone,
    required this.whatsapp,
    this.email,                  // ← NOUVEAU
    required this.planType,
    required this.estVerifie,
    required this.estDisponible,
    required this.tarif,
    required this.dateExpiration,
    required this.vues,
  });

  /// Image principale (vignette carte)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Une publication est visible dans la liste uniquement si
  /// l'abonnement associé est encore actif (dateExpiration non dépassée).
  bool get estActive => dateExpiration.isAfter(DateTime.now());

  /// Localisation affichable compacte
  String get localisationLabel {
    final parts = <String>[];
    if (quartier.isNotEmpty) parts.add(quartier);
    if (ville.isNotEmpty)    parts.add(ville);
    return parts.join(', ');
  }

  int get poidsAffichage {
    switch (planType) {
      case PlanType.premium:  return 3;
      case PlanType.standard: return 2;
      case PlanType.basique:  return 1;
    }
  }
}

// ─────────────────────────────────────────────────────────
// DONNÉES MOCK
// ─────────────────────────────────────────────────────────
final List<PublicationModel> mockPublications = [
  PublicationModel(
    id: 1,
    escortPseudo: 'Sofia K.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/11.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/101/15166976/15166976_001_4c81.jpg',
      'https://cdni.pornpics.com/1280/7/101/15166976/15166976_039_4306.jpg',
      'https://cdni.pornpics.com/1280/7/101/15166976/15166976_046_3d4b.jpg',
    ],
    titre: 'Moment de détente et douceur',
    description: 'Je propose des moments de qualité dans un cadre discret et chaleureux. Disponible en soirée. Appel uniquement.',
    categorie: 'Milf',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Bonanjo',
    telephone: '+237600000001',
    whatsapp:  '+237600000001',
    email:     'sofia.k@proton.me',
    planType: PlanType.premium,
    estVerifie: true, estDisponible: true,
    tarif: 50000,
    dateExpiration: DateTime.now().add(const Duration(days: 20)),
    vues: 340,
  ),
  PublicationModel(
    id: 2,
    escortPseudo: 'Naomi B.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/22.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/484/53822931/53822931_049_4205.jpg',
      'https://cdni.pornpics.com/1280/7/484/53822931/53822931_100_6dde.jpg',
    ],
    titre: 'Élégance et complicité',
    description: 'Belle et raffinée, je vous propose une expérience inoubliable.',
    categorie: 'Ebony',
    pays: 'Cameroun', region: 'Littoral',
    ville: 'Douala', quartier: 'Bonanjo',
    telephone: '+237600000002',
    whatsapp:  '+237600000002',
    email:     'naomi.b@proton.me',
    planType: PlanType.premium,
    estVerifie: true, estDisponible: true,
    tarif: 45000,
    dateExpiration: DateTime.now().add(const Duration(days: 15)),
    vues: 280,
  ),
  PublicationModel(
    id: 3,
    escortPseudo: 'Bella R.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/33.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/840/90695987/90695987_009_2bf0.jpg',
      'https://cdni.pornpics.com/1280/7/840/90695987/90695987_097_290a.jpg',
      'https://cdni.pornpics.com/1280/7/840/90695987/90695987_102_faf7.jpg',
      'https://cdni.pornpics.com/1280/7/840/90695987/90695987_040_f80f.jpg',
    ],
    titre: 'Disponible ce soir',
    description: 'Jeune femme dynamique, douce et attentionnée.',
    categorie: 'Latina',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Nlongkak',
    telephone: '+237600000003',
    whatsapp:  '+237600000003',
    // pas d'email → null
    planType: PlanType.standard,
    estVerifie: true, estDisponible: true,
    tarif: 30000,
    dateExpiration: DateTime.now().add(const Duration(days: 5)),
    vues: 120,
  ),
  PublicationModel(
    id: 4,
    escortPseudo: 'Candy M.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/44.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/79/91215820/91215820_022_c227.jpg',
      'https://cdni.pornpics.com/1280/7/79/91215820/91215820_084_3aaa.jpg',
    ],
    titre: 'Douceur garantie',
    description: 'Ronde et généreuse, pour ceux qui aiment les vraies courbes.',
    categorie: 'BBW',
    pays: 'Cameroun', region: 'Littoral',
    ville: 'Douala', quartier: 'Akwa',
    telephone: '+237600000004',
    whatsapp:  '+237600000004',
    email:     'candy.m@proton.me',
    planType: PlanType.standard,
    estVerifie: false, estDisponible: true,
    tarif: 25000,
    dateExpiration: DateTime.now().add(const Duration(days: 3)),
    vues: 95,
  ),
  PublicationModel(
    id: 5,
    escortPseudo: 'Jade L.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/55.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/113/28112813/28112813_045_e296.jpg',
    ],
    titre: 'Rencontre discrète',
    description: 'Disponible en semaine, sérieuse et ponctuelle.',
    categorie: 'Asian',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Mvan',
    telephone: '+237600000005',
    whatsapp:  '+237600000005',
    // Abonnement expiré → cette publication n'apparaîtra PAS dans la liste
    planType: PlanType.basique,
    estVerifie: false, estDisponible: false,
    tarif: 20000,
    dateExpiration: DateTime.now().subtract(const Duration(days: 1)), // ← expiré
    vues: 45,
  ),
  PublicationModel(
    id: 6,
    escortPseudo: 'Nina V.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/66.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/1/364/54937640/54937640_002_8c39.jpg',
      'https://cdni.pornpics.com/1280/1/364/54937640/54937640_004_7f5d.jpg',
      'https://cdni.pornpics.com/1280/1/364/54937640/54937640_003_a744.jpg',
    ],
    titre: 'Massage et relaxation',
    description: 'Experte en massage relaxant, corps et esprit.',
    categorie: 'Milf',
    pays: 'Cameroun', region: 'Ouest',
    ville: 'Bafoussam', quartier: 'Centre',
    telephone: '+237600000006',
    whatsapp:  '+237600000006',
    email:     'nina.v@proton.me',
    planType: PlanType.premium,
    estVerifie: true, estDisponible: true,
    tarif: 55000,
    dateExpiration: DateTime.now().add(const Duration(days: 25)),
    vues: 410,
  ),
  PublicationModel(
    id: 7,
    escortPseudo: 'Eva C.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/77.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/763/13331005/13331005_011_b8af.jpg',
      'https://cdni.pornpics.com/1280/7/763/13331005/13331005_017_798b.jpg',
    ],
    titre: 'Compagnie de qualité',
    description: 'Pour sorties, dîners ou moments intimes. Bilingue.',
    categorie: 'Ebony',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Omnisports',
    telephone: '+237600000007',
    whatsapp:  '+237600000007',
    // pas d'email
    planType: PlanType.standard,
    estVerifie: true, estDisponible: true,
    tarif: 35000,
    dateExpiration: DateTime.now().add(const Duration(days: 8)),
    vues: 180,
  ),
  PublicationModel(
    id: 8,
    escortPseudo: 'Tina P.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/88.jpg',
    imageUrls: [
      'https://cdni.pornpics.com/1280/7/557/16454844/16454844_003_f858.jpg',
      'https://cdni.pornpics.com/1280/7/557/16454844/16454844_037_898f.jpg',
      'https://cdni.pornpics.com/1280/7/557/16454844/16454844_060_df62.jpg',
    ],
    titre: 'Fraîcheur et spontanéité',
    description: 'Jeune et pétillante, pour des moments légers.',
    categorie: 'BBW',
    pays: 'Cameroun', region: 'Littoral',
    ville: 'Douala', quartier: 'Deido',
    telephone: '+237600000008',
    whatsapp:  '+237600000008',
    email:     'tina.p@proton.me',
    planType: PlanType.basique,
    estVerifie: false, estDisponible: true,
    tarif: 15000,
    dateExpiration: DateTime.now().add(const Duration(days: 2)),
    vues: 60,
  ),
];

// ─────────────────────────────────────────────────────────
// LISTES FILTRE
// ─────────────────────────────────────────────────────────
const List<String> categories = [
  'Toutes', 'Milf', 'BBW', 'Ebony', 'Latina', 'Asian', 'Trans', 'Couple',
];

const List<String> villes = [
  'Toutes', 'Yaoundé', 'Douala', 'Bafoussam', 'Garoua', 'Maroua',
];

// ─────────────────────────────────────────────────────────
// AVIS ANONYME
// ─────────────────────────────────────────────────────────
class AvisModel {
  final int      id;
  final int      publicationId;
  final int      note;
  final String   message;
  final DateTime createdAt;

  const AvisModel({
    required this.id,
    required this.publicationId,
    required this.note,
    required this.message,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────────────────────
// MOTIF SIGNALEMENT
// ─────────────────────────────────────────────────────────
enum SignalementMotif {
  fauxCompte,
  spam,
  contenuInapproprie,
  autre;

  String get label {
    switch (this) {
      case SignalementMotif.fauxCompte:         return 'Faux compte';
      case SignalementMotif.spam:               return 'Spam';
      case SignalementMotif.contenuInapproprie: return 'Contenu inapproprié';
      case SignalementMotif.autre:              return 'Autre';
    }
  }
}

// ─────────────────────────────────────────────────────────
// AVIS MOCK
// ─────────────────────────────────────────────────────────
final List<AvisModel> mockAvis = [
  AvisModel(id: 1, publicationId: 1, note: 5, message: 'Très discrète et ponctuelle. Je recommande vivement.', createdAt: DateTime.now().subtract(const Duration(days: 3))),
  AvisModel(id: 2, publicationId: 1, note: 4, message: 'Super expérience, cadre agréable.', createdAt: DateTime.now().subtract(const Duration(days: 7))),
  AvisModel(id: 3, publicationId: 1, note: 3, message: 'Correct mais légèrement en retard.', createdAt: DateTime.now().subtract(const Duration(days: 14))),
  AvisModel(id: 4, publicationId: 2, note: 5, message: 'Magnifique, très professionnelle.', createdAt: DateTime.now().subtract(const Duration(days: 2))),
  AvisModel(id: 5, publicationId: 2, note: 4, message: 'Bonne prestation, je reviendrai.', createdAt: DateTime.now().subtract(const Duration(days: 10))),
  AvisModel(id: 6, publicationId: 3, note: 5, message: 'Parfait, rien à redire.', createdAt: DateTime.now().subtract(const Duration(days: 1))),
  AvisModel(id: 7, publicationId: 6, note: 4, message: 'Massage très relaxant, cadre propre.', createdAt: DateTime.now().subtract(const Duration(days: 5))),
  AvisModel(id: 8, publicationId: 6, note: 5, message: 'Excellent rapport qualité prix.', createdAt: DateTime.now().subtract(const Duration(days: 8))),
];