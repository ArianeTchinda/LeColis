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
  final String id;           // ← String (cuid Prisma, pas int)
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
  final String? email;

  final PlanType planType;
  final bool     estVerifie;

  /// [estDisponible] indique si l'escort se déclare disponible pour des RDV.
  /// Ce champ est INDÉPENDANT de la visibilité de la publication.
  /// La visibilité est dictée uniquement par [dateExpiration].
  final bool estDisponible;

  final double?  tarif;
  final DateTime dateExpiration;
  final int      vues;

  // ── Avis ──
  final List<AvisModel> avis;

  const PublicationModel({
    required this.id,
    required this.escortPseudo,
    required this.escortImageProfil,
    required this.imageUrls,
    required this.titre,
    required this.description,
    required this.categorie,
    this.pays     = 'Cameroun',
    this.region   = '',
    required this.ville,
    required this.quartier,
    required this.telephone,
    required this.whatsapp,
    this.email,
    required this.planType,
    required this.estVerifie,
    required this.estDisponible,
    required this.tarif,
    required this.dateExpiration,
    required this.vues,
    this.avis = const [],
  });

  /// Image principale (vignette carte)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Visible uniquement si l'abonnement est encore actif
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

  /// Construit depuis la réponse JSON du backend (GET /publications ou GET /publications/:id)
  /// Structure backend : { id, titre, description, estDisponible, tarif, statut,
  ///   vues, dateExpiration, planType, villeNom, regionNom, paysNom,
  ///   quartier:{nom}, images:[{url}], categories:[{nom}],
  ///   escort:{pseudo, photoUrl, telephone, email, estVerifie},
  ///   avis:[{id, note, message, createdAt}] }
  factory PublicationModel.fromJson(Map<String, dynamic> j) {
    // Images
    final images   = (j['images'] as List?) ?? [];
    final imageUrls = images.map<String>((img) => img['url'] as String).toList();

    // Catégorie principale (première de la liste)
    final cats       = (j['categories'] as List?) ?? [];
    final categorie  = cats.isNotEmpty ? (cats.first['nom'] ?? '') : '';

    // Escort
    final escort = j['escort'] as Map<String, dynamic>? ?? {};

    // Avis
    final avisRaw = (j['avis'] as List?) ?? [];
    final avis    = avisRaw.map((a) => AvisModel.fromJson(a, j['id'])).toList();

    // PlanType
    PlanType parsePlanType(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'premium':  return PlanType.premium;
        case 'standard': return PlanType.standard;
        default:         return PlanType.basique;
      }
    }

    return PublicationModel(
      id:                 j['id'],
      escortPseudo:       escort['pseudo']   ?? '',
      escortImageProfil:  escort['photoUrl'] ?? '',
      imageUrls:          imageUrls,
      titre:              j['titre']         ?? '',
      description:        j['description']   ?? '',
      categorie:          categorie,
      pays:               j['paysNom']       ?? 'Cameroun',
      region:             j['regionNom']     ?? '',
      ville:              j['villeNom']      ?? '',
      quartier:           j['quartier']?['nom'] ?? '',
      telephone:          escort['telephone'] ?? '',
      whatsapp:           escort['whatsapp']  ?? escort['telephone'] ?? '',
      email:              escort['email'],
      planType:           parsePlanType(j['planType']),
      estVerifie:         escort['estVerifie'] ?? false,
      estDisponible:      j['estDisponible']   ?? false,
      tarif:              (j['tarif'] as num?)?.toDouble(),
      dateExpiration:     DateTime.parse(j['dateExpiration']),
      vues:               j['vues'] ?? 0,
      avis:               avis,
    );
  }
}

// ─────────────────────────────────────────────────────────
// AVIS ANONYME
// ─────────────────────────────────────────────────────────
class AvisModel {
  final String   id;
  final String   publicationId;
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

  factory AvisModel.fromJson(Map<String, dynamic> j, String pubId) =>
      AvisModel(
        id:            j['id']?.toString() ?? '',
        publicationId: pubId,
        note:          j['note'] ?? 0,
        message:       j['message'] ?? '',
        createdAt:     DateTime.parse(j['createdAt']),
      );
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
// DONNÉES MOCK (conservées pour les tests hors-réseau)
// ─────────────────────────────────────────────────────────
final List<PublicationModel> mockPublications = [
  PublicationModel(
    id: 'mock_1',
    escortPseudo: 'Sofia K.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/11.jpg',
    imageUrls: [
      'https://picsum.photos/seed/s1a/800/600',
      'https://picsum.photos/seed/s1b/800/600',
    ],
    titre: 'Moment de détente et douceur',
    description: 'Je propose des moments de qualité dans un cadre discret et chaleureux.',
    categorie: 'Milf',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Bastos',
    telephone: '+237600000001', whatsapp: '+237600000001',
    email: 'sofia.k@proton.me',
    planType: PlanType.premium,
    estVerifie: true, estDisponible: true,
    tarif: 50000,
    dateExpiration: DateTime.now().add(const Duration(days: 20)),
    vues: 340,
  ),
  PublicationModel(
    id: 'mock_2',
    escortPseudo: 'Naomi B.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/22.jpg',
    imageUrls: [
      'https://picsum.photos/seed/s2a/800/600',
      'https://picsum.photos/seed/s2b/800/600',
    ],
    titre: 'Élégance et complicité',
    description: 'Belle et raffinée, je vous propose une expérience inoubliable.',
    categorie: 'Ebony',
    pays: 'Cameroun', region: 'Littoral',
    ville: 'Douala', quartier: 'Bonanjo',
    telephone: '+237600000002', whatsapp: '+237600000002',
    email: 'naomi.b@proton.me',
    planType: PlanType.premium,
    estVerifie: true, estDisponible: true,
    tarif: 45000,
    dateExpiration: DateTime.now().add(const Duration(days: 15)),
    vues: 280,
  ),
  PublicationModel(
    id: 'mock_3',
    escortPseudo: 'Bella R.',
    escortImageProfil: 'https://randomuser.me/api/portraits/women/33.jpg',
    imageUrls: ['https://picsum.photos/seed/s3a/800/600'],
    titre: 'Disponible ce soir',
    description: 'Jeune femme dynamique, douce et attentionnée.',
    categorie: 'Latina',
    pays: 'Cameroun', region: 'Centre',
    ville: 'Yaoundé', quartier: 'Nlongkak',
    telephone: '+237600000003', whatsapp: '+237600000003',
    planType: PlanType.standard,
    estVerifie: true, estDisponible: true,
    tarif: 30000,
    dateExpiration: DateTime.now().add(const Duration(days: 5)),
    vues: 120,
  ),
];

// ─────────────────────────────────────────────────────────
// LISTES FILTRE (statiques — remplacées dynamiquement par le référentiel)
// ─────────────────────────────────────────────────────────
const List<String> categoriesStatiques = [
  'Toutes', 'Milf', 'BBW', 'Ebony', 'Latina', 'Asian', 'Trans', 'Couple',
];

const List<String> villesStatiques = [
  'Toutes', 'Yaoundé', 'Douala', 'Bafoussam', 'Garoua', 'Maroua',
];

// ─────────────────────────────────────────────────────────
// AVIS MOCK
// ─────────────────────────────────────────────────────────
final List<AvisModel> mockAvis = [
  AvisModel(id: '1', publicationId: 'mock_1', note: 5,
      message: 'Très discrète et ponctuelle.',
      createdAt: DateTime.now().subtract(const Duration(days: 3))),
  AvisModel(id: '2', publicationId: 'mock_1', note: 4,
      message: 'Super expérience, cadre agréable.',
      createdAt: DateTime.now().subtract(const Duration(days: 7))),
];